GameStateManager = require("libs/gamestateManager")
local MainMenu = require("states/mainMenu")
local inGame = require("states/inGame")

function love.load()
    GameStateManager:setState(inGame)
end

function love.update(dt)   
    GameStateManager:update(dt)
end

function love.draw()
    GameStateManager:draw()
end