
local damage = require("battle.damage")
local status = require("battle.status")
local ai = require("battle.ai")

local actions = require("data.action")
local weapons = require("data.weapon")
local armors = require("data.armor")
local accs = require("data.accessory")
local enemies = require("data.enemy")

local M = {}

local hero, enemy
local actionLogs = {}
local MAX_LOGS = 12
local battleEnded = false
local battleResult = nil

local function addLog(text)
    table.insert(actionLogs, text)
    if #actionLogs > MAX_LOGS then
        table.remove(actionLogs, 1)
    end
end

local function refreshGaugeTotals(unit)
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

local function random()
    if love and love.math and love.math.random then
        return love.math.random()
    end
    return math.random()
end

local function weaponTypeEquipped(unit, weaponType)
    if weaponType == "any" then return true end

    for _, weapon in pairs({unit.w1, unit.w2}) do
        if weapon and weapon.type == weaponType then
            return true
        end
    end

    return false
end

local function applyDamage(attacker, target, actionName, rawDamage)
    local dmg = math.max(1, math.floor(rawDamage + 0.5))
    target.hp = math.floor(target.hp - dmg)
    addLog(string.format("%s | %s | %s | %d", attacker.name, actionName, target.name, dmg))
    return dmg
end

local function resolveStunLogs(unit)
    if unit.just_stunned then
        addLog(string.format("%s | stun_start | %s | 0", unit.name, unit.name))
        unit.just_stunned = false
    end
    if unit.just_recovered then
        addLog(string.format("%s | stun_cleared | %s | 0", unit.name, unit.name))
        unit.just_recovered = false
    end
end

local function readySpecialGauge(unit, condition)
    for _, gauge in ipairs(unit.special_gauges or {}) do
        if gauge.value >= 100 and (not condition or gauge.condition == condition) then
            return gauge
        end
    end

    return nil
end

local function tryFinalAction(unit)
    if unit.final_action_used then return false end
    if not readySpecialGauge(unit, "final_action") then return false end
    if unit.hp > 0 then return false end

    unit.final_action_used = true
    unit.consumeSpecial(100)
    unit.hp = math.max(1, math.floor(unit.maxhp * 0.1 + 0.5))
    unit.energy = actions.final_action.cost
    unit.action = nil
    unit.cost = 0
    unit.action_started = false
    addLog(string.format("%s | final_action | %s | %d", unit.name, unit.name, unit.hp))
    return true
end

local function addSpecialGauge(unit, gain)
    for _, gauge in ipairs(unit.special_gauges or {}) do
        gauge.value = math.min(100, gauge.value + gain)
    end
    refreshGaugeTotals(unit)
end

local function addCounterGauge(unit)
    for _, gauge in ipairs(unit.counter_gauges or {}) do
        local gain = gauge.gain or 10
        gauge.value = math.min(100, gauge.value + gain)
    end
    refreshGaugeTotals(unit)
end

local function performAttack(attacker, target, actionName, weapon, multiplier)
    multiplier = multiplier or 1
    local dmg = damage.calc(attacker, target, weapon.damage_type) * weapon.power * multiplier
    applyDamage(attacker, target, actionName, dmg)
    status.onDamaged(target)
    status.onHit(attacker, target)
    resolveStunLogs(target)
    addCounterGauge(target)
    addSpecialGauge(attacker, 10)
    addSpecialGauge(target, 10)
end

local function performCounterAttack(attacker, target)
    local item = table.remove(attacker.counter_queue, 1)
    if not item then return false end

    performAttack(attacker, target, "counter_" .. item.weapon.type, item.weapon)
    attacker.action = "counter_wait"
    attacker.cost = actions.counter.cost
    attacker.energy = 0
    attacker.action_started = true
    return true
end

local function startCounterSequence(unit, target)
    if unit.hp <= 0 then return end
    unit.counter_target = target
    if not unit.counter_gauges then return end

    local queued = 0
    for _, gauge in ipairs(unit.counter_gauges) do
        if gauge.value >= 100 and random() < unit.counter_rate then
            gauge.value = gauge.value - 100
            table.insert(unit.counter_queue, {weapon=gauge.weapon})
            queued = queued + 1
        end
    end
    refreshGaugeTotals(unit)

    if queued == 0 then return end

    if unit.action ~= "counter_wait" then
        unit.saved_action = {
            action=unit.action,
            pending_weapon=unit.pending_weapon,
            cost=unit.cost,
            energy=unit.energy,
            action_started=unit.action_started
        }
    end

    if unit.action ~= "counter_wait" then
        performCounterAttack(unit, target)
    end
end

local function finishCounterIfReady(unit)
    if unit.action ~= "counter_wait" then return false end

    unit.energy = unit.energy + 10
    if unit.energy < unit.cost then
        return true
    end

    if #unit.counter_queue > 0 then
        performCounterAttack(unit, unit.counter_target)
        return true
    end

    local saved = unit.saved_action or {}
    unit.action = saved.action
    unit.pending_weapon = saved.pending_weapon
    unit.cost = saved.cost or 0
    unit.energy = saved.energy or 0
    unit.action_started = saved.action_started
    unit.saved_action = nil
    unit.counter_target = nil
    return true
end

