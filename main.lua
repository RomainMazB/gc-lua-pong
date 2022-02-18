local padWidth = 10
local initialBallSize = 10

local minBallSpeed = 50
local maxBallSpeed = 350
local minPadSpeed = 50
local maxPadSpeed = 350
local minPadHeight = 20
local maxPadHeight = 200
local minBallSpeedIncrease = 5
local maxBallSpeedIncrease = 20

local initialPadHeight = 50
local initialPadSpeed = 100
local initialBallSpeed = 100
local ballSpeedIncrease = 8

local screenSize = {
    width = love.graphics.getWidth(),
    height = love.graphics.getHeight(),
    centerX = love.graphics.getWidth() / 2,
    centerY = love.graphics.getHeight() / 2
}

local pad1 = {
    x = 0,
    y = 0,
    speed = initialPadSpeed,
    height = initialPadHeight
}

local pad2 = {
    x = screenSize.width - padWidth,
    y = 0,
    speed = initialPadSpeed,
    height = initialPadHeight
}

local ball = {
    x = screenSize.centerX - initialBallSize / 2,
    y = screenSize.centerY - initialBallSize / 2,
    size = initialBallSize,
    speedLeft = initialBallSpeed,
    speedRight = initialBallSpeed,
    vx = 0,
    vy = 0
}

local gameState = {
    gameIsRunning = false,
    gameIsPaused  = false,
    scores = {
        player1 = 0,
        player2 = 0
    },
    spawnedBoosts = {},
    player1ActivatedBoosts = {},
    player2ActivatedBoosts = {},
    options = {
        horizontalCollisions = true
    }
}

function love.load()
    math.randomseed(os.time())
    local midScreenWidth = screenSize.height / 2
    pad1.y = midScreenWidth - initialPadHeight
    pad2.y = midScreenWidth - initialPadHeight
end

function love.update(dt)
    if gameState.gameIsRunning and not gameState.gameIsPaused then
        HandlePlayer1Keyboard(dt)
        HandlePlayer2Keyboard(dt)
        DetectCollisions()

        ball.x = ball.x + ball.vx * dt
        ball.y = ball.y + ball.vy * dt
    end
end

function love.draw()
    love.graphics.rectangle("fill", pad1.x, pad1.y, padWidth, pad1.height)
    love.graphics.rectangle("fill", pad2.x, pad2.y, padWidth, pad2.height)
    love.graphics.rectangle("fill", ball.x, ball.y, ball.size, ball.size)

    -- Display scores only when the game is running
    if gameState.gameIsRunning then
        love.graphics.print(GenerateScoreString(), screenSize.centerX, 10)
    end

    if not gameState.gameIsRunning then
        love.graphics.print("Press 'space' to run the game")

        love.graphics.print("Settings: ", screenSize.centerX, 10)
        love.graphics.print("Initial ball speed: "..initialBallSpeed, screenSize.centerX, 25)
        love.graphics.print("Ball speed increase on pads collision: "..ballSpeedIncrease, screenSize.centerX, 40)
        love.graphics.print("Initial pads size: "..initialPadHeight, screenSize.centerX, 55)
        love.graphics.print("Initial pads speed: "..initialPadSpeed, screenSize.centerX, 70)
    elseif gameState.gameIsPaused then
        love.graphics.print("Game is paused, press 'space' to continue")
    end
end

function HandlePlayer1Keyboard(dt)
    if love.keyboard.isDown("z") then
        if pad1.y > 0 then
            pad1.y = pad1.y - pad1.speed * dt
        end
    elseif love.keyboard.isDown("s") then
        if pad1.y < screenSize.height - pad1.height then
            pad1.y = pad1.y + pad1.speed * dt
        end
    end
end

function HandlePlayer2Keyboard(dt)
    if love.keyboard.isDown("up") then
        if pad2.y > 0 then
            pad2.y = pad2.y - pad2.speed * dt
        end
    elseif love.keyboard.isDown("down") then
        if pad2.y < screenSize.height - pad2.height then
            pad2.y = pad2.y + pad2.speed * dt
        end
    end
end

