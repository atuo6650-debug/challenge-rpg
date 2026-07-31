-- battle/damage.lua: 攻撃・防御・状態異常を踏まえたダメージ計算を担当する責務。

local M = {}

function M.calc(a,b,damageType)
    local attack = a.atk or 0
    local defense = b.def or 0

    if damageType == "physical" then
        attack = a.physical_atk or attack
        defense = b.physical_def or defense
    elseif damageType == "magic" then
        attack = a.magic_atk or attack
        defense = b.magic_def or defense
    end

    local dmg = attack - defense
    if dmg < 1 then dmg = 1 end

    if b.damage_cut then
        dmg = dmg * (1 - b.damage_cut)
    end

    if damageType == "physical" and a.blinded then
        dmg = dmg * 0.2
    end

    if damageType == "magic" and a.silenced then
        dmg = dmg * 0.2
    end

    -- スタン中の被ダメージ倍率は他の効果とは独立した倍率として扱う
    if b.stunned then
        dmg = dmg * 1.3
    end

    return math.floor(dmg + 0.5)
end

return M
