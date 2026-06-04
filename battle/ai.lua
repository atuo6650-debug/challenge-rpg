local actions = require("data.action")

local M = {}

local function specialCanFire(gauge, target)
    local condition = gauge.condition

    if condition == "stun" or condition == "wait_stunned" then
        return target.stunned
    end

    if condition == "final_action" then
        return false
    end

    return true
end

local function readySpecialGauge(u, target)
    if not u.special_gauges then return nil end

    for _, gauge in ipairs(u.special_gauges) do
        if gauge.value >= 100 and specialCanFire(gauge, target) then
            return gauge
        end
    end

    return nil
end

function M.decide(u, target)

    if u.action then return end

    -- 特殊行動: 発動条件を満たさないゲージは保持したまま、他のゲージも確認する
    local readySpecial = readySpecialGauge(u, target)
    if readySpecial then
        readySpecial.value = readySpecial.value - 100
        u.action = "special"
        u.pending_special_gauge = readySpecial
        u.cost = actions.special.cost
        u.wait = actions.special.wait
        u.energy = 0
        u.action_started = false
        u.refreshGaugeTotals()
        return
    end

    -- パターン行動
    local weapon = u.pattern[u.patternIndex]
    if not weapon then return end

    u.patternIndex = u.patternIndex + 1
    if u.patternIndex > #u.pattern then
        u.patternIndex = 1
    end

    local action = actions.forWeapon(weapon)
    u.action = "weapon"
    u.pending_weapon = weapon
    u.cost = action.cost
    u.wait = action.wait
    u.energy = 0
    u.action_started = false
end

return M