function DetectCollisions()
    -- Ball collisions on screen top and bottom
    if ball.y < 0 or ball.y + ball.size > screenSize.height then
        if gameState.options.horizontalCollisions then
            ball.vy = - ball.vy
        end
    end

    -- Ball collisions on screen left and right
    if ball.x < 0 then
        gameState.gameIsPaused = true
        gameState.scores.player2 = gameState.scores.player2 + 1
        ResetGame()
    elseif ball.x + ball.size > screenSize.width then
        gameState.gameIsPaused = true
        gameState.scores.player1 = gameState.scores.player1 + 1
        ResetGame()
    end

    -- Ball collisions on pads
    if
        -- Pad1 collision
        (ball.x < padWidth and pad1.y < ball.y and pad1.y + pad1.height > ball.y + ball.size)
        or
        -- Pad2 collisions
        (ball.x + ball.size > screenSize.width - padWidth and pad2.y < ball.y and pad2.y + pad2.height > ball.y + ball.size)
    then
        ball.vx = - ball.vx
        ball.speedLeft = ball.speedLeft + ballSpeedIncrease
        ball.speedRight = ball.speedRight + ballSpeedIncrease
    end
end

function StartGame()
    -- Randomly pick the first ball horizontal direction
    if math.random(2) == 1 then
        ball.vx = ball.vx + initialBallSpeed
    else
        ball.vx = ball.vx - initialBallSpeed
    end

    -- Randomly pick the first vertical direction
    if math.random(2) == 1 then
        ball.vy = ball.vy + initialBallSpeed
    else
        ball.vy = ball.vy - initialBallSpeed
    end

    gameState.gameIsRunning = true
end

function ResetGame()
    ball.size = initialBallSize
    ball.x = screenSize.centerX - ball.size / 2
    ball.y = screenSize.centerY - ball.size / 2

    pad1.height = initialPadHeight
    pad2.height = initialPadHeight
    pad1.y = screenSize.centerY - pad1.height
    pad2.y = screenSize.centerY - pad2.height
end

function GenerateScoreString()
    return "Player 1 : "..gameState.scores.player1.." / Player 2 : "..gameState.scores.player2
end

function love.keypressed(key)
    -- Space keyboard input is used to start the game and (un)pausing the game
    if key == "space" then
        if gameState.gameIsRunning then
            gameState.gameIsPaused = not gameState.gameIsPaused
        else
            StartGame()
        end

    -- Escape keyboard input is used to quit the game
    elseif key == "escape" then
        love.event.quit()

    -- Settings can only be changed before the game start
    -- all the settings are handled by the numpad + keyboard pressure
    elseif not gameState.gameIsRunning then
        -- Press H + a number on the keypad to increase the pads size
        if love.keyboard.isDown("h") then
            if key == "up" then
                initialPadHeight = math.min(maxPadHeight, initialPadHeight + 10)
            elseif key == "down" then
                initialPadHeight = math.max(minPadHeight, initialPadHeight - 10)
            end

            pad1.height = initialPadHeight
            pad2.height = initialPadHeight

        -- Press P + a number on the keypad to increase the pads speed
        elseif love.keyboard.isDown("p") then
            if key == "up" then
                initialPadSpeed = math.min(maxPadSpeed, initialPadSpeed + 10)
            elseif key == "down" then
                initialPadSpeed = math.max(minPadSpeed, initialPadSpeed - 10)
            end

            pad1.speed = initialPadSpeed
            pad2.speed = initialPadSpeed

        -- Press B + a number on the keypad to increase the ball first speed
        elseif love.keyboard.isDown("b") then
            if key == "up" then
                initialBallSpeed = math.min(maxBallSpeed, initialBallSpeed + 10)
            elseif key == "down" then
                initialBallSpeed = math.max(minBallSpeed, initialBallSpeed - 10)
            end

        -- Press S + a number on the keypad to increase speed increase on pads collisions
        elseif love.keyboard.isDown("s") then
            if key == "up" then
                ballSpeedIncrease = math.min(maxBallSpeedIncrease, ballSpeedIncrease + 1)
            elseif key == "down" then
                ballSpeedIncrease = math.max(minBallSpeedIncrease, ballSpeedIncrease - 1)
            end
        end
    end
end