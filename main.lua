-- main.lua
local json = require("json")
local anim8 = require("anim8")

local player = {}
local platforms = {}
local enemies = {}
local enemies2 = {}
local bonusBoxes = {}
local gravity = 800
local jumpStrength = -400
local playerSpeed = 200
local enemySpeed = 100
local bonusBoxSize = 32
local camera = {x = 0, y = 0}
local level_length_px = 0

local is_mobile = false

local max_player_a = 2
local player_a_const = 0.08
local bonus_count = 0

local player_a = 0.0

local deadZoneWidth = 100
local deadZoneHeight = 100
camera = {}
camera.x = 0
camera.y = 0
local cameraSpeed = 5
local previousDt = 0
local smoothingFactor = 0.8

local is_killed_by_enemy = false

local start_x, start_y

local logs = {}

function addLog(message)
    table.insert(logs, message)
end

local bullets = {}  -- Таблица для хранения всех пуль
local bulletBaseSpeed = 700  -- Базовая скорость пули
local bulletSize = 8  -- Размер пуль
local bulletGravity = 500  -- Гравитация для пуль
local fireInterval = 2  -- Интервал между выстрелами
local fireRange = 500  -- Радиус, в пределах которого враг стреляет
local count_to_triple = 0

local is_menu_mode = false

local level = 1

--------- MENU -----------
local levels = {}  -- Таблица с состоянием уровней
local selectedLevel = 1  -- Выбранный уровень
local font  -- Шрифт для надписи "Mario"
local smallFont  -- Шрифт для меню
local background  -- Фон для меню
local startGame = false  -- Флаг для начала игры
local currentLevel = nil  -- Текущий выбранный уровень
local gameOver = false  -- Флаг для окончания уровня

local count_levels = 5
local max_level = 1

local is_dark_background = false
local is_before_dark_back = false

local colors = {
    background = {0.4, 0.7, 1},  -- Небесный фон
    locked = {0.9, 0.9, 0.9},  -- Серый цвет для заблокированных уровней
    unlocked = {0.8, 0.3, 0.2},  -- Зеленый цвет для разблокированных уровней
    unlocked_boss = {0.0, 0.0, 1},
    selected = {1, 0.9, 0},  -- Желтый для выбранного уровня
    title = {0.7, 0.2, 0},  -- Оранжевый цвет для заголовка
}
--------------------------

function save_data_to_json() 
    --local data_raw = {{max_lvl = max_level}}
    --local data = json.encode(levels)
    --love.filesystem.write("temp_data/data.json", data)
end 

function load_data_from_json() 
    local file = love.filesystem.read("temp_data/data.json")
    if file then
        info = json.decode(file)
        max_level = info.max_lvl
        count_levels = info.count_levels
    else 
        max_level = 1
    end
end


function loadLevels()
    local file = love.filesystem.read("levels.json")
    if file then
        levels = json.decode(file)
    else
        -- Если файла нет, создаем начальные данные
        levels = {}
        for i=1, count_levels do
            table.insert(levels, {name = "Level "..i, unlocked = (i <= max_level)})
        end
    end
end

function love.load()
    load_data_from_json()

    is_menu_mode = true

    love.window.setTitle("Mario")
    love.window.setMode(800, 600)

    sound_jump = love.audio.newSource("assets/jump.mp3", "static")  -- замените 'yourfile.mp3' на имя вашего файла
    sound_back_soundtrack = love.audio.newSource("assets/back_music.mp3", "static")  -- замените 'yourfile.mp3' на имя вашего файла
    sound_back_birds = love.audio.newSource("assets/birds.mp3", "static")  -- замените 'yourfile.mp3' на имя вашего файла
    sound_back_soundtrack:setVolume(0.3)
    sound_back_birds:setVolume(0.5)
    
    sound_back_soundtrack:play()
    sound_back_birds:play()

    end_level = love.graphics.newImage("assets/end_level.png")

    font = love.graphics.newFont(60)
    smallFont = love.graphics.newFont(23)
    background = love.graphics.newImage("assets/background-spring.jpg")
    loadLevels()

    if is_mobile then 
        screenWidth = 800
        screenHeight = 400

        -- Определяем кнопки как таблицы с их положениями и размерами
        buttons = {
            up = {x = 60, y = screenHeight - 200, width = 60, height = 60, key = "space"},
            down = {x = 60, y = screenHeight - 60, width = 60, height = 60, key = "down"},
            left = {x = 0, y = screenHeight - 130, width = 60, height = 60, key = "left"},
            right = {x = 120, y = screenHeight - 130, width = 60, height = 60, key = "right"},
            jump = {x = screenWidth - 120, y = screenHeight - 130, width = 100, height = 60, key = "space"}, -- прыжок на пробел
            enter = {x = screenWidth - 60, y = 10, width = 50, height = 50, key = "return2"} -- Enter
        }
    
        -- Позиция игрока
        player = {x = screenWidth / 2, y = screenHeight / 2, speed = 200, jump = false}
    end 

    activeKeys = {
        up = false,
        down = false,
        left = false,
        right = false,
        space = false,
        return2 = false
    }

