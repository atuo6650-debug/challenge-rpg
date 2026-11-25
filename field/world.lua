-- field/world.lua
-- ワールドマップの基本データ、座標、地形を管理する。

local M = {}

local terrainData = require("data.terrain")
local dungeonData = require("data.dungeon")
local fieldTerrain = require("field.terrain")

-- マップの大きさ
M.TILE_SIZE = 18
M.MAP_WIDTH = 84
M.MAP_HEIGHT = 56

-- 拠点の座標
M.bases = {
    {id = "base_1", name = "拠点1", x = 15, y = 8},
    {id = "base_2", name = "拠点2", x = 70, y = 8},
    {id = "base_3", name = "拠点3", x = 15, y = 49},
    {id = "base_4", name = "拠点4", x = 70, y = 49}
}

-- 街道の座標
M.roads = {
    {
        id = "north",
        name = "北側街道",
        points = {{x = 15, y = 8}, {x = 70, y = 8}}
    },
    {
        id = "east",
        name = "東側街道",
        points = {
            {x = 70, y = 8},
            {x = 77, y = 8},
            {x = 77, y = 49},
            {x = 70, y = 49}
        }
    },
    {
        id = "south",
        name = "南側街道",
        points = {{x = 70, y = 49}, {x = 15, y = 49}}
    },
    {
        id = "west",
        name = "西側街道",
        points = {
            {x = 15, y = 49},
            {x = 8, y = 49},
            {x = 8, y = 8},
            {x = 15, y = 8}
        }
    }
}

-- 地形の座標データ
-- terrainMap[y][x] の形式で管理する。
M.terrainMap = {}

-- プレイヤーの移動テスト用の仮初期座標
-- 拠点1の街道上から開始する。
-- 正式な初期配置は別Issueで扱う。
local playerPosition = {
    x = 15,
    y = 8
}

-- プレイヤーの現在座標を取得する
-- 外部から直接座標を書き換えられないよう、コピーを返す。
function M.getPlayerPosition()
    return {
        x = playerPosition.x,
        y = playerPosition.y
    }
end

-- 座標がマップ内にあるか確認する
function M.inBounds(x, y)
    return type(x) == "number"
        and type(y) == "number"
        and x >= 1
        and x <= M.MAP_WIDTH
        and y >= 1
        and y <= M.MAP_HEIGHT
        and x == math.floor(x)
        and y == math.floor(y)
end

-- 拠点をIDから取得する
function M.getBase(id)
    for _, base in ipairs(M.bases) do
        if base.id == id then
            return base
        end
    end

    return nil
end

-- 指定座標が拠点か確認する
function M.isBase(x, y)
    if not M.inBounds(x, y) then
        return false
    end

    for _, base in ipairs(M.bases) do
        if base.x == x and base.y == y then
            return true
        end
    end

    return false
end

-- 指定座標が街道上にあるか確認する
local function isRoad(x, y)
    for _, road in ipairs(M.roads) do
        for i = 1, #road.points - 1 do
            local a = road.points[i]
            local b = road.points[i + 1]

            -- 横方向の街道
            if a.y == b.y and y == a.y then
                if x >= math.min(a.x, b.x)
                    and x <= math.max(a.x, b.x) then
                    return true
                end
            end

            -- 縦方向の街道
            if a.x == b.x and x == a.x then
                if y >= math.min(a.y, b.y)
                    and y <= math.max(a.y, b.y) then
                    return true
                end
            end
        end
    end

    return false
end

-- ラストダンジョンの配置範囲内か確認する
function M.isFinalDungeon(x, y)
    if not M.inBounds(x, y) then
        return false
    end

    local placement = dungeonData.getPlacement("final")

    if not placement or not placement.fixed then
        return false
    end

    return x >= placement.x
        and x < placement.x + placement.width
        and y >= placement.y
        and y < placement.y + placement.height
end


