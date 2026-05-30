

local M = {}

local STUN_DURATION_ENERGY = 90

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
    u.just_stunned = true
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
    if u.stun_energy >= STUN_DURATION_ENERGY then
        clearStun(u)
    end

    return true
end

return M