end

function openLevel(str) 
    local file = love.filesystem.read(str)
    local levelData = json.decode(file)

    if(level/5 <= 1) then --srping
        background = love.graphics.newImage("assets/background-spring.jpg")
        paral1 = love.graphics.newImage("assets/paral1-spring.png")
        paral2 = love.graphics.newImage("assets/paral2-spring.png")
        paral3 = love.graphics.newImage("assets/paral3-spring.png")
        deadZone = {}
        deadZone.spriteSheet = love.graphics.newImage('assets/dead_zone-spring.png')
        bulletTexture = love.graphics.newImage("assets/bullet-spring.png")
    elseif level/5 <= 2 then
        background = love.graphics.newImage("assets/background-winter.jpg")
        paral1 = love.graphics.newImage("assets/paral3-winter.png")
        paral2 = love.graphics.newImage("assets/paral1-winter.png")
        paral3 = love.graphics.newImage("assets/paral2-winter.png")
        deadZone = {}
        deadZone.spriteSheet = love.graphics.newImage('assets/dead_zone-winter.png')
        bulletTexture = love.graphics.newImage("assets/bullet-winter.png")
    end


    -- Инициализация игрока
    player = levelData.player
    start_x = player.x
    start_y = player.y
    player.dy = 0
    player_a = 0

    --player.sprite = love.graphics.newImage('assets/anim_mario.png')
    player.spriteSheet = love.graphics.newImage('assets/anim_mario.png')
    player.grid = anim8.newGrid( 192, 288, player.spriteSheet:getWidth(), player.spriteSheet:getHeight() )
    player.animations = {}
    player.animations.walk = anim8.newAnimation( player.grid('1-4',1, '1-1', 2), 0.2 )
    player.animations.dead = anim8.newAnimation( player.grid('1-1',3), 0.2)
    --player.animations.right = anim8.newAnimation( player.grid('1-4', 3), 0.2 )
    player.animations.up = anim8.newAnimation( player.grid('2-4', 2,'1-2', 3), 0.2 )
    player.anim = player.animations.walk
    player.direction = 1

    platformLeft = love.graphics.newImage('assets/wood_begin.png')
    platformCenter = love.graphics.newImage('assets/wood_middle.png')
    platformRight = love.graphics.newImage('assets/wood_end.png')
    beeBonusSprite = love.graphics.newImage('assets/bee_bonus.png')
    is_dark_background = false
    -- Инициализация платформ
    platforms = {}
    level_length_px =0
    for _, platform in ipairs(levelData.platforms) do
        addLog(level_length_px)
        level_length_px = math.max(platform.x + platform.width+1000, level_length_px)
        table.insert(platforms, platform)
    end
    enemies = {}
    -- Инициализация врагов
    for _, enemy in ipairs(levelData.enemies) do
        enemy.spriteSheet = love.graphics.newImage('assets/anim_enemy1.png')
        enemy.grid = anim8.newGrid( 192, 288, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight() )
        enemy.animations = {}
        enemy.animations.walk = anim8.newAnimation( enemy.grid('1-4',1, '1-4', 2), 0.08 )
        enemy.anim = enemy.animations.walk
        table.insert(enemies, enemy)
    end
    enemies2 ={}
    for _, enemy in ipairs(levelData.enemies2) do
        is_dark_background = enemy.evolution or is_dark_background
        enemy.spriteSheet = love.graphics.newImage('assets/anim_enemy2.png')
        enemy.grid = anim8.newGrid( 192, 288, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight() )
        enemy.animations = {}
        enemy.animations.walk = anim8.newAnimation( enemy.grid('1-4',1, '1-4', 2, '1-1', 3), 0.1 )
        enemy.anim = enemy.animations.walk
        enemy.fireTimer = fireInterval
        enemy.y = enemy.y - 35
        table.insert(enemies2, enemy)
    end
    bonusBoxes = {}
    -- Инициализация бонусных ящиков
    for _, box in ipairs(levelData.bonusBoxes) do
        table.insert(bonusBoxes, box)
    end

    if(is_dark_background) then 
        if(not is_before_dark_back) then 
            sound_back_soundtrack:stop()
            sound_back_birds:stop()
            sound_back_soundtrack = love.audio.newSource("assets/boss_fight.mp3", "static")  -- замените 'yourfile.mp3' на имя вашего файла
            sound_back_soundtrack:play()
        end
    else 
        if(is_before_dark_back) then 
            sound_back_soundtrack:stop()
            sound_back_soundtrack = love.audio.newSource("assets/back_music.mp3", "static")  -- замените 'yourfile.mp3' на имя вашего файла
            sound_back_birds:play()
            sound_back_soundtrack:play()
        end
    end
    is_before_dark_back = is_dark_background
