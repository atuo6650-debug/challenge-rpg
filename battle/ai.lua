
local M = {}

local function specialReadyGauge(u)
    if not u.special_gauges then return nil end

    for _, gauge in ipairs(u.special_gauges) do
        if gauge.value >= 100 then
            return gauge
        end
    end

    return nil
end

function M.decide(u, target)

    if u.action then return end

    -- 特殊行動
    local readySpecial = specialReadyGauge(u)
    if readySpecial then
        local condition = readySpecial.condition

        if (condition == "stun" or condition == "wait_stunned") and target.stunned then
            u.consumeSpecial(100)
            u.action = "special"
            u.cost = 0
            u.action_started = false
            return
        end

        if condition == "wait_stunned" or condition == "final_action" then
            -- スペシャルの発動条件を待っている間も、通常の武器パターン行動は継続する
        else
            -- 即時型
            u.consumeSpecial(100)
            u.action = "special"
            u.cost = 0
            u.action_started = false
            return
        end

        -- 待機型はスペシャルゲージを保持したままパターン行動へ進む
    end

    -- パターン行動
    local weapon = u.pattern[u.patternIndex]

    u.patternIndex = u.patternIndex + 1
    if u.patternIndex > #u.pattern then
        u.patternIndex = 1
    end

    u.action = "weapon"
    u.pending_weapon = weapon
    u.cost = weapon.wait
    u.action_started = false
end

return M
