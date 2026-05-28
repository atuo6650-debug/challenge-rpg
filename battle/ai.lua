

local actions = require("data.action")

local M = {}

function M.decide(u, target)

    if u.action then return end

    -- 特殊行動
    if u.special >= 100 then

        if (u.special_condition == "stun" or u.special_condition == "wait_stunned") and target.stunned then
            u.special = 0
            u.action = "special"
            u.cost = 0
            return
        end

        if u.special_condition == "wait_stunned" then
            return
        end

        -- 即時型
        u.special = 0
        u.action = "special"
        u.cost = 0
        return
    end

    -- パターン行動
    local act = u.pattern[u.patternIndex]

    u.patternIndex = u.patternIndex + 1
    if u.patternIndex > #u.pattern then
        u.patternIndex = 1
    end

    u.action = act
    u.cost = actions[act].cost
end

return M
