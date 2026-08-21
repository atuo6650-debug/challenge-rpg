-- core/state.lua: 今後、ゲーム進行状況、プレイヤーデータ、共有状態を保持する責務。
local M = {}

-- 世界時間モジュールの読み込み
local time = require("core.time")

-- ゲーム状態
M.worldTime = {
    totalSeconds = 0  -- 初期時間: Y1/1 00:00:00 = 0秒
}

--- 世界時間を進める
-- @param seconds 進める秒数
function M.advanceWorldTime(seconds)
    M.worldTime.totalSeconds = M.worldTime.totalSeconds + seconds
end

--- 現在の世界時間を年月日時分秒で取得
-- @return table {year, month, day, hour, minute, second}
function M.getWorldDateTime()
    return time.secondsToDatetime(M.worldTime.totalSeconds)
end

--- 現在の季節を取得
-- @return string 季節名 ("春", "夏", "秋", "冬")
function M.getCurrentSeason()
    return time.getSeason(M.worldTime.totalSeconds)
end

--- 現在の昼夜を取得
-- @return string 昼夜 ("昼", "夜")
function M.getCurrentDayPeriod()
    return time.getDayPeriod(M.worldTime.totalSeconds)
end

--- 世界時間を設定 (デバッグ用)
-- @param year 年
-- @param month 月
-- @param day 日
-- @param hour 時
-- @param minute 分
-- @param second 秒
function M.setWorldTime(year, month, day, hour, minute, second)
    M.worldTime.totalSeconds = time.datetimeToSeconds(year, month, day, hour, minute, second)
end

return M
