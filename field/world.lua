
-- field/world.lua
-- ワールドマップの基本データ、座標、地形を管理する。

local M = {}

local terrainData = require("data.terrain")

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

-- 座標に地形を設定する
function M.setTerrain(x, y, terrainType)
    if not M.inBounds(x, y) then
        return false
    end

    -- 街道の地形は固定する
    if isRoad(x, y) then
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

return M
