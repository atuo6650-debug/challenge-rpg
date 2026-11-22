-- data/dungeon.lua
-- ダンジョンの種類と配置座標を管理する。

local M = {}

-- ダンジョンの定義
-- ダンジョンIDをキーとして、種類や適合地形などを管理する。
M.definitions = {
    -- 今後、ダンジョンごとの定義を追加する。
}

-- ダンジョンの配置座標
-- ダンジョンIDをキーとして、ワールドマップ上の座標を管理する。
M.placements = {
    -- ラストダンジョン
    -- 84×56マップの中央に2×2タイルで固定する。
    final = {
        x = 42,
        y = 28,
        width = 2,
        height = 2,
        fixed = true
    }
}

-- ダンジョンの定義をIDから取得する
function M.getDefinition(id)
    return M.definitions[id]
end

-- ダンジョンの配置座標をIDから取得する
function M.getPlacement(id)
    return M.placements[id]
end

return M