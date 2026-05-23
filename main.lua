
local battle = require("battle.battle")

function love.load()
    battle.load()
end

function love.update(dt)
    battle.update(dt)
end

function love.draw()
    battle.draw()
end