end


function handlePlayerDeath()
    -- Можно добавить анимацию падения или эффект
    player.x = start_x 
    player.y = start_y  
    player.dy = 0  -- Останавливаем движение
    player.onGround = true  -- Считаем, что игрок на земле (для предотвращения падений)
    player.anim = player.animations.walk   
    -- Можно добавить логику перезапуска уровня или конца игры
    is_killed_by_enemy = false
end

function move_with_a()

    local isMoving = false

    if activeKeys["left"] or love.keyboard.isDown("left") and not(is_killed_by_enemy) then
        if(player.onGround) then 
            player.anim = player.animations.walk
        end
        player.direction = -1
        if(player_a < max_player_a) then 
            player_a = player_a + player_a_const
        end
        isMoving = true
    else 
        if player_a > 0 then 
            if(player_a < (player_a_const - 0.01)) then 
                player_a = 0
            else
                player_a = player_a - (player_a_const-0.01)
            end
        end
    end
    if activeKeys["right"] or love.keyboard.isDown("right") and not(is_killed_by_enemy) then
        if(player.onGround) then 
            player.anim = player.animations.walk
        end
        player.direction = 1
        if(player_a > -max_player_a) then 
            player_a = player_a - player_a_const
        end
        isMoving = true
    else
        if player_a < 0 then 
            if(player_a > -(player_a_const - 0.01)) then 
                player_a = 0
            else
                player_a = player_a + (player_a_const - 0.01)
            end
        end
    end
    return isMoving
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function updateCamera(dt)
    -- Используем среднее значение предыдущего и текущего dt для сглаживания
    local smoothDt = (previousDt + dt) / 2
    previousDt = dt

    -- Центр экрана
    local screenCenterX = love.graphics.getWidth() / 2
    local screenCenterY = love.graphics.getHeight() / 2

    -- Позиция игрока относительно центра экрана
    local offsetX = player.x - camera.x - screenCenterX + player.width / 2
    local offsetY = player.y - camera.y - screenCenterY + player.height / 2

    local targetX = camera.x
    local targetY = camera.y

    -- Проверка выхода за пределы мертвой зоны по X
    if math.abs(offsetX) > deadZoneWidth / 2 then
        if offsetX > 0 then
            targetX = player.x - screenCenterX + deadZoneWidth / 2
        else
            targetX = player.x - screenCenterX - deadZoneWidth / 2
        end
    end

    -- Проверка выхода за пределы мертвой зоны по Y
    if math.abs(offsetY) > deadZoneHeight / 2 then
        if offsetY > 0 then
            targetY = player.y - screenCenterY + deadZoneHeight / 2
        else
            targetY = player.y - screenCenterY - deadZoneHeight / 2
        end
    end

    -- Плавное движение камеры к целевой позиции с использованием сглаживания и стабильного обновления
    camera.x = camera.x + (targetX - camera.x) * smoothingFactor * smoothDt
    camera.y = camera.y + (targetY - camera.y) * smoothingFactor * smoothDt
end
-- Функция для создания пули с заданной погрешностью
-- Функция создания пули с углом от 30° до 90° относительно горизонта



