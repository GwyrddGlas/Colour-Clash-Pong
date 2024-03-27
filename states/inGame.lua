local inGame = {}

local player1
local player2
local gameBall

function inGame:newPlayer(x, y, width, height, id)
    return {
        x = x,
        y = y,
        width = width,
        height = height,
        id = id,
        score = 0,
        color = id == "Player 1" and {1, 0, 0} or {0, 0, 1}  -- Red for Player 1, Blue for Player 2
    }
end

local radialGradientShader = love.graphics.newShader[[
    extern number innerRadius;
    extern number outerRadius;
    extern vec2 center;
    extern vec4 colorInner;
    extern vec4 colorOuter;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
    {
        number dist = distance(screen_coords, center);
        number t = smoothstep(innerRadius, outerRadius, dist);
        return mix(colorInner, colorOuter, t) * Texel(texture, texture_coords);
    }
]]


function inGame:enter()
    player1 = self:newPlayer(50, love.graphics.getHeight() / 2 - 25, 20, 70, "Player 1")
    player2 = self:newPlayer(love.graphics.getWidth() - 70, love.graphics.getHeight() / 2 - 25, 20, 70, "Player 2")
    gameBall = {
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() / 2,
        size = 10,
        dx = 200,  
        dy = 120
    }

    local scoreFontSize = 30
    self.scoreFont = love.graphics.newFont(scoreFontSize)
    love.graphics.setFont(self.scoreFont)

    math.randomseed(os.time())

    local vertices1 = {
        {player1.x, player1.y, 0, 0, 1, 0, 0, 1},  -- Top left corner, color: red
        {player1.x + player1.width, player1.y, 0, 0, 1, 0.5, 0.5, 1},  -- Top right corner, color: pink
        {player1.x + player1.width, player1.y + player1.height, 0, 0, 1, 0.2, 0.2, 1},  -- Bottom right corner, color: dark pink
        {player1.x, player1.y + player1.height, 0, 0, 0.8, 0, 0, 1}  -- Bottom left corner, color: dark red
    }
    player1.mesh = love.graphics.newMesh(vertices1, "fan", "static")
    
    local vertices2 = {
        {player2.x, player2.y, 0, 0, 0, 0, 1, 1},  -- Top left corner, color: blue
        {player2.x + player2.width, player2.y, 0, 0, 0.5, 0.5, 1, 1},  -- Top right corner, color: light blue
        {player2.x + player2.width, player2.y + player2.height, 0, 0, 0.2, 0.2, 1, 1},  -- Bottom right corner, color: dark light blue
        {player2.x, player2.y + player2.height, 0, 0, 0, 0, 0.8, 1}  -- Bottom left corner, color: dark blue
    }
    player2.mesh = love.graphics.newMesh(vertices2, "fan", "static")

    radialGradientShader:send("innerRadius", love.graphics.getWidth() / 10)  -- Start transition from this radius
    radialGradientShader:send("outerRadius", love.graphics.getWidth())  -- End transition at this radius
    radialGradientShader:send("center", {love.graphics.getWidth() / 2, love.graphics.getHeight() / 2})
    radialGradientShader:send("colorInner", {0.109803922, 0.109803922, 0.109803922, 1})  -- White center
    radialGradientShader:send("colorOuter", {0, 0, 0, 1})  -- Fades to black
end

local function updateBall(dt)
    gameBall.x = gameBall.x + gameBall.dx * dt
    gameBall.y = gameBall.y + gameBall.dy * dt

    if gameBall.y <= 0 then 
        gameBall.y = 0  
        gameBall.dy = -gameBall.dy 
    elseif gameBall.y >= love.graphics.getHeight() - gameBall.size then  
        gameBall.y = love.graphics.getHeight() - gameBall.size  
        gameBall.dy = -gameBall.dy 
    end

    if gameBall.x <= 0 then  
        gameBall.x = love.graphics.getWidth() / 2
        gameBall.y = love.graphics.getHeight() / 2
        gameBall.dx = -gameBall.dx

        player2.score = player2.score + 1
    elseif gameBall.x >= love.graphics.getWidth() - gameBall.size then 
        gameBall.x = love.graphics.getWidth() / 2
        gameBall.y = love.graphics.getHeight() / 2
        gameBall.dx = -gameBall.dx
        
        player1.score = player1.score + 1
    end
