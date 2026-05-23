

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
    u.counter_stack=0
    u.counter_rate=data.counter_rate or 0.5

    return u
end

function counterCheck(a,b)
    if a.counter_stack >= 10 then
        if love.math.random() < a.counter_rate then
            local dmg = damage.calc(a,b)
            b.hp = b.hp - dmg
            a.counter_stack = 0
        end
    end
end

function execute(a,b)

    if a.stunned then
        a.stunned=false
        a.energy=0
        a.action=nil
        return
    end

    if a.action=="attack" then
        local dmg=damage.calc(a,b)
        b.hp=b.hp-dmg
        status.onHit(a,b)
        a.special=a.special+10
        b.special=b.special+10
    end

    if a.action=="quick" then
        local dmg=damage.calc(a,b)*0.5
        b.hp=b.hp-dmg
        status.onHit(a,b)
        a.special=a.special+10
        b.special=b.special+10
    end

    if a.action=="special" then
        local dmg=damage.calc(a,b)*2
        b.hp=b.hp-dmg
    end

    -- カウンター加算
    b.counter_stack = b.counter_stack + 1
    counterCheck(b,a)

    a.energy=0
    a.action=nil
end

function updateUnit(a,b)

    ai.decide(a,b)

    a.energy = a.energy + 10

    if a.energy >= a.cost then
        execute(a,b)
    end
end

function M.load()
    hero=createUnit(enemies.hero)
    enemy=createUnit(enemies.enemy)
end

function M.update(dt)
    updateUnit(hero,enemy)
    updateUnit(enemy,hero)
end

function drawGauge(x,y,v)
    love.graphics.rectangle("line",x,y,100,8)
    love.graphics.rectangle("fill",x,y,v,8)
end

function drawUnit(u,x,y)
    love.graphics.print(u.name.." "..u.hp,x,y)

    local i=0
    for k,v in pairs(u.status) do
        love.graphics.print(k,x,y+20+i*12)
        drawGauge(x+60,y+20+i*12,v)
        i=i+1
    end

    love.graphics.print("SP "..u.special,x,y+100)
end

function M.draw()

    drawUnit(hero,40,40)
    drawUnit(enemy,220,40)

    if hero.hp<=0 then
        love.graphics.print("Enemy Wins",120,200)
    elseif enemy.hp<=0 then
        love.graphics.print("Hero Wins",120,200)
    end
end

return M