function createBullet(enemy, targetX, targetY)

    local bullet = {
        x = enemy.x + enemy.width / 2,
        y = enemy.y + enemy.height / 2,
        dx = 0,  -- Горизонтальная скорость (будет рассчитана)
        dy = 0,  -- Вертикальная скорость (будет рассчитана)
        radius = bulletSize / 2,
    }

    -- Рассчитываем расстояние до игрока
    local distanceX = targetX - bullet.x
    local direction = distanceX > 0 and 0 or 1  -- Определяем, с какой стороны находится игрок (справа или слева)
    local distanceY = targetY - bullet.y
    local distance = distanceX --math.sqrt(distanceX^2 + distanceY^2)

    -- Рассчитываем угол между врагом и игроком
    local angleToPlayer = math.atan2(distanceY, distanceX)

    -- Устанавливаем скорость пули пропорционально расстоянию
    local speed = bulletBaseSpeed * (distance / 500) + math.random()*200 - 100-- Умножаем на коэффициент для нормализации скорости

    -- Устанавливаем направление пули под углом 45° (π/4 радиан)
    bullet.dx = speed * math.cos(angleToPlayer + 180*direction + math.rad(-45))
    bullet.dy = speed * math.sin(angleToPlayer + 180*direction + math.rad(-45))

    table.insert(bullets, bullet)
end

-- Функция для проверки столкновения круга и прямоугольника
function checkCircleRectangleCollision(circle, rect)

    local closestX = math.max(rect.x, math.min(circle.x, rect.x + rect.width))
    local closestY = math.max(rect.y, math.min(circle.y, rect.y + rect.height))

    local distanceX = circle.x - closestX
    local distanceY = circle.y - closestY

    return (distanceX * distanceX + distanceY * distanceY) < (circle.radius * circle.radius)
end

-- Функция обновления пуль
function updateBullets(dt)
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]

        -- Применяем гравитацию
        bullet.dy = bullet.dy + bulletGravity * dt

        -- Обновляем позицию пули
        bullet.x = bullet.x + bullet.dx * dt
        bullet.y = bullet.y + bullet.dy * dt

        bullet.rotation = math.atan2(bullet.dy, bullet.dx)

        -- Проверяем столкновения с платформами
        for _, platform in ipairs(platforms) do
            if bullet.x + bullet.radius > platform.x and
               bullet.x - bullet.radius < platform.x + platform.width and
               bullet.y + bullet.radius > platform.y and
               bullet.y - bullet.radius < platform.y + platform.height then
                -- Если пуля касается платформы, удаляем её
                table.remove(bullets, i)
                break
            end
        end

        -- Проверяем столкновение пули с игроком
        if checkCircleRectangleCollision(bullet, player) then
            if(not(is_killed_by_enemy)) then 
                player.dy = -200
                player.anim = player.animations.dead      
            end
            is_killed_by_enemy = true
            table.remove(bullets, i)  -- Удаляем пулю
        end

        -- Если пуля выходит за пределы экрана, удаляем её
        --if bullet.x < 0 or bullet.x > love.graphics.getWidth() or bullet.y > love.graphics.getHeight() then
        --    table.remove(bullets, i)
        --end
    end
end

-- Функция отрисовки пуль
function drawBullets()
    for _, bullet in ipairs(bullets) do
        -- Рисуем текстуру пули с поворотом
        love.graphics.draw(bulletTexture, bullet.x, bullet.y, bullet.rotation, 0.05, 0.05, bulletTexture:getWidth() / 2, bulletTexture:getHeight() / 2)
    end
end

-- Функция обновления врага, который стреляет
function updateEnemyFire(enemy, dt, player)


    -- Проверяем расстояние до игрока
    local distanceToPlayer = math.sqrt((player.x - enemy.x)^2 + (player.y - enemy.y)^2)

    -- Враг стреляет только если игрок находится в пределах fireRange
    if distanceToPlayer <= fireRange then
        -- Таймер стрельбы
        enemy.fireTimer = enemy.fireTimer - dt
        if enemy.fireTimer <= 0 then
            -- Стреляем в игрока

            count_to_triple = count_to_triple + 1
            if(count_to_triple == 3) then 
                for i=1 , 3 do
                    createBullet(enemy, player.x, player.y) 
                end
                count_to_triple = 0
            else 
                createBullet(enemy, player.x, player.y) 
            end
            if(enemy.evolution) then
                fireRange = 1000
                enemy.fireTimer = ((math.random()*10) > 9) and 2 or fireInterval / 50
                bulletBaseSpeed = 2000  -- Базовая скорость пули
                bulletSize = 12  -- Размер пуль  
            else 
                enemy.fireTimer = fireInterval  -- Перезагружаем таймер
                bulletBaseSpeed = 700  -- Базовая скорость пули
                bulletSize = 8  -- Размер пуль  
            end
        end
    end
