

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

        if u.special_condition == "wait_stunned" or u.special_condition == "final_action" then
            -- スペシャルの発動条件を待っている間も、通常の武器パターン行動は継続する
        else
            -- 即時型
            u.special = 0
            u.action = "special"
            u.cost = 0
            return
        end

        -- 待機型はスペシャルゲージを保持したままパターン行動へ進む
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
