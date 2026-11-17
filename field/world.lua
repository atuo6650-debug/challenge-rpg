-- field/world.lua: 今後、ワールドマップやフィールド移動の状態を管理する責務。

-- field/world.lua
-- ワールドマップの基本データと座標管理を担当する。

local M = {}

-- マップ基本設定
M.TILE_SIZE = 18
M.MAP_WIDTH = 84
M.MAP_HEIGHT = 56

-- 地点の種類
M.LOCATION_TYPE = {
    BASE = "base",
    DUNGEON = "dungeon",
    FINAL_DUNGEON = "final_dungeon"
}

-- 4つの拠点
M.bases = {
    {
        id = "base_1",
        name = "拠点1",
        x = 8,
        y = 8
    },
    {
        id = "base_2",
        name = "拠点2",
        x = 77,
        y = 8
    },
    {
        id = "base_3",
        name = "拠点3",
        x = 8,
        y = 49
    },
    {
        id = "base_4",
        name = "拠点4",
        x = 77,
        y = 49
    }
}

-- 各拠点に属する3つのダンジョン入口
M.dungeons = {
    {
        id = "dungeon_1",
        baseId = "base_1",
        name = "ダンジョン1",
        x = 16,
        y = 8
    },
    {
        id = "dungeon_2",
        baseId = "base_1",
        name = "ダンジョン2",
        x = 14,
        y = 14
    },
    {
        id = "dungeon_3",
        baseId = "base_1",
        name = "ダンジョン3",
        x = 8,
        y = 17
    },
    {
        id = "dungeon_4",
        baseId = "base_2",
        name = "ダンジョン4",
        x = 69,
        y = 8
    },
    {
        id = "dungeon_5",
        baseId = "base_2",
        name = "ダンジョン5",
        x = 71,
        y = 14
    },
    {
        id = "dungeon_6",
        baseId = "base_2",
        name = "ダンジョン6",
        x = 77,
        y = 17
    },
    {
        id = "dungeon_7",
        baseId = "base_3",
        name = "ダンジョン7",
        x = 16,
        y = 49
    },
    {
        id = "dungeon_8",
        baseId = "base_3",
        name = "ダンジョン8",
        x = 14,
        y = 43
    },
    {
        id = "dungeon_9",
        baseId = "base_3",
        name = "ダンジョン9",
        x = 8,
        y = 40
    },
    {
        id = "dungeon_10",
        baseId = "base_4",
        name = "ダンジョン10",
        x = 69,
        y = 49
    },
    {
        id = "dungeon_11",
        baseId = "base_4",
        name = "ダンジョン11",
        x = 71,
        y = 43
    },
    {
        id = "dungeon_12",
        baseId = "base_4",
        name = "ダンジョン12",
        x = 77,
        y = 40
    }
}

-- 最終ダンジョン
M.finalDungeon = {
    id = "final_dungeon",
    name = "最終ダンジョン",
    x = 42,
    y = 28
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

-- ダンジョンをIDから取得する
function M.getDungeon(id)
    for _, dungeon in ipairs(M.dungeons) do
        if dungeon.id == id then
            return dungeon
        end
    end

    return nil
end

return M