end

function handlePlayerWin()
    level = level + 1
    max_level = math.max(level, max_level)
    if(level > count_levels) then 
        gameOver = true
        endLevel()
    else
        openLevel("levels/map"..level..".json")
    end
end

function love.keypressed(key)
        if startGame then
            -- Когда игра начата, обрабатываем завершение игры
            if key == "escape" then
                gameOver = true
                endLevel()
            end
        else
            -- Управление меню
            if key == "up" then
                selectedLevel = math.max(selectedLevel - 1, 1)
            elseif key == "down" then
                selectedLevel = math.min(selectedLevel + 1, #levels)
            elseif key == "return" and levels[selectedLevel].unlocked then
                startLevel()
            elseif key == "escape" then
                love.event.quit()
            end
        end
end

-- Функция начала уровня
function startLevel()
    startGame = true
    currentLevel = levels[selectedLevel].name
    gameOver = false
    level = selectedLevel
    openLevel("levels/map"..level..".json")
    is_menu_mode = false
    --print("Starting " .. currentLevel)
    -- Здесь пишем код для начала уровня
end

-- Функция окончания уровня
function endLevel()
    startGame = false
   -- addLog(startGame)
    --if not gameOver then
    --    print("Level completed: " .. currentLevel)
    --    -- Здесь код для завершения уровня (например, разблокировка следующего уровня)
    --    if selectedLevel < #levels and not levels[selectedLevel + 1].unlocked then
    --        levels[selectedLevel + 1].unlocked = true
    --    end
    --    saveLevels()
    --end
    loadLevels()
    save_data_to_json()
    is_menu_mode = true
end

function love.touchpressed(id, tx, ty)
    -- Эмулируем нажатие клавиш при касании виртуальных кнопок
    addLog(1)
    for _, button in pairs(buttons) do
        if isInside(tx, ty, button) then
            activeKeys[button.key] = true
        end
    end
end

function love.touchreleased(id, tx, ty)
    -- Эмулируем отпускание клавиш
    for _, button in pairs(buttons) do
        if isInside(tx, ty, button) then
            activeKeys[button.key] = false
        end
    end
end

function love.update(dt)

    if activeKeys["return2"] then
        startLevel()
    end

    if(not startGame) then 
        return 
    end

    -- Player move    
    local isMoving = move_with_a()
    player.x = player.x - playerSpeed * dt * player_a

    -- Прыжок
    if activeKeys["space"] or love.keyboard.isDown("space") and player.onGround then
        if player.onGround then
            player.dy = jumpStrength
            player.onGround = false
            player.anim = player.animations.up
            player.anim:gotoFrame(1)
            sound_jump:play()
        end
    end

    if(player.onGround == false) then 
        isMoving = true
    end

    -- Применение гравитации
    player.dy = player.dy + gravity * dt
    player.y = player.y + player.dy * dt

    -- Проверка столкновений с платформами
    if(not(is_killed_by_enemy)) then
        local count = false
        for _, platform in ipairs(platforms) do
            -- Проверка столкновения с платформой
            if player.x < platform.x + platform.width and
            player.x + player.width > platform.x and
            player.y + player.height > platform.y and
            player.y < platform.y + platform.height then
                count = true
                -- Если игрок падает
                if player.dy > 0 and player.y + player.height <= platform.y + player.dy*dt + 5 then
                    player.y = platform.y - player.height  -- Устанавливаем игрока на верх платформы
                    player.dy = 0
                    player.onGround = true
                    player.anim = player.animations.walk
                elseif player.dy < 0 and player.y >= platform.y + platform.height + player.dy*dt then
                    player.y = platform.y + platform.height  -- Устанавливаем игрока под платформой
                    player.dy = 0
                else
                    -- Если игрок находится на уровне платформы, корректируем его позицию
                    if player.x + player.width / 2 < platform.x + platform.width / 2 then
                        player.x = platform.x - player.width  -- Слева от платформы
                    else
                        player.x = platform.x + platform.width  -- Справа от платформы
                    end
                end
            end
        end
        if not count then 
            player.onGround = false
        end
    end

    -- Ограничение игрока по оси Y
    if player.y > 1400 then
        player.y = 1400
        player.dy = 0
        player.onGround = true
        handlePlayerDeath()
    end

    -- Ограничение по оси X (в пределах уровня)
    if player.x < 0 then
        player.x = 0
    elseif player.x > level_length_px - player.width then
        player.x = level_length_px - player.width
    end

    -- Движение врагов
    for _, enemy in ipairs(enemies) do
        local new_x = enemy.x + enemySpeed * enemy.direction * dt

        -- Изменение направления врагов при столкновении с границами
        if enemy.x < 0 or enemy.x > level_length_px - enemy.width or enemy.current_walk >= enemy.walk_area then
            enemy.direction = -enemy.direction
            enemy.current_walk = 0
        else 
            enemy.current_walk = enemy.current_walk + math.abs(new_x - enemy.x)
        end

        enemy.x = new_x

        -- Проверка столкновений с игроком
        if player.x < enemy.x + enemy.width and
           player.x + player.width > enemy.x and
           player.y < enemy.y + enemy.height and
           player.y + player.height > enemy.y then
            -- Если происходит столкновение, игрок "падает"
            if(not(is_killed_by_enemy)) then 
                player.dy = -200
                player.anim = player.animations.dead      
            end
            is_killed_by_enemy = true
            --handlePlayerDeath()
        end
    end

    -- Движение врагов 2
    updateBullets(dt)
    for _, enemy in ipairs(enemies2) do
        updateEnemyFire(enemy, dt, player)
        --local new_x = enemy.x + enemySpeed * enemy.direction * dt
--
        ---- Изменение направления врагов при столкновении с границами
        --if enemy.x < 0 or enemy.x > level_length_px - enemy.width or enemy.current_walk >= enemy.walk_area then
        --    enemy.direction = -enemy.direction
        --    enemy.current_walk = 0
        --else 
        --    enemy.current_walk = enemy.current_walk + math.abs(new_x - enemy.x)
        --end
--
        --enemy.x = new_x

        -- Проверка столкновений с игроком
        if player.x < enemy.x + enemy.width and
           player.x + player.width > enemy.x and
           player.y < enemy.y + enemy.height and
           player.y + player.height > enemy.y then
            -- Если происходит столкновение, игрок "падает"
            if(not(is_killed_by_enemy)) then 
                player.dy = -200
                player.anim = player.animations.dead      
            end
            is_killed_by_enemy = true
            --handlePlayerDeath()
        end
    end

    -- Проверка столкновений с бонусными ящиками (как с платформами)
    if(not(is_killed_by_enemy)) then 
        for i = #bonusBoxes, 1, -1 do
            local box = bonusBoxes[i]

            -- Проверка столкновения с верхней частью ящика (как с платформой)
            if player.x < box.x + box.width and
            player.x + player.width > box.x and
            player.y + player.height > box.y and
            player.y + player.height < box.y + box.height then
                player.y = box.y - player.height
                player.dy = 0
                player.onGround = true
                player.anim = player.animations.walk
            end

            -- Проверка на столкновение с бонусным ящиком при ударе снизу
            if player.x < box.x + box.width and
            player.x + player.width > box.x and
            player.dy < 0 and -- Игрок должен двигаться вверх
            player.y < box.y + box.height and -- Верхняя часть игрока выше нижней части ящика
            player.y + player.height > box.y + box.height then -- Игрок касается именно нижней части ящика
                -- Если игрок ударяет ящик снизу, то ящик удаляется (собирается)
                bonus_count = bonus_count + 1
                jumpStrength = jumpStrength - 10
                table.remove(bonusBoxes, i)
            end

            -- Боковые столкновения с ящиком (чтобы предотвратить прохождение через него)
            if player.x < box.x + box.width and
            player.x + player.width > box.x and
            player.y + player.height > box.y and
            player.y < box.y + box.height then
                if player.x + player.width / 2 < box.x + box.width / 2 then
                    player.x = box.x - player.width
                else
                    player.x = box.x + box.width
                end
            end
        end
    end
    updateCamera(dt)

    -- Ограничение камеры по оси X
    if camera.x < 0 then camera.x = 0 end
    if camera.x > level_length_px - love.graphics.getWidth() then camera.x = 1300 - love.graphics.getWidth() end

    if(player.x > level_length_px - 820 and player.y >550) then
        handlePlayerWin()
    end

    if isMoving == false then
        player.anim:gotoFrame(2)
    end
    player.anim:update(dt)

    for _, enemy in ipairs(enemies) do
        enemy.anim:update(dt)
    end
    for _, enemy in ipairs(enemies2) do
        enemy.anim:update(dt)
    end
end

function applyScreenDarkening(alpha)
    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)
