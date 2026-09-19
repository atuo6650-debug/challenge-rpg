-- ui/time.lua: 世界時間の表示用
local worldTime = require("core.time")

local M = {}

-- 世界時間の情報を取得
-- @param totalSeconds 世界時間（秒）
-- @return table
-- {
--     year,
--     month,
--     day,
--     hour,
--     minute,
--     second,
--     season,
--     dayPeriod
-- }
function M.getTimeInfo(totalSeconds)
    local datetime = worldTime.secondsToDatetime(totalSeconds)

    return {
        year = datetime.year,
        month = datetime.month,
        day = datetime.day,
        hour = datetime.hour,
        minute = datetime.minute,
        second = datetime.second,
        season = worldTime.getSeason(totalSeconds),
        dayPeriod = worldTime.getDayPeriod(totalSeconds)
    }
end

-- 時刻だけを整形
-- 例: 00:00:00
function M.formatTime(totalSeconds)
    local info = M.getTimeInfo(totalSeconds)

    return string.format(
        "%02d:%02d:%02d",
        info.hour,
        info.minute,
        info.second
    )
end

-- 年月日＋時刻を整形
-- 例: 1/1 00:00:00
function M.formatDateTime(totalSeconds)
    local info = M.getTimeInfo(totalSeconds)

    return string.format(
        "%d/%d %02d:%02d:%02d",
        info.month,
        info.day,
        info.hour,
        info.minute,
        info.second
    )
end

-- 年月日＋時刻＋季節＋昼夜を整形
-- 例: Year 1 1/1 00:00:00 冬 夜
function M.formatDateTimeWithYear(totalSeconds)
    local info = M.getTimeInfo(totalSeconds)

    return string.format(
        "Year %d %d/%d %02d:%02d:%02d %s %s",
        info.year,
        info.month,
        info.day,
        info.hour,
        info.minute,
        info.second,
        info.season,
        info.dayPeriod
    )
end

return M