

local M = {}

function M.calc(a,b)
    local dmg = a.atk - b.def
    if dmg < 1 then dmg = 1 end

    if b.damage_cut then
        dmg = dmg * (1 - b.damage_cut)
    end

    return math.floor(dmg + 0.5)
end

return M