function createUnit(data)

    local u = {}

    u.name=data.name
    u.hp=data.hp
    u.maxhp=data.hp
    u.atk=data.atk
    u.def=data.def

    u.energy=0
    u.action=nil
    u.cost=0
    u.action_started=false

    u.special=0
    u.special_condition=data.special_condition

    u.status={stun=0,blind=0,silence=0,curse=0,paralysis=0,poison=0,burn=0,freeze=0,shock=0}
    u.resist={stun=0,blind=0,silence=0,curse=0,paralysis=0,poison=0,burn=0,freeze=0,shock=0}

    u.stunned=false
    u.stun_energy=0
    u.blinded=false
    u.blind_energy=0
    u.silenced=false
    u.silence_energy=0
    u.final_action_used=false

    -- 装備
    u.w1=weapons[data.w1]
    u.w2=weapons[data.w2]
    u.a1=armors[data.a1]
    u.a2=armors[data.a2]
    u.acc1=accs[data.acc1]
    u.acc2=accs[data.acc2]

    -- パターン
    u.pattern={}
    if u.w1 then table.insert(u.pattern, u.w1) end
    if u.w2 then table.insert(u.pattern, u.w2) end

    if #u.pattern==0 then table.insert(u.pattern,weapons.sword) end
    u.patternIndex=1

    -- アクセ適用
    for _,acc in pairs({u.acc1,u.acc2}) do
        if acc then
            if acc.resist then
                u.resist[acc.resist.type] = acc.resist.value
            end
            if acc.inflict then
                u.inflict = acc.inflict
            end
            if acc.special then
                u.special_condition = acc.special.condition
            end
        end
    end

    -- カウンターゲージ（防具に応じて0〜2本）
    u.counter_gauges={}
    for _, armor in pairs({u.a1,u.a2}) do
        if armor and armor.counter_type and weaponTypeEquipped(u, armor.counter_type) then
            table.insert(u.counter_gauges, {
                value=0,
                gain=armor.counter_gain or 10,
                weapon=weapons[armor.counter_type]
            })
        end
    end
    u.counter_queue={}
    u.counter_rate=data.counter_rate or 0.5

    -- 特殊ゲージ（アクセサリーに応じて0〜2本）
    u.special_gauges={}
    for _, acc in pairs({u.acc1,u.acc2}) do
        if acc and acc.special then
            local weaponType = acc.special.weapon_type or "any"
            if weaponTypeEquipped(u, weaponType) then
                table.insert(u.special_gauges, {
                    value=0,
                    condition=acc.special.condition or u.special_condition,
                    weapon_type=weaponType
                })
            end
        end
    end

    function u.consumeSpecial(amount)
        reduceGauge(u.special_gauges, amount)
        refreshGaugeTotals(u)
    end

    function u.reduceSpecial(amount)
        reduceGauge(u.special_gauges, amount)
        refreshGaugeTotals(u)
    end

    function u.reduceCounter(amount)
        reduceGauge(u.counter_gauges, amount)
        refreshGaugeTotals(u)
    end

    refreshGaugeTotals(u)

    return u
end

function execute(a,b)

    if a.action=="weapon" then
        performAttack(a, b, a.pending_weapon.type, a.pending_weapon)
        startCounterSequence(b, a)
        a.action_started = true
        a.energy = 0
        return
    end

    if a.action=="special" then
        local weapon = a.pending_weapon or a.pattern[a.patternIndex] or weapons.sword
        local dmg=damage.calc(a,b,weapon.damage_type)*2
        applyDamage(a, b, "special", dmg)
        status.onDamaged(b)
        resolveStunLogs(b)
        addCounterGauge(b)
        startCounterSequence(b, a)
        a.energy=0
        a.action=nil
        a.action_started=false
        return
    end
end

function updateUnit(a,b)

    a.counter_target = a.counter_target or b
    if finishCounterIfReady(a) then
        resolveStunLogs(a)
        return
    end

    status.updateTimed(a, 10)

    if status.updateStun(a, 10) then
        resolveStunLogs(a)
        return
    end

    ai.decide(a,b)
    if not a.action then return end

    if a.action == "weapon" and not a.action_started then
        execute(a,b)
        return
    end

    if a.action == "special" then
        execute(a,b)
        return
    end

    a.energy = a.energy + 10

    if a.energy >= a.cost then
        a.energy=0
        a.action=nil
        a.pending_weapon=nil
        a.action_started=false
    end
end

function M.load()
    hero=createUnit(enemies.hero)
    enemy=createUnit(enemies.enemy)
    actionLogs = {}
    battleEnded = false
    battleResult = nil
end

function M.update(dt)
    if battleEnded then return end
    updateUnit(hero,enemy)
    tryFinalAction(hero)
    tryFinalAction(enemy)
    if enemy.hp <= 0 then
        battleEnded = true
        battleResult = "You Win"
        return
    end
    if hero.hp <= 0 then
        battleEnded = true
        battleResult = "You Lose"
        return
    end

    updateUnit(enemy,hero)
    tryFinalAction(hero)
    tryFinalAction(enemy)
    if hero.hp <= 0 then
        battleEnded = true
        battleResult = "You Lose"
        return
    end
    if enemy.hp <= 0 then
        battleEnded = true
        battleResult = "You Win"
    end
end

function drawGauge(x,y,v)
    love.graphics.rectangle("line",x,y,100,8)
    love.graphics.rectangle("fill",x,y,math.min(100, v),8)
end

function drawUnit(u,x,y)
    love.graphics.print(u.name.." "..math.floor(u.hp),x,y)

    local i=0
    for k,v in pairs(u.status) do
        love.graphics.print(k,x,y+20+i*12)
        drawGauge(x+60,y+20+i*12,v)
        i=i+1
    end

    love.graphics.print("SP "..u.special,x,y+140)
    love.graphics.print("CT "..u.counter_gauge,x,y+155)
end

function M.draw()

    drawUnit(hero,40,40)
    drawUnit(enemy,220,40)

    if battleResult then
        love.graphics.print(battleResult,120,200)
    end

    love.graphics.print("Action Log",20,240)
    for i, log in ipairs(actionLogs) do
        love.graphics.print(log,20,240 + i * 14)
    end
end

return M
