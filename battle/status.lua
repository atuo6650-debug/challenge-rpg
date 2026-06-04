local M = {}

local STATUS_DURATION_ENERGY = 90
local ACTIVE_STATUSES = {"stun", "blind", "silence", "curse", "paralysis"}

local function clearStun(u)
    if u.stunned then
        u.stunned = false
        u.stun_energy = 0
        u.just_recovered = true
    end
end

local function startStun(u)
    u.stunned = true
    u.stun_energy = 0
    u.action = nil
    u.cost = 0
    u.wait = 0
    u.action_started = false
    u.just_stunned = true
end

local function startTimedStatus(u, statusName)
    if statusName == "blind" then
        u.blinded = true
        u.blind_energy = 0
    end
    if statusName == "silence" then
        u.silenced = true
        u.silence_energy = 0
    end
end

local function add(t, k, v, resist)
    if not t.status[k] then return end

    local gain = v * (1 - (resist or 0))
    t.status[k] = math.min(100, t.status[k] + gain)
end

local function reduceGauge(gauges, amount)
    local remaining = amount
    table.sort(gauges, function(a, b) return a.value > b.value end)

    for _, gauge in ipairs(gauges) do
        if remaining <= 0 then break end
        local spent = math.min(gauge.value, remaining)
        gauge.value = gauge.value - spent
        remaining = remaining - spent
    end
end

function M.statusNames()
    return ACTIVE_STATUSES
end

function M.initStatuses(u)
    u.status = {}
    u.resist = {}

    for _, name in ipairs(ACTIVE_STATUSES) do
        u.status[name] = 0
        u.resist[name] = 0
    end

    u.stunned = false
    u.stun_energy = 0
    u.blinded = false
    u.blind_energy = 0
    u.silenced = false
    u.silence_energy = 0
    u.final_action_used = false
end

function M.refreshGaugeTotals(unit)
    local special = 0
    for _, gauge in ipairs(unit.special_gauges or {}) do
        special = special + gauge.value
    end
    unit.special = special

    local counter = 0
    for _, gauge in ipairs(unit.counter_gauges or {}) do
        counter = counter + gauge.value
    end
    unit.counter_gauge = counter
end

function M.consumeSpecial(unit, amount)
    reduceGauge(unit.special_gauges or {}, amount)
    M.refreshGaugeTotals(unit)
end

function M.reduceSpecial(unit, amount)
    M.consumeSpecial(unit, amount)
end

function M.reduceCounter(unit, amount)
    reduceGauge(unit.counter_gauges or {}, amount)
    M.refreshGaugeTotals(unit)
end

function M.addSpecialGauge(unit, gain)
    for _, gauge in ipairs(unit.special_gauges or {}) do
        if not gauge.consumed then
            gauge.value = math.min(100, gauge.value + gain)
        end
    end
    M.refreshGaugeTotals(unit)
end

function M.addCounterGauge(unit)
    for _, gauge in ipairs(unit.counter_gauges or {}) do
        local gain = gauge.gain or 10
        gauge.value = math.min(100, gauge.value + gain)
    end
    M.refreshGaugeTotals(unit)
end

function M.readySpecialGauge(unit, predicate)
    for _, gauge in ipairs(unit.special_gauges or {}) do
        if gauge.value >= 100 and (not predicate or predicate(gauge)) then
            return gauge
        end
    end

    return nil
end

function M.consumeGauge(gauge, amount)
    gauge.value = math.max(0, gauge.value - amount)
end

function M.onHit(a, b)
    -- 状態異常付与（アクセ）
    if a.inflict then
        add(b, a.inflict.type, a.inflict.value, b.resist[a.inflict.type])
    end

    -- スタン
    add(b,"stun",20,b.resist.stun)

    -- 発動
    for k,v in pairs(b.status) do
        if v >= 100 then
            b.status[k] = 0

            if k=="stun" then startStun(b) end
            if k=="blind" then startTimedStatus(b, "blind") end
            if k=="silence" then startTimedStatus(b, "silence") end
            if k=="curse" and b.reduceSpecial then b.reduceSpecial(50) end
            if k=="paralysis" and b.reduceCounter then b.reduceCounter(50) end
        end
    end
end

function M.onDamaged(u)
    clearStun(u)
end

function M.updateStun(u, energyGain)
    if not u.stunned then return false end

    u.stun_energy = (u.stun_energy or 0) + energyGain
    if u.stun_energy >= STATUS_DURATION_ENERGY then
        clearStun(u)
    end

    return true
end

function M.updateTimed(u, energyGain)
    if u.blinded then
        u.blind_energy = (u.blind_energy or 0) + energyGain
        if u.blind_energy >= STATUS_DURATION_ENERGY then
            u.blinded = false
            u.blind_energy = 0
        end
    end

    if u.silenced then
        u.silence_energy = (u.silence_energy or 0) + energyGain
        if u.silence_energy >= STATUS_DURATION_ENERGY then
            u.silenced = false
            u.silence_energy = 0
        end
    end
end

return M