end

local function updatePaddleMesh(paddle, colorTop, colorBottom)
    local vertices = {
        {paddle.x, paddle.y, 0, 0, unpack(colorTop)},  
        {paddle.x + paddle.width, paddle.y, 0, 0, unpack(colorTop)}, 
        {paddle.x + paddle.width, paddle.y + paddle.height, 0, 0, unpack(colorBottom)}, 
        {paddle.x, paddle.y + paddle.height, 0, 0, unpack(colorBottom)}  
    }
    paddle.mesh:setVertices(vertices)
end

local function checkCollision(ball, paddle)
    if ball.x + ball.size < paddle.x or ball.x > paddle.x + paddle.width then
        return false
    end

    if ball.y + ball.size < paddle.y or ball.y > paddle.y + paddle.height then
        return false
    end

    return true
end

local moveProbability = 0.9

local function updateAI(dt)
    local paddleSpeed = 200 
    local reactionDelay = 0.1  
    local errorMargin = 10 

    if math.random() < moveProbability then
        if gameBall.y < player2.y + player2.height / 2 and player2.y > 0 then
            player2.y = player2.y - paddleSpeed * dt
        elseif gameBall.y > player2.y + player2.height / 2 and player2.y < love.graphics.getHeight() - player2.height then
            player2.y = player2.y + paddleSpeed * dt
        end
    end
end

function inGame:update(dt)
    if love.keyboard.isDown('w') then
        player1.y = player1.y - 300 * dt  
    end
    if love.keyboard.isDown('s') then
        player1.y = player1.y + 300 * dt  
    end

    if love.keyboard.isDown('up') then
        player2.y = player2.y - 300 * dt  
    end
    if love.keyboard.isDown('down') then
        player2.y = player2.y + 300 * dt  
    end

    player1.y = math.max(0, math.min(player1.y, love.graphics.getHeight() - player1.height))
    player2.y = math.max(0, math.min(player2.y, love.graphics.getHeight() - player2.height))
    
    -- Update ball position
    updateBall(dt)
    updatePaddleMesh(player1, {1, 0, 0, 1}, {1, 0.5, 0.5, 1})  -- From red to light red for Player 1
    updatePaddleMesh(player2, {0, 0, 1, 1}, {0.5, 0.5, 1, 1})  -- From blue to light blue for Player 2

    -- Update AI
    updateAI(dt)

    if checkCollision(gameBall, player1) or checkCollision(gameBall, player2) then
        gameBall.dx = -gameBall.dx         
        gameBall.dy = gameBall.dy + math.random(-10, 10)
    end
end

function inGame:draw()
    love.graphics.setShader(radialGradientShader)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()

    love.graphics.draw(player1.mesh)
    love.graphics.draw(player2.mesh)

    -- Draw the game ball
    love.graphics.setColor(0.75, 0.75, 0.75) 
    love.graphics.circle('fill', gameBall.x, gameBall.y, gameBall.size)

    love.graphics.setColor(1, 1, 1)

    -- Draw the dashed center line
    local dashHeight = 10
    local dashSpace = 15
    local centerY = love.graphics.getWidth() / 2 

    for y = 0, love.graphics.getHeight(), dashHeight + dashSpace do
        love.graphics.rectangle('fill', centerY - 1, y, 2, dashHeight)
    end

    local scoreText1 = tostring(player1.score)
    local scoreText2 = tostring(player2.score)
    local scoreWidth1 = self.scoreFont:getWidth(scoreText1)
    local scoreWidth2 = self.scoreFont:getWidth(scoreText2)

    local scoreOffsetX = 50  
    local scorePosY = 10  

    love.graphics.print(scoreText1, centerY - scoreOffsetX - scoreWidth1, scorePosY)
    love.graphics.print(scoreText2, centerY + scoreOffsetX, scorePosY)
end

return inGame