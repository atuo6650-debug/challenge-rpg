-- ui/time.lua: 世界時間の表示を担当
local timeCore = require("core.time")

local M = {}

--- 秒数をフォーマットされた日付時刻文字列に変換
-- @param totalSeconds 秒数
-- @return string フォーマットされた文字列 "M/D HH:MM:SS"
function M.formatDateTime(totalSeconds)
    local dt = timeCore.secondsToDatetime(totalSeconds)
    return string.format("%d/%d %02d:%02d:%02d", 
        dt.month, dt.day, dt.hour, dt.minute, dt.second)
end

--- 秒数を時刻のみの文字列に変換
-- @param totalSeconds 秒数
-- @return string フォーマットされた時刻文字列 "HH:MM:SS"
function M.formatTime(totalSeconds)
    local dt = timeCore.secondsToDatetime(totalSeconds)
    return string.format("%02d:%02d:%02d", dt.hour, dt.minute, dt.second)
end

--- すべての時間情報を取得
-- @param totalSeconds 秒数
-- @return table {month, day, hour, minute, second, season, dayPeriod}
function M.getTimeInfo(totalSeconds)
    local dt = timeCore.secondsToDatetime(totalSeconds)
    return {
        month = dt.month,
        day = dt.day,
        hour = dt.hour,
        minute = dt.minute,
        second = dt.second,
        season = timeCore.getSeason(totalSeconds),
        dayPeriod = timeCore.getDayPeriod(totalSeconds)
    }
end

return M
