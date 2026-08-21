-- core/time.lua: 世界時間の基盤
local M = {}

-- 時間定数
M.DAYS_PER_YEAR = 360
M.DAYS_PER_MONTH = 30
M.HOURS_PER_DAY = 24
M.SECONDS_PER_MINUTE = 60
M.SECONDS_PER_HOUR = 3600
M.SECONDS_PER_DAY = 86400

-- 季節の定義 (月)
M.SEASONS = {
    SPRING = { start_month = 4, end_month = 6, name = "春" },
    SUMMER = { start_month = 7, end_month = 9, name = "夏" },
    AUTUMN = { start_month = 10, end_month = 12, name = "秋" },
    WINTER = { start_month = 1, end_month = 3, name = "冬" },
}

-- 昼夜の定義 (時間)
M.DAY_PERIODS = {
    DAY = { start_hour = 6, end_hour = 17, name = "昼" },      -- 6:00～17:59
    NIGHT = { start_hour = 18, end_hour = 5, name = "夜" },    -- 18:00～5:59
}

--- 秒を年月日時分秒に変換
-- @param totalSeconds 秒数
-- @return table {year, month, day, hour, minute, second}
function M.secondsToDatetime(totalSeconds)
    local seconds = totalSeconds % M.SECONDS_PER_MINUTE
    local totalMinutes = math.floor(totalSeconds / M.SECONDS_PER_MINUTE)
    local minutes = totalMinutes % M.SECONDS_PER_MINUTE
    
    local totalHours = math.floor(totalMinutes / M.SECONDS_PER_MINUTE)
    local hours = totalHours % M.HOURS_PER_DAY
    
    local totalDays = math.floor(totalHours / M.HOURS_PER_DAY)
    
    local year = math.floor(totalDays / M.DAYS_PER_YEAR) + 1  -- Y1から開始
    local dayOfYear = (totalDays % M.DAYS_PER_YEAR) + 1
    
    local month = math.floor((dayOfYear - 1) / M.DAYS_PER_MONTH) + 1
    local day = ((dayOfYear - 1) % M.DAYS_PER_MONTH) + 1
    
    return {
        year = year,
        month = month,
        day = day,
        hour = hours,
        minute = minutes,
        second = seconds
    }
end

--- 年月日時分秒を秒に変換
-- @param year 年
-- @param month 月
-- @param day 日
-- @param hour 時
-- @param minute 分
-- @param second 秒
-- @return number 秒数
function M.datetimeToSeconds(year, month, day, hour, minute, second)
    year = year or 1
    month = month or 1
    day = day or 1
    hour = hour or 0
    minute = minute or 0
    second = second or 0
    
    local totalDays = (year - 1) * M.DAYS_PER_YEAR
        + (month - 1) * M.DAYS_PER_MONTH
        + (day - 1)
    
    local totalSeconds = totalDays * M.SECONDS_PER_DAY
        + hour * M.SECONDS_PER_HOUR
        + minute * M.SECONDS_PER_MINUTE
        + second
    
    return totalSeconds
end

--- 秒から季節を導出
-- @param totalSeconds 秒数
-- @return string 季節名 ("春", "夏", "秋", "冬")
function M.getSeason(totalSeconds)
    local datetime = M.secondsToDatetime(totalSeconds)
    local month = datetime.month
    
    if month >= M.SEASONS.SPRING.start_month and month <= M.SEASONS.SPRING.end_month then
        return M.SEASONS.SPRING.name
    elseif month >= M.SEASONS.SUMMER.start_month and month <= M.SEASONS.SUMMER.end_month then
        return M.SEASONS.SUMMER.name
    elseif month >= M.SEASONS.AUTUMN.start_month and month <= M.SEASONS.AUTUMN.end_month then
        return M.SEASONS.AUTUMN.name
    else  -- 冬 (1～3月)
        return M.SEASONS.WINTER.name
    end
end

--- 秒から昼夜を導出
-- @param totalSeconds 秒数
-- @return string 昼夜 ("昼", "夜")
function M.getDayPeriod(totalSeconds)
    local datetime = M.secondsToDatetime(totalSeconds)
    local hour = datetime.hour
    
    if hour >= M.DAY_PERIODS.DAY.start_hour and hour <= M.DAY_PERIODS.DAY.end_hour then
        return M.DAY_PERIODS.DAY.name
    else
        return M.DAY_PERIODS.NIGHT.name
    end
end

return M
