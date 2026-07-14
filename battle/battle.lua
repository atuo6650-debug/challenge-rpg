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
local onBattleEnd = nil

local function addLog(text)
    table.insert(actionLogs, text)
    if #actionLogs > MAX_LOGS then
        table.remove(actionLogs, 1)
    end
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


local function equippedWeaponByType(unit, weaponType)
    if weaponType == "any" then return nil end

    for _, weapon in pairs({unit.w1, unit.w2}) do
        if weapon and weapon.type == weaponType then
            return weapon
        end
    end

    return nil
end

local function specialWeapon(unit, target)
    local gauge = unit.pending_special_gauge
    if gauge then
        local weapon = equippedWeaponByType(unit, gauge.weapon_type or "any")
        if weapon then return weapon end
    end

    if target.stunned and unit.w2 and unit.w2.condition == "wait_stunned" then
        return unit.w2
    end

    return unit.pending_weapon or unit.pattern[unit.patternIndex] or weapons.sword
end

local function canEquipWeapon(slot, weapon)
    if not weapon then return false end
    if weapon.second_only and slot ~= 2 then return false end
    return true
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

local function tryFinalAction(unit)
    if unit.final_action_used then return false end
    if unit.hp > 0 then return false end

    local gauge = status.readySpecialGauge(unit, function(g)
        return g.condition == "final_action"
    end)
    if not gauge then return false end

    unit.final_action_used = true
    status.consumeGauge(gauge, 100)
    unit.refreshGaugeTotals()
    unit.hp = math.max(1, math.floor(unit.maxhp * 0.1 + 0.5))
    unit.energy = actions.final_action.cost
    unit.action = nil
    unit.cost = 0
    unit.wait = actions.final_action.wait
    unit.action_started = false
    addLog(string.format("%s | final_action | %s | %d", unit.name, unit.name, unit.hp))
    return true
end

local function performAttack(attacker, target, actionName, weapon, multiplier)
    multiplier = multiplier or 1
    local dmg = damage.calc(attacker, target, weapon.damage_type) * weapon.power * multiplier
    applyDamage(attacker, target, actionName, dmg)
    status.onDamaged(target)
    status.onHit(attacker, target)
    resolveStunLogs(target)
    local counterAllowed = target.stun_changed_on_hit ~= "started"
    if counterAllowed then
        status.addCounterGauge(target)
    end
    target.stun_changed_on_hit = nil
    status.addSpecialGauge(attacker, 10)
    status.addSpecialGauge(target, 10)
    return counterAllowed
end

local function startCooldown(unit)
    unit.action_started = true
    unit.energy = 0

    if (unit.wait or 0) <= 0 then
        unit.action = nil
        unit.pending_weapon = nil
        unit.pending_special_gauge = nil
        unit.cost = 0
        unit.wait = 0
        unit.action_started = false
    end
end

local function performCounterAttack(attacker, target)
    local item = table.remove(attacker.counter_queue, 1)
    if not item then return false end

    performAttack(attacker, target, "counter_" .. item.weapon.type, item.weapon)
    attacker.action = "counter_wait"
    attacker.cost = actions.counter.cost
    attacker.wait = actions.counter.wait
    startCooldown(attacker)
    return true
end

local function startCounterSequence(unit, target)
    if unit.hp <= 0 then return end
    unit.counter_target = target
    if not unit.counter_gauges then return end

    local queued = 0
    for _, gauge in ipairs(unit.counter_gauges) do
        if gauge.value >= 100 then
            gauge.value = gauge.value - 100
            table.insert(unit.counter_queue, {weapon=gauge.weapon})
            queued = queued + 1
        end
    end
    unit.refreshGaugeTotals()

    if queued == 0 then return end

    if unit.action ~= "counter_wait" then
        unit.saved_action = {
            action=unit.action,
            pending_weapon=unit.pending_weapon,
            pending_special_gauge=unit.pending_special_gauge,
            cost=unit.cost,
            wait=unit.wait,
            energy=unit.energy,
            action_started=unit.action_started
        }
        performCounterAttack(unit, target)
    end
end

local function finishCounterIfReady(unit)
    if unit.action ~= "counter_wait" then return false end

    unit.energy = unit.energy + 10
    if unit.energy < unit.wait then
        return true
    end

    if #unit.counter_queue > 0 then
        performCounterAttack(unit, unit.counter_target)
        return true
    end

    local saved = unit.saved_action or {}
    unit.action = saved.action
    unit.pending_weapon = saved.pending_weapon
    unit.pending_special_gauge = saved.pending_special_gauge
    unit.cost = saved.cost or 0
    unit.wait = saved.wait or 0
    unit.energy = saved.energy or 0
    unit.action_started = saved.action_started
    unit.saved_action = nil
    unit.counter_target = nil
    return true
