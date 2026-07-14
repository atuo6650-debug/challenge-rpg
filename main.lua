local dungeon = require("dungeon")

function love.load()
    dungeon.load()
end

function love.update(dt)
    dungeon.update(dt)
end

function love.keypressed(key)
    dungeon.keypressed(key)
end

function love.draw()
    dungeon.draw()
end
