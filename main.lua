-- main.lua: LÖVE2D のエントリーポイント。ゲーム全体の初期化・更新・入力・描画を現在のシーンへ橋渡しする責務。
local dungeon = require("dungeon.base")

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
