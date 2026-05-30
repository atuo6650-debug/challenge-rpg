

local M = {}

function M.calc(a,b)
    local dmg = a.atk - b.def
    if dmg < 1 then dmg = 1 end

    if b.damage_cut then
        dmg = dmg * (1 - b.damage_cut)
    end

    -- スタン中の被ダメージ倍率は他の効果とは独立した倍率として扱う
    if b.stunned then
        dmg = dmg * 1.3
    end

    return math.floor(dmg + 0.5)
end

return M