end

function menu_draw()
    love.graphics.clear(0, 0, 0)
    love.graphics.setColor(1, 1, 1)
 
        -- Отрисовка меню
        love.graphics.setBackgroundColor(colors.background)
        love.graphics.draw(background, 0, 0, 0, love.graphics.getWidth() / background:getWidth(), love.graphics.getHeight() / background:getHeight())

        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill", 50, 150, love.graphics.getWidth()-100, love.graphics.getHeight()-200, 20, 20)

        -- Отображение надписи Mario
        love.graphics.setColor(colors.title)
        love.graphics.setFont(font)
        love.graphics.printf("MARIO SEASONS", 0, 50, love.graphics.getWidth(), "center")

        -- Рисуем меню уровней
        love.graphics.setFont(smallFont)
        for i, level in ipairs(levels) do
            local x = math.floor((i - 1)/7) * 245 - 250
            local y = 200 + (i - 1)%7 * 50
            
            -- Устанавливаем цвет для уровня
            if i == selectedLevel then
                love.graphics.setColor(colors.selected)  -- Желтый для выбранного уровня
            elseif level.unlocked then
                if(i % 5 == 0) then -- boss
                    love.graphics.setColor(colors.unlocked_boss)  -- Зеленый для открытых уровней
                else
                    love.graphics.setColor(colors.unlocked)  -- Зеленый для открытых уровней
                end 
            else
                love.graphics.setColor(colors.locked)  -- Серый для заблокированных уровней
            end

            -- Если уровень закрыт, отображаем его как заблокированный
            local levelText = level.name
            if not level.unlocked then
                levelText = levelText .. " (Locked)"
            end
            love.graphics.printf(levelText, x, y, love.graphics.getWidth(), "center")
        end