end

local function addWeaponPattern(pattern, weapon)
    if not weapon then return end

    local repeatCount = weapon.repeat_count
    if repeatCount == nil then repeatCount = 1 end
    weapon.pattern_repeat_count = repeatCount

    for _ = 1, repeatCount do
        table.insert(pattern, weapon)
    end
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
    u.wait=0
    u.action_started=false

    u.special=0
    u.special_condition=data.special_condition

    status.initStatuses(u)

    -- 装備
    local w1 = weapons[data.w1]
    local w2 = weapons[data.w2]
    u.w1 = canEquipWeapon(1, w1) and w1 or nil
    u.w2 = canEquipWeapon(2, w2) and w2 or nil
    u.a1=armors[data.a1]
    u.a2=armors[data.a2]
    u.acc1=accs[data.acc1]
    u.acc2=accs[data.acc2]

    -- パターン
    u.pattern={}
    addWeaponPattern(u.pattern, u.w1)
    addWeaponPattern(u.pattern, u.w2)

    if #u.pattern==0 then addWeaponPattern(u.pattern,weapons.sword) end
    u.patternIndex=1

    -- アクセ適用
    for _,acc in pairs({u.acc1,u.acc2}) do
        if acc then
            if acc.resist and u.resist[acc.resist.type] ~= nil then
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

    function u.refreshGaugeTotals()
        status.refreshGaugeTotals(u)
    end

    function u.consumeSpecial(amount)
        status.consumeSpecial(u, amount)
    end

    function u.reduceSpecial(amount)
        status.reduceSpecial(u, amount)
    end

    function u.reduceCounter(amount)
        status.reduceCounter(u, amount)
    end

    u.refreshGaugeTotals()

    return u
end

M.createUnit = createUnit

function execute(a,b)

    if a.action=="weapon" then
        local counterAllowed = performAttack(a, b, a.pending_weapon.type, a.pending_weapon)
        if counterAllowed then
            startCounterSequence(b, a)
        end
        startCooldown(a)
        return
    end

    if a.action=="special" then
        local weapon = specialWeapon(a, b)
        local dmg=damage.calc(a,b,weapon.damage_type)*2
        applyDamage(a, b, "special", dmg)
        status.onDamaged(b)
        resolveStunLogs(b)
        if b.stun_changed_on_hit ~= "started" then
            status.addCounterGauge(b)
        end
        b.stun_changed_on_hit = nil
        startCounterSequence(b, a)
        startCooldown(a)
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

    if not a.action_started then
        a.energy = a.energy + 10
        if a.energy >= a.cost then
            execute(a,b)
        end
        return
    end

    a.energy = a.energy + 10

    if a.energy >= a.wait then
        a.energy=0
        a.action=nil
        a.pending_weapon=nil
        a.pending_special_gauge=nil
        a.cost=0
        a.wait=0
        a.action_started=false
    end
end

function M.load()
    hero=createUnit(enemies.hero)
    enemy=createUnit(enemies.enemy)
    actionLogs = {}
    battleEnded = false
    battleResult = nil
    onBattleEnd = nil
end

function M.start(playerUnit, enemyUnit, callback)
    hero = playerUnit or createUnit(enemies.hero)
    enemy = enemyUnit or createUnit(enemies.enemy)
    actionLogs = {}
    battleEnded = false
    battleResult = nil
    onBattleEnd = callback
end

local function finishBattle(result)
    battleEnded = true
    battleResult = result
    status.clearBattleGauges(hero)
    status.clearBattleGauges(enemy)
    if onBattleEnd then
        onBattleEnd(result)
    end
end

function M.update(dt)
    if battleEnded then return end
    updateUnit(hero,enemy)
    tryFinalAction(hero)
    tryFinalAction(enemy)
    if enemy.hp <= 0 then
        finishBattle("You Win")
        return
    end
    if hero.hp <= 0 then
        finishBattle("You Lose")
        return
    end

    updateUnit(enemy,hero)
    tryFinalAction(hero)
    tryFinalAction(enemy)
    if hero.hp <= 0 then
        finishBattle("You Lose")
        return
    end
    if enemy.hp <= 0 then
        finishBattle("You Win")
    end
end

function drawGauge(x,y,v)
    love.graphics.rectangle("line",x,y,100,8)
    love.graphics.rectangle("fill",x,y,math.min(100, v),8)
end

function drawUnit(u,x,y)
    love.graphics.print(u.name.." "..math.floor(u.hp),x,y)

    local i=0
    for _, k in ipairs(status.statusNames()) do
        local v = u.status[k] or 0
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
