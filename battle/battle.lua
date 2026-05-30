

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
    if unit.special_condition ~= "final_action" then return false end
    if unit.final_action_used then return false end
    if unit.special < 100 then return false end
    if unit.hp > 0 then return false end

    unit.final_action_used = true
    unit.special = 0
    unit.hp = math.max(1, math.floor(unit.maxhp * 0.1 + 0.5))
    unit.energy = actions.final_action.cost
    unit.action = nil
    unit.cost = 0
    addLog(string.format("%s | final_action | %s | %d", unit.name, unit.name, unit.hp))
    return true
end


local function addCounterGauge(unit)
    local gain = 10
    local armors = {unit.a1, unit.a2}
    for _, armor in ipairs(armors) do
        if armor and armor.counter_gain then
            gain = math.max(gain, armor.counter_gain)
        end
    end

    unit.counter_gauge = unit.counter_gauge + gain
    if unit.counter_gauge >= 100 then
        unit.counter_ready = true
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

    u.special=0
    u.special_condition=data.special_condition

    u.status={stun=0,poison=0,burn=0,freeze=0,shock=0}
    u.resist={stun=0,poison=0,burn=0,freeze=0,shock=0}

    u.stunned=false
    u.stun_energy=0
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
    for _,w in ipairs({u.w1,u.w2}) do
        if w then
            for i=1,w.repeat_count do
                table.insert(u.pattern, w.action)
            end
        end
    end

    if #u.pattern==0 then table.insert(u.pattern,"attack") end
    u.patternIndex=1

    -- アクセ適用
    for _,acc in ipairs({u.acc1,u.acc2}) do
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

    -- カウンター
    u.counter_gauge=0
    u.counter_ready=false
    u.counter_rate=data.counter_rate or 0.5

    return u
end

function counterCheck(a,b)
    if a.hp > 0 and a.counter_ready and a.counter_gauge >= 100 and love.math.random() < a.counter_rate then
        local dmg = damage.calc(a,b)
        applyDamage(a, b, "counter", dmg)
        a.counter_gauge = a.counter_gauge - 100
        a.counter_ready = a.counter_gauge >= 100
        status.onDamaged(b)
        resolveStunLogs(b)
    end
end

function execute(a,b)

    if a.action=="attack" then
        local dmg=damage.calc(a,b)
        applyDamage(a, b, "attack", dmg)
        status.onDamaged(b)
        status.onHit(a,b)
        resolveStunLogs(b)
        addCounterGauge(b)
        a.special=a.special+10
        b.special=b.special+10
    end

    if a.action=="quick" then
        local dmg=damage.calc(a,b)*0.5
        applyDamage(a, b, "quick", dmg)
        status.onDamaged(b)
        status.onHit(a,b)
        resolveStunLogs(b)
        addCounterGauge(b)
        a.special=a.special+10
        b.special=b.special+10
    end

    if a.action=="special" then
        local dmg=damage.calc(a,b)*2
        applyDamage(a, b, "special", dmg)
        status.onDamaged(b)
        resolveStunLogs(b)
        addCounterGauge(b)
    end
    counterCheck(b,a)

    a.energy=0
    a.action=nil
end

function updateUnit(a,b)

    if status.updateStun(a, 10) then
        resolveStunLogs(a)
        return
    end

    ai.decide(a,b)
    if not a.action then return end

    a.energy = a.energy + 10

    if a.energy >= a.cost then
        execute(a,b)
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
    love.graphics.rectangle("fill",x,y,v,8)
end

function drawUnit(u,x,y)
    love.graphics.print(u.name.." "..math.floor(u.hp),x,y)

    local i=0
    for k,v in pairs(u.status) do
        love.graphics.print(k,x,y+20+i*12)
        drawGauge(x+60,y+20+i*12,v)
        i=i+1
    end

    love.graphics.print("SP "..u.special,x,y+100)
    love.graphics.print("CT "..u.counter_gauge,x,y+115)
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
