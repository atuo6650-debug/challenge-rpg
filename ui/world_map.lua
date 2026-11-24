
-- ui/world_map.lua
-- ワールドマップの地形・街道・拠点・ダンジョン・通行不能帯の描画を担当する。

local world = require("field.world")
local terrainData = require("data.terrain")
local dungeonData = require("data.dungeon")

local M = {}

local TILE_SIZE = world.TILE_SIZE

-- 地形ごとの表示色
local terrainColors = {
    grassland = {0.45, 0.65, 0.30},
    forest = {0.15, 0.40, 0.20},
    mountain = {0.50, 0.48, 0.45},
    road = {0.75, 0.65, 0.40}
}

-- 地形未設定時の仮表示色
local unknownColor = {0.30, 0.35, 0.30}

-- 通行不能帯の表示色
local blockedColor = {0.12, 0.12, 0.15}

-- タイルを描画する
local function drawTile(x, y, color, originX, originY)
    love.graphics.setColor(color[1], color[2], color[3], 1)

    love.graphics.rectangle(
        "fill",
        originX + (x - 1) * TILE_SIZE,
        originY + (y - 1) * TILE_SIZE,
        TILE_SIZE,
        TILE_SIZE
    )
end

-- 地形を描画する
local function drawTerrain(originX, originY)
    for y = 1, world.MAP_HEIGHT do
        for x = 1, world.MAP_WIDTH do
            local terrainType = world.getTerrainType(x, y)

            local color = unknownColor

            if terrainType then
                color = terrainColors[terrainType] or unknownColor
            end

            drawTile(x, y, color, originX, originY)
        end
    end
end

-- 拠点を描画する
local function drawBases(originX, originY)
    for i, base in ipairs(world.bases) do
        local x = originX + (base.x - 1) * TILE_SIZE
        local y = originY + (base.y - 1) * TILE_SIZE

        love.graphics.setColor(0.20, 0.65, 0.95, 1)

        love.graphics.rectangle(
            "fill",
            x + 2,
            y + 2,
            TILE_SIZE - 4,
            TILE_SIZE - 4
        )

        love.graphics.setColor(1, 1, 1, 1)

        love.graphics.printf(
            tostring(i),
            x,
            y + 3,
            TILE_SIZE,
            "center"
        )
    end
end

-- ラストダンジョンを描画する
local function drawFinalDungeon(originX, originY)
    local placement = dungeonData.getPlacement("final")

    if not placement then
        return
    end

    if not placement.fixed then
        return
    end

    love.graphics.setColor(0.65, 0.15, 0.20, 1)

    love.graphics.rectangle(
        "fill",
        originX + (placement.x - 1) * TILE_SIZE,
        originY + (placement.y - 1) * TILE_SIZE,
        placement.width * TILE_SIZE,
        placement.height * TILE_SIZE
    )

    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.rectangle(
        "line",
        originX + (placement.x - 1) * TILE_SIZE,
        originY + (placement.y - 1) * TILE_SIZE,
        placement.width * TILE_SIZE,
        placement.height * TILE_SIZE
    )
end

-- 十字型通行不能帯を描画する
-- field/world.lua の isBlockedMove() と同じ境界座標を使用する。
local function drawBlockedAreas(originX, originY)
    love.graphics.setColor(
        blockedColor[1],
        blockedColor[2],
        blockedColor[3],
        1
    )

    love.graphics.setLineWidth(4)

    -- 縦方向の境界
    -- 北側と南側の通路部分は描画しない。
    local verticalRows = {
        {9, 27},
        {30, 48}
    }

    for _, range in ipairs(verticalRows) do
        for y = range[1], range[2] do
            love.graphics.line(
                originX + 42 * TILE_SIZE,
                originY + (y - 1) * TILE_SIZE,
                originX + 42 * TILE_SIZE,
                originY + y * TILE_SIZE
            )
        end
    end

    -- 横方向の境界
    -- 西側と東側の通路部分は描画しない。
    local horizontalRanges = {
        {9, 41},
        {44, 76}
    }

    for _, range in ipairs(horizontalRanges) do
        for x = range[1], range[2] do
            love.graphics.line(
                originX + (x - 1) * TILE_SIZE,
                originY + 28 * TILE_SIZE,
                originX + x * TILE_SIZE,
                originY + 28 * TILE_SIZE
            )
        end
    end

    love.graphics.setLineWidth(1)
end

-- ワールドマップ全体を描画する
-- originX, originY は画面上のマップ描画開始位置。
-- 画面スクロールは呼び出し側から座標を渡して調整する。
function M.draw(originX, originY)
    originX = originX or 0
    originY = originY or 0

    drawTerrain(originX, originY)
    drawBases(originX, originY)
    drawFinalDungeon(originX, originY)
    drawBlockedAreas(originX, originY)

    love.graphics.setColor(1, 1, 1, 1)
end

return M
