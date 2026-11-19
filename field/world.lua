
-- field/world.lua
-- ワールドマップの基本データと座標管理を担当する。

local M = {}

-- マップ基本設定
M.TILE_SIZE = 18
M.MAP_WIDTH = 84
M.MAP_HEIGHT = 56

-- 4つの拠点
M.bases = {
    {
        id = "base_1",
        name = "拠点1",
        x = 15,
        y = 8
    },
    {
        id = "base_2",
        name = "拠点2",
        x = 70,
        y = 8
    },
    {
        id = "base_3",
        name = "拠点3",
        x = 15,
        y = 49
    },
    {
        id = "base_4",
        name = "拠点4",
        x = 70,
        y = 49
    }
}

-- 拠点間を結ぶ街道
-- points は街道の曲がり角と接続地点を示す。
-- 各地点間は直線で結ぶ。
M.roads = {
    {
        id = "north",
        name = "北側街道",
        points = {
            { x = 15, y = 8 },
            { x = 70, y = 8 }
        }
    },
    {
        id = "east",
        name = "東側街道",
        points = {
            { x = 70, y = 8 },
            { x = 77, y = 8 },
            { x = 77, y = 49 },
            { x = 70, y = 49 }
        }
    },
    {
        id = "south",
        name = "南側街道",
        points = {
            { x = 70, y = 49 },
            { x = 15, y = 49 }
        }
    },
    {
        id = "west",
        name = "西側街道",
        points = {
            { x = 15, y = 49 },
            { x = 8, y = 49 },
            { x = 8, y = 8 },
            { x = 15, y = 8 }
        }
    }
}

-- 座標がマップ内か確認する
function M.inBounds(x, y)
    return x >= 1
        and x <= M.MAP_WIDTH
        and y >= 1
        and y <= M.MAP_HEIGHT
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

return M
