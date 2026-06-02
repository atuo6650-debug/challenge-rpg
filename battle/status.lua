
local M = {}

local STATUS_DURATION_ENERGY = 90

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
    local gain = v * (1 - (resist or 0))
    t.status[k] = math.min(100, t.status[k] + gain)
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
            if k=="poison" then b.hp=b.hp-5 end
            if k=="burn" then b.hp=b.hp-8 end
            if k=="freeze" then startStun(b) end
            if k=="shock" then b.energy=0 end
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
