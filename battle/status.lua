

local M = {}

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

            if k=="stun" then b.stunned=true b.just_stunned=true end
            if k=="poison" then b.hp=b.hp-5 end
            if k=="burn" then b.hp=b.hp-8 end
            if k=="freeze" then b.stunned=true b.just_stunned=true end
            if k=="shock" then b.energy=0 end
        end
    end
end

function M.onDamaged(u)
    if u.stunned then
        u.stunned = false
        u.just_recovered = true
    end
end

return M
