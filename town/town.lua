-- town/town.lua: 町シーン全体の進行、施設遷移、町イベントを管理する責務。
local M = {}

local currentDistrict = "grass"
local playerUnit = nil
local message = "町に到着した"

function M.returnToTown(district, unit, reason)
    currentDistrict = district or currentDistrict
    playerUnit = unit or playerUnit
    if playerUnit then
        playerUnit.hp = playerUnit.maxhp
    end
    if reason == "defeat" then
        message = "敗北したため、同地区の町へ戻った"
    else
        message = "同地区の町へ戻った"
    end
end

function M.currentDistrict()
    return currentDistrict
end

function M.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Town - " .. currentDistrict, 40, 40)
    love.graphics.print(message, 40, 64)
    love.graphics.print("Enter: ダンジョン入口へ戻る", 40, 88)
end

return M
