-- dungeon/base.lua: ダンジョン探索の暫定実装、マップ生成、敵配置、戦闘遷移、描画を管理する責務。
local battle = require("battle.battle")
local status = require("battle.status")
local enemies = require("data.enemy")
local fieldUi = require("ui.field_ui")
local town = require("town.town")

local M = {}

local TILE_SIZE = 18
local mapWidth = 42
local mapHeight = 28
local sightRange = 6
local encounterDistance = 1

local map = {}
local rooms = {}
local player = nil
local dungeonEnemies = {}
local mode = "dungeon"
local currentDistrict = "grass"
local entrancePosition = nil
local stairsPosition = nil
local currentFloor = 1

local aiTypes = {
    SEE_PLAYER = "see_player",
    NEAR_PLAYER = "near_player",
    PACK_HUNTER = "pack_hunter",
    PATROL_INNER = "patrol_inner"
}

local function createWalls()
    map = {}
    rooms = {}
    for y = 1, mapHeight do
        map[y] = {}
        for x = 1, mapWidth do
            map[y][x] = 1
        end
    end
end

local function inBounds(x, y)
    return x >= 1 and x <= mapWidth and y >= 1 and y <= mapHeight
end

local function isFloor(x, y)
    return inBounds(x, y) and map[y][x] == 0
end

local function createRoom(x, y, w, h)
    for yy = y, math.min(y + h, mapHeight - 1) do
        for xx = x, math.min(x + w, mapWidth - 1) do
            map[yy][xx] = 0
        end
    end
end

local function generateRooms()
    for _ = 1, 8 do
        local w = math.random(4, 8)
        local h = math.random(4, 8)
        local x = math.random(2, mapWidth - w - 1)
        local y = math.random(2, mapHeight - h - 1)
        createRoom(x, y, w, h)
        table.insert(rooms, {x = x, y = y, w = w, h = h})
    end
end

local function createCorridor(x1, y1, x2, y2)
    for x = math.min(x1, x2), math.max(x1, x2) do
        map[y1][x] = 0
    end
    for y = math.min(y1, y2), math.max(y1, y2) do
        map[y][x2] = 0
    end
end

local function connectRooms()
    for i = 2, #rooms do
        local r1 = rooms[i - 1]
        local r2 = rooms[i]
        local x1 = r1.x + math.floor(r1.w / 2)
        local y1 = r1.y + math.floor(r1.h / 2)
        local x2 = r2.x + math.floor(r2.w / 2)
        local y2 = r2.y + math.floor(r2.h / 2)
        createCorridor(x1, y1, x2, y2)
    end
end

local function generateMap()
    createWalls()
    generateRooms()
    connectRooms()
end

local function centerOf(room)
    return room.x + math.floor(room.w / 2), room.y + math.floor(room.h / 2)
end

local function distance(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

local function canSee(a, b, range)
    if distance(a, b) > range then return false end
    if a.x == b.x then
        for y = math.min(a.y, b.y) + 1, math.max(a.y, b.y) - 1 do
            if map[y][a.x] == 1 then return false end
        end
        return true
    end
    if a.y == b.y then
        for x = math.min(a.x, b.x) + 1, math.max(a.x, b.x) - 1 do
            if map[a.y][x] == 1 then return false end
        end
        return true
    end
    return distance(a, b) <= range
end

local function occupied(x, y, except)
    if player and player ~= except and player.x == x and player.y == y then return true end
    for _, e in ipairs(dungeonEnemies) do
        if e ~= except and e.alive and e.x == x and e.y == y then return true end
    end
    return false
end

local function tryMove(actor, dx, dy)
    local nx, ny = actor.x + dx, actor.y + dy
    if not isFloor(nx, ny) or occupied(nx, ny, actor) then return false end
    if actor ~= player and stairsPosition and stairsPosition.x == nx and stairsPosition.y == ny then return false end
    actor.x, actor.y = nx, ny
    return true
end

local function stepToward(actor, target)
    local choices = {}
    if target.x > actor.x then table.insert(choices, {1, 0}) end
    if target.x < actor.x then table.insert(choices, {-1, 0}) end
    if target.y > actor.y then table.insert(choices, {0, 1}) end
    if target.y < actor.y then table.insert(choices, {0, -1}) end
    for _, d in ipairs(choices) do
        if tryMove(actor, d[1], d[2]) then return true end
    end
    return false
end

local function patrolInner(actor)
    local dirs = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}}
    for i = 0, 3 do
        local d = dirs[((actor.patrolDir + i - 1) % 4) + 1]
        local nx, ny = actor.x + d[1], actor.y + d[2]
        local nearWall = not isFloor(nx + d[1] * 2, ny + d[2] * 2)
        if isFloor(nx, ny) and not occupied(nx, ny, actor) and not nearWall then
            actor.x, actor.y = nx, ny
            actor.patrolDir = ((actor.patrolDir + i - 1) % 4) + 1
            return
        end
    end
    actor.patrolDir = (actor.patrolDir % 4) + 1
end

local function seesOtherEnemy(actor)
    for _, other in ipairs(dungeonEnemies) do
        if other ~= actor and other.alive and canSee(actor, other, sightRange) then
            return true
        end
    end
    return false
end

local function updateEnemy(actor)
    if actor.aiType == aiTypes.SEE_PLAYER and canSee(actor, player, sightRange) then
        stepToward(actor, player)
    elseif actor.aiType == aiTypes.NEAR_PLAYER and distance(actor, player) <= 3 then
        stepToward(actor, player)
    elseif actor.aiType == aiTypes.PACK_HUNTER and ((canSee(actor, player, sightRange) and seesOtherEnemy(actor)) or distance(actor, player) <= 3) then
        stepToward(actor, player)
    elseif actor.aiType == aiTypes.PATROL_INNER then
        patrolInner(actor)
    end
