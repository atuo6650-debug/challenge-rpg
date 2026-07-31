-- unit/builder.lua: データ定義からプレイヤー・敵ユニットを生成する責務。
local M = {}

local BASE_STAT_KEYS = {"vitality", "strength", "magic", "focus", "spirit"}

local function value(data, key)
    return data[key] or 0
end

function M.applyBaseParameters(unit, data)
    unit.base = {}
    for _, key in ipairs(BASE_STAT_KEYS) do
        unit.base[key] = value(data, key)
        unit[key] = unit.base[key]
    end

    unit.maxhp = unit.base.vitality + unit.base.strength + unit.base.magic + unit.base.focus + unit.base.spirit
    unit.hp = data.hp or unit.maxhp
    unit.physical_atk = unit.base.strength + unit.base.magic + unit.base.focus
    unit.magic_atk = unit.base.strength + unit.base.magic + unit.base.spirit
    unit.physical_def = unit.base.strength + unit.base.focus + unit.base.spirit
    unit.magic_def = unit.base.magic + unit.base.focus + unit.base.spirit

    -- 既存処理との互換用。ダメージ種別未指定時のみ利用する。
    unit.atk = data.atk or unit.physical_atk
    unit.def = data.def or unit.physical_def
end

function M.baseStatKeys()
    return BASE_STAT_KEYS
end

return M
