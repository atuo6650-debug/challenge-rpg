
-- field/terrain.lua
-- 移動先の地形に応じた時間進行を管理する。

local M = {}

local terrainData = require("data.terrain")
local state = require("core.state")

-- 指定された地形の移動時間だけ世界時間を進める。
-- @param terrainType 地形の種類
-- @return 成功した場合 true, 加算した秒数
--         失敗した場合 false, nil
function M.advanceTime(terrainType)
    local seconds = terrainData.getMoveSeconds(terrainType)

    -- 未設定地形や存在しない地形では時間を進めない。
    if not seconds then
        return false, nil
    end

    state.advanceWorldTime(seconds)

    return true, seconds
end

return M