-- 隣接するタイル間の移動が中央の通行不能ラインを横切るか確認する
-- 移動元・移動先の座標を指定する。
function M.isBlockedMove(fromX, fromY, toX, toY)
    if not M.inBounds(fromX, fromY)
        or not M.inBounds(toX, toY) then
        return false
    end

    -- 隣接する上下左右への移動だけを判定する
    local distance = math.abs(toX - fromX)
        + math.abs(toY - fromY)

    if distance ~= 1 then
        return false
    end

    local placement = dungeonData.getPlacement("final")

    if not placement or not placement.fixed then
        return false
    end

    local left = placement.x
    local right = placement.x + placement.width - 1
    local top = placement.y
    local bottom = placement.y + placement.height - 1

    -- 外周街道の座標
    local westRoadX = 8
    local eastRoadX = 77
    local northRoadY = 8
    local southRoadY = 49

    -- 北・南のライン
    -- x方向に隣のタイルへ移動するとき、
    -- 2列の境界を横切る移動を禁止する。
    local verticalLine =
        (
            (fromX == left and toX == right)
            or
            (fromX == right and toX == left)
        )
        and (
            (fromY > northRoadY and fromY < top)
            or
            (fromY > bottom and fromY < southRoadY)
        )

    -- 西・東のライン
    -- y方向に隣のタイルへ移動するとき、
    -- 2行の境界を横切る移動を禁止する。
    local horizontalLine =
        (
            (fromY == top and toY == bottom)
            or
            (fromY == bottom and toY == top)
        )
        and (
            (fromX > westRoadX and fromX < left)
            or
            (fromX > right and fromX < eastRoadX)
        )

    return verticalLine or horizontalLine
end

-- 地形を変更できない固定場所か確認する
function M.isFixedLocation(x, y)
    if not M.inBounds(x, y) then
        return false
    end

    return isRoad(x, y)
        or M.isBase(x, y)
        or M.isFinalDungeon(x, y)
end

-- 固定場所の種類を取得する
-- 戻り値: "final_dungeon" / "base" / "road" / nil
function M.getFixedLocationType(x, y)
    if not M.inBounds(x, y) then
        return nil
    end

    if M.isFinalDungeon(x, y) then
        return "final_dungeon"
    end

    if M.isBase(x, y) then
        return "base"
    end

    if isRoad(x, y) then
        return "road"
    end

    return nil
end

-- 座標に地形を設定する
function M.setTerrain(x, y, terrainType)
    if not M.inBounds(x, y) then
        return false
    end

    -- 街道・拠点・ラストダンジョンは固定する
    if M.isFixedLocation(x, y) then
        return false
    end

    -- 街道は固定データから判定するため、ここでは設定できない
    if terrainType == terrainData.types.ROAD then
        return false
    end

    -- 存在する地形か確認する
    if not terrainData.get(terrainType) then
        return false
    end

    M.terrainMap[y] = M.terrainMap[y] or {}
    M.terrainMap[y][x] = terrainType

    return true
end

-- 座標から地形の種類を取得する
function M.getTerrainType(x, y)
    if not M.inBounds(x, y) then
        return nil
    end

    -- ラストダンジョンは通常地形として扱わない
    if M.isFinalDungeon(x, y) then
        return nil
    end

    -- 街道を優先する
    if isRoad(x, y) then
        return terrainData.types.ROAD
    end

    local row = M.terrainMap[y]

    if not row then
        return nil
    end

    return row[x]
end

-- 座標から地形データを取得する
function M.getTerrain(x, y)
    local terrainType = M.getTerrainType(x, y)

    if not terrainType then
        return nil
    end

    return terrainData.get(terrainType)
end

-- 座標から移動時間（秒）を取得する
function M.getMoveSeconds(x, y)
    local terrainType = M.getTerrainType(x, y)

    if not terrainType then
        return nil
    end

    return terrainData.getMoveSeconds(terrainType)
end

-- プレイヤーを上下左右に1タイル移動させる。
-- dx: 左 -1 / 右 1
-- dy: 上 -1 / 下 1
--
-- 成功: true, 消費した秒数
-- 失敗: false, 理由
function M.movePlayer(dx, dy)
    -- 上下左右の1タイル移動だけを許可する。
    if (dx ~= -1 and dx ~= 0 and dx ~= 1)
        or (dy ~= -1 and dy ~= 0 and dy ~= 1) then
        return false, "invalid_direction"
    end

    if math.abs(dx) + math.abs(dy) ~= 1 then
        return false, "invalid_direction"
    end

    local fromX = playerPosition.x
    local fromY = playerPosition.y

    local toX = fromX + dx
    local toY = fromY + dy

    -- マップ外への移動を禁止する。
    if not M.inBounds(toX, toY) then
        return false, "out_of_bounds"
    end

    -- 中央の通行不能ラインを横切る移動を禁止する。
    if M.isBlockedMove(fromX, fromY, toX, toY) then
        return false, "blocked"
    end

    -- 移動先の地形を確認する。
    local terrainType = M.getTerrainType(toX, toY)

    -- 未設定地形やラストダンジョンには移動できない。
    if not terrainType then
        return false, "unassigned_terrain"
    end

    -- 地形に応じて世界時間を進める。
    local success, seconds = fieldTerrain.advanceTime(terrainType)

    if not success then
        return false, "invalid_terrain"
    end

    -- 時間進行が成功した場合だけ座標を更新する。
    playerPosition.x = toX
    playerPosition.y = toY

    return true, seconds
end

return M