end

local function startBattle(enemyActor)
    mode = "battle"
    battle.start(player.unit, enemyActor.unit, function(result)
        if result == "You Win" then
            enemyActor.alive = false
            mode = "dungeon"
        elseif result == "You Lose" then
            town.returnToTown(currentDistrict, player.unit, "defeat")
            mode = "town"
        end
    end)
end

local function placeStairs()
    local room = rooms[#rooms] or rooms[1]
    if not room then
        stairsPosition = nil
        return
    end

    local sx, sy = centerOf(room)
    stairsPosition = {x = sx, y = sy}
end

local function createDungeonEnemies()
    dungeonEnemies = {}
    local enemyAi = {aiTypes.SEE_PLAYER, aiTypes.NEAR_PLAYER, aiTypes.PACK_HUNTER, aiTypes.PATROL_INNER}
    for i = 1, 2 do
        local room = rooms[#rooms - i + 1] or rooms[1]
        local ex, ey = centerOf(room)
        if stairsPosition and ex == stairsPosition.x and ey == stairsPosition.y then
            local fallback = rooms[math.max(1, #rooms - i)] or rooms[1]
            ex, ey = centerOf(fallback)
        end
        local unit = battle.createUnit(enemies.enemy)
        unit.name = unit.name .. currentFloor .. "-" .. i
        table.insert(dungeonEnemies, {x = ex, y = ey, unit = unit, alive = true, aiType = enemyAi[math.random(#enemyAi)], patrolDir = i})
    end
end

local function descendStairs()
    currentFloor = currentFloor + 1
    generateMap()
    local px, py = centerOf(rooms[1])
    entrancePosition = {x = px, y = py}
    player.x, player.y = px, py
    player.district = currentDistrict
    placeStairs()
    createDungeonEnemies()
    fieldUi.close()
end

local function checkStairs()
    if stairsPosition and player.x == stairsPosition.x and player.y == stairsPosition.y then
        descendStairs()
        return true
    end
    return false
end

local function checkEncounter()
    for _, e in ipairs(dungeonEnemies) do
        if e.alive and distance(player, e) <= encounterDistance then
            startBattle(e)
            return true
        end
    end
    return false
end

function M.load()
    math.randomseed(os.time())
    currentFloor = 1
    generateMap()
    local px, py = centerOf(rooms[1])
    entrancePosition = {x = px, y = py}
    player = {x = px, y = py, district = currentDistrict, unit = battle.createUnit(enemies.hero)}
    status.clearStatusGauges(player.unit)
    placeStairs()
    createDungeonEnemies()
    fieldUi.configure({
        {label = "拠点へ戻る", execute = function()
            town.returnToTown(currentDistrict, player.unit)
            mode = "town"
        end},
        {label = "ダンジョン入口へ戻る", execute = function()
            M.returnToEntrance()
        end}
    })
    mode = "dungeon"
end

function M.update(dt)
    if mode == "town" then return end
    if mode == "battle" then
        battle.update(dt)
        return
    end
    checkEncounter()
end

function M.keypressed(key)
    if mode == "town" then
        if key == "return" or key == "kpenter" then
            M.returnToEntrance()
        end
        return
    end
    if mode ~= "dungeon" then return end
    if key == "escape" or key == "m" then
        fieldUi.toggle()
        return
    end
    if fieldUi.keypressed(key) then return end
    local moved = false
    if key == "up" or key == "w" then moved = tryMove(player, 0, -1) end
    if key == "down" or key == "s" then moved = tryMove(player, 0, 1) end
    if key == "left" or key == "a" then moved = tryMove(player, -1, 0) end
    if key == "right" or key == "d" then moved = tryMove(player, 1, 0) end
    if moved and not checkStairs() and not checkEncounter() then
        for _, e in ipairs(dungeonEnemies) do
            if e.alive then updateEnemy(e) end
        end
        checkEncounter()
    end
end

local function drawTile(x, y, color)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE, TILE_SIZE - 1, TILE_SIZE - 1)
end

function M.draw()
    if mode == "town" then
        town.draw()
        return
    end
    if mode == "battle" then
        battle.draw()
        return
    end

    for y = 1, mapHeight do
        for x = 1, mapWidth do
            if map[y][x] == 1 then
                drawTile(x, y, {0.15, 0.15, 0.18})
            else
                drawTile(x, y, {0.35, 0.35, 0.38})
            end
        end
    end

    if stairsPosition then drawTile(stairsPosition.x, stairsPosition.y, {0.1, 0.75, 0.25}) end
    for _, e in ipairs(dungeonEnemies) do
        if e.alive then drawTile(e.x, e.y, {0.8, 0.15, 0.15}) end
    end
    drawTile(player.x, player.y, {0.15, 0.45, 0.95})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Dungeon F" .. currentFloor .. ": arrow/WASD move, green stairs descends", 10, mapHeight * TILE_SIZE + 8)
    love.graphics.print("Sight range: " .. sightRange .. " tiles", 10, mapHeight * TILE_SIZE + 24)
    fieldUi.draw(player.unit)
end

function M.returnToEntrance()
    if player and entrancePosition then
        player.x = entrancePosition.x
        player.y = entrancePosition.y
        status.clearStatusGauges(player.unit)
    end
    fieldUi.close()
    mode = "dungeon"
end

M.aiTypes = aiTypes
M.generateMap = generateMap

return M
