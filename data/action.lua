-- data/action.lua: 武器種別などに対応する行動コスト・待機時間データを提供する責務。
local M = {
    weapon = {
        physical = {
            [60] = {cost=0, wait=60},
            [90] = {cost=0, wait=90}
        },
        magic = {
            [60] = {cost=60, wait=0},
            [90] = {cost=90, wait=0}
        }
    },
    counter={cost=0, wait=30},
    activation_wait={cost=0, wait=30},
    special={cost=0, wait=30},
    final_action={cost=0, wait=30},
    defense={cost=50, wait=0}
}

function M.forWeapon(weapon)
    local damageType = weapon.damage_type or "physical"
    local wait = weapon.wait or 60
    local byType = M.weapon[damageType] or M.weapon.physical
    return byType[wait] or {cost=wait, wait=0}
end

return M
