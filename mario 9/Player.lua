Player = Class{}

require "Animation"


local MOVE_SPEED = 80
local JUMP_VELOCITY = 400
local GRAVITY = 40

function Player:init(map)
    self.width = 16
    self.height = 20

    self.x = map.tilewidth * 10
    self.y = map.tileheight * ((map.mapheight - 2) / 2) - self.height
    self.dx = 0
    self.dy = 0

    self.map = map
    
    self.texture = love.graphics.newImage("graphics/blue_alien.png")
    self.frames = generateQuads(self.texture, 16, 20)

    self.state = "idle"
 
    self.animations = {
        ["idle"] = Animation {
            texture = self.texture,
            frames =  {
                self.frames[1]
            },
            interval = 1
        },

        ["walking"] = Animation {
            texture = self.texture,
            frames = {
                self.frames[9], self.frames[10], self.frames[11]
            },
            interval = 0.15
        },

        ["jumping"] = Animation {
            texture = self.texture, 
            frames = {
                self.frames[3]
            },
            interval = 1
        }
    }

    self.animation = self.animations["idle"]
    self.direction = "right"

    self.behaviours = {
        ["idle"] = function(dt)
            if love.keyboard.wasPressed("space") then
                self.dy = -JUMP_VELOCITY
                self.state = "jumping"
                self.animation = self.animations["jumping"]
            elseif love.keyboard.isDown("a") then
                self.dx = - MOVE_SPEED 
                self.animation = self.animations["walking"]
                self.direction = "left"
            elseif love.keyboard.isDown("d") then
                self.dx = MOVE_SPEED
                self.animation = self.animations["walking"]
                self.direction = "right"
            else
                self.dx = 0
                self.animation = self.animations["idle"]
            end
        end, 
        ["walking"] = function(dt)
            if love.keyboard.wasPressed("space") then
                self.dy = -JUMP_VELOCITY
                self.state = "jumping"
                self.animation = self.animations["jumping"]
            elseif love.keyboard.isDown("a") then
                self.dx = - MOVE_SPEED
                self.animation = self.animations["walking"]
                self.direction = "left"
            elseif love.keyboard.isDown("d") then
                self.dx = MOVE_SPEED
                self.animation = self.animations["walking"]
                self.direction = "right"
            else
                self.dx = 0
                self.state = "idle"
                self.animation = self.animations["idle"]
            end

            -- check for collision when moving left or right
            self:checkRightCollision()
            self:checkLeftCollision()

            -- check if there is a tile beneath
            if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
                
                -- reset velocity and position  and change state
                self.state = "jumping"
                self.animations = self.animations["jumping"]
            end
        end,

        ["jumping"] = function(dt)
            if self.y > 300 then
                return
            end

            if love.keyboard.isDown("a") then
                self.direction = "left"
                self.dx = -MOVE_SPEED
            elseif love.keyboard.isDown("d") then
                self.direction = "right"
                self.dx = MOVE_SPEED
            end

            self.dy = self.dy + GRAVITY

            if self.map:collides(self.map:tileAt(self.x, self.y + self.height)) or
                self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then

                self.dy = 0
                self.state = "idle"
                self.animation = self.animations["idle"]
                self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileheight - self.height
            end

            -- check for collisions left and right
            self:checkRightCollision()
            self:checkLeftCollision()
        end
    }
end


function Player:update(dt)
    self.behaviours[self.state](dt)
    self.animation:update(dt)
    self.currentFrame = self.animation:getCurrentFrame()

    self.x = self.x + self.dx * dt

    if self.dy < 0 then
        if self.map:tileAt(self.x, self.y).id ~= TILE_EMPTY or
            self.map:tileAt(self.x + self.width - 1, self.y).id ~= TILE_EMPTY then
            self.dy = 0
            -- change block to hit block
            if self.map:tileAt(self.x, self.y).id == JUMP_BLOCK then
                self.map:setTile(math.floor(self.x / self.map.tilewidth) + 1, 
                    math.floor(self.y / self.map.tileheight) + 1, JUMP_BLOCK_HIT)
            end
            if self.map:tileAt(self.x + self.width - 1, self.y).id == JUMP_BLOCK then
                self.map:setTile(math.floor((self.x + self.width - 1) / self.map.tilewidth) + 1, 
                math.floor(self.y / self.map.tileheight) + 1, JUMP_BLOCK_HIT)
            end
        end 
    end 

    self.y = self.y + self.dy * dt
end


function Player:checkLeftCollision()
    if self.dx < 0 then
        -- check if there is a tile under
        if self.map:collides(self.map:tileAt(self.x - 1, self.y)) or 
            self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height)) then
            -- reset velocity and position and change state
            self.dx = 0 
            self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tilewidth
        end
    end
end


function Player:checkRightCollision()
    if self.dx > 0 then
        -- check if there is a tile under
        if self.map:collides(self.map:tileAt(self.x + self.width, self.y)) or
            self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) then
            -- reset velocity and position and change state
            self.dx = 0
            self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tilewidth - self.width
        end
    end
end


function Player:render()
    local scalex
    if self.direction == "right" then
        scalex = 1
    else
        scalex = -1
    end

    love.graphics.draw(self.texture, self.animation: getCurrentFrame(), 
        math.floor(self.x + self.width / 2), math.floor(self.y + self.height / 2),
        0, scalex, 1,
        self.width / 2, self.height / 2)
end