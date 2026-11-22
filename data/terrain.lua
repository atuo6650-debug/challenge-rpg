
-- data/terrain.lua
-- 地形の種類と基本データを管理する。

local M = {}

-- 地形の定義
M.types = {
    GRASSLAND = "grassland",
    FOREST = "forest",
    MOUNTAIN = "mountain",
    ROAD = "road"
}

-- 地形ごとの基本データ
M.definitions = {
    grassland = {
        name = "草地",
        moveSeconds = 1200
    },

    forest = {
        name = "森林",
        moveSeconds = 1800
    },

    mountain = {
        name = "山地",
        moveSeconds = 2400
    },

    road = {
        name = "街道",
        moveSeconds = 600
    }
}

-- 面積比率（街道・ラストダンジョンを除く）
M.areaRatio = {
    grassland = 2,
    forest = 1,
    mountain = 1
}

-- 地形データを取得する
function M.get(terrainType)
    return M.definitions[terrainType]
end

-- 地形の移動時間を取得する
function M.getMoveSeconds(terrainType)
    local terrain = M.get(terrainType)

    if not terrain then
        return nil
    end

    return terrain.moveSeconds
end

return M
