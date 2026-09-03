-- field/world.lua: 今後、ワールドマップやフィールド移動の状態を管理する責務。
local worldTime = require("core.world_time")
local timeUI = require("ui.time")

local M = {}

--- フィールド状態の初期化
function M.init()
    worldTime.init()
end

--- フィールド更新
-- @param dt デルタタイム
function M.update(dt)
    -- 時間を進める（dt は通常 1/60 秒）
    worldTime.advance(dt)
end

--- 世界時間の秒数を取得
-- @return number 世界時間（秒）
function M.getWorldSeconds()
    return worldTime.getSeconds()
end

--- 世界時間情報を表示（月日時刻、季節、昼夜）
-- @param x 描画X座標
-- @param y 描画Y座標
function M.drawTimeInfo(x, y)
    local seconds = M.getWorldSeconds()
    local timeInfo = timeUI.getTimeInfo(seconds)
    local formattedTime = timeUI.formatDateTime(seconds)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("時刻: " .. formattedTime, x, y)
    love.graphics.print("季節: " .. timeInfo.season, x, y + 16)
    love.graphics.print("昼夜: " .. timeInfo.dayPeriod, x, y + 32)
end

return M