end

function drawButton(button, label)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(label, button.x, button.y + button.height / 4, button.width, "center")
end

-- Проверяем, находится ли касание внутри кнопки
function isInside(tx, ty, button)
    return tx > button.x and tx < button.x + button.width and ty > button.y and ty < button.y + button.height
end

function love.draw()

    if not startGame then 
        menu_draw()
        if is_mobile then
            drawButton(buttons.up, "UP")
            drawButton(buttons.down, "DOWN")
            drawButton(buttons.left, "LEFT")
            drawButton(buttons.right, "RIGHT")
            drawButton(buttons.jump, "JUMP")
            drawButton(buttons.enter, "ENTER")
        end
        return
    end

    love.graphics.clear(0, 0, 0)
    love.graphics.setColor(1, 1, 1)
    -- Функция для рисования повторяющегося слоя
    local function drawLayer(image, scrollFactor, yOffset, xOffset)
        local imageWidth = image:getWidth()

        local x = 0

        if xOffset then
            x = xOffset
            x = x - (camera.x * scrollFactor)
        else 
            x = -(camera.x * scrollFactor) % imageWidth
        end

        local y = yOffset or 0
        if yOffset then
            y = y - (camera.y * scrollFactor)
        end

        love.graphics.draw(image, x, y)
        if not(xOffset) then
            love.graphics.draw(image, x - imageWidth, y)
        end
    end

    if(is_dark_background) then
        love.graphics.setColor(0, 0, 1, 1) 
    end
        drawLayer(background, 0.2)
        drawLayer(paral3, 0.5)
        drawLayer(paral2, 0.8)
        drawLayer(paral1, 1.5)
    
     -- Настройки текста
     love.graphics.setColor(1, 1, 1, 1) -- Белый цвет
     love.graphics.setFont(love.graphics.newFont(12)) -- Размер шрифта 12
 
     -- Отрисовка логов
     local y = 10
     for i, log in ipairs(logs) do
         love.graphics.print(log, 10, y)
         y = y + 15 -- Интервал между строками
     end

    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    player.anim:draw(player.spriteSheet, player.x + (player.direction == -1 and 0 or player.width), player.y, 0, -player.direction*0.35, 0.35)
    local scale = 0.2

    if(is_dark_background) then
        love.graphics.setColor(0.7, 0.7, 0.7, 1) 
    end

    for _, platform in ipairs(platforms) do
        
        -- Рисуем левую часть платформы
        love.graphics.draw(platformLeft, platform.x, platform.y, 0, scale, scale)

        -- Рисуем центральную часть платформы (повторяющийся элемент)
        local centerWidth = platformCenter:getWidth() * scale
        local startX = platform.x + platformLeft:getWidth() * scale
        local endX = platform.x + platform.width - platformRight:getWidth() * scale

        local currentX = startX
        while currentX + centerWidth <= endX do
            love.graphics.draw(platformCenter, currentX, platform.y, 0, scale, scale)
            currentX = currentX + centerWidth
        end

        -- Обрезаем последнюю текстуру если она выходит за грань
        local remainingWidth = endX - currentX
        if remainingWidth > 0 then
            love.graphics.draw(platformCenter, currentX, platform.y, 0, remainingWidth / platformCenter:getWidth(), scale)
        end

        -- Рисуем правую часть платформы
        love.graphics.draw(platformRight, platform.x + platform.width - platformRight:getWidth() * scale, platform.y, 0, scale, scale)
    end

    love.graphics.setColor(1, 1, 1, 1) 

    for _, enemy in ipairs(enemies) do
        --love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.width, enemy.height)
        enemy.anim:draw(enemy.spriteSheet, enemy.x + (enemy.direction == 1 and 0 or enemy.width), enemy.y - 53, 0, -(enemy.direction == 1 and -1 or 1)*0.35, 0.35)
    end

    for _, enemy in ipairs(enemies2) do
        --love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.width, enemy.height)
        if(enemy.evolution) then 
            love.graphics.setColor(0.3, 0.3, 0, 1) 
            enemy.anim:draw(enemy.spriteSheet, enemy.x, enemy.y-140, 0, 1, 1)
            love.graphics.setColor(1, 1, 1, 1) 
        else
            enemy.anim:draw(enemy.spriteSheet, enemy.x, enemy.y, 0, 0.35, 0.35)
        end
    end

    --love.graphics.setColor(255, 255, 0) -- Желтый цвет для бонусных ящиков
    for _, box in ipairs(bonusBoxes) do
        love.graphics.draw(beeBonusSprite, box.x - 20, box.y - 20, 0, 0.1, 0.1)
    end

    drawBullets()

    -- Возврат к исходной трансформации
    love.graphics.pop()

    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.setFont(love.graphics.newFont(24)) -- Шрифт размером 24
    love.graphics.print(bonus_count, love.graphics.getWidth() -80, 15) -- Параметры: текст, x, y
    love.graphics.setFont(love.graphics.newFont(12)) -- Шрифт размером 24
    love.graphics.setColor(1, 0, 1, 1)
    love.graphics.print("Jump: "..tostring(-jumpStrength), love.graphics.getWidth() -110, 43) -- Параметры: текст, x, y
    love.graphics.setColor(1, 1, 1, 1) -- Белый цвет

    love.graphics.draw(beeBonusSprite, love.graphics.getWidth() -50, 0, 0.08, 0.08)

    drawLayer(end_level, 1.0, 430, level_length_px - 850)   

    if(is_dark_background) then
        love.graphics.setColor(0, 0.5, 1, 1) 
    end

    drawLayer(deadZone.spriteSheet, 1.0, 300)

    applyScreenDarkening(((player.y-600) / 790))


    if is_mobile then
        drawButton(buttons.up, "UP")
        drawButton(buttons.down, "DOWN")
        drawButton(buttons.left, "LEFT")
        drawButton(buttons.right, "RIGHT")
        drawButton(buttons.jump, "JUMP")
        drawButton(buttons.enter, "ENTER")
    end
end


function love.quit()
    save_data_to_json()
end
