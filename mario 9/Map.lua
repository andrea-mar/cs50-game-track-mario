require "Util"
require "Player"

Map = Class{}

TILE_BRICK = 1
TILE_EMPTY = 4

-- cloud tiles
CLOUD_LEFT = 6
CLOUD_RIGHT = 7

-- bush tiles
BUSH_LEFT = 2
BUSH_RIGHT = 3

--mushroom tile
MUSHROOM_TOP = 10
MUSHROOM_BOTTOM = 11

-- jump block
JUMP_BLOCK = 5
JUMP_BLOCK_HIT = 9

local SCROLL_SPEED = 62

function Map:init()
    self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
    self.tilewidth = 16
    self.tileheight = 16
    self.mapwidth = 30
    self.mapheight = 28
    self.tiles = {}

    self.player = Player(self)

    self.camx = 0
    self.camy = 0

    self.tileSprites = generateQuads(self.spritesheet, self.tilewidth, self.tileheight)

    self.mapWidthPixels = self.mapwidth * self.tilewidth
    self.mapHeightPixels = self.mapheight * self.tileheight

    -- fills map with empty tiles
    for y = 1, self.mapheight do
        for x = 1, self.mapwidth do
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    local x = 1
    while x < self.mapwidth - 2 do

        -- 2% chance to draw a cloud
        -- make sure it s 2 tiles from the edge at least
        if x < self.mapwidth - 2 then
            if math.random(20) == 1 then
                -- choose a random vertical spot above where blocks generate
                local cloudStart = math.random(self.mapheight / 2 - 6)
                self:setTile(x, cloudStart, CLOUD_LEFT)
                self:setTile(x + 1, cloudStart, CLOUD_RIGHT)
            end
        end

        -- 5% chance to generate mushroom
        if math.random(20) == 1 then
            self:setTile(x, self.mapheight / 2 - 2, MUSHROOM_TOP)
            self:setTile(x, self.mapheight / 2 - 1, MUSHROOM_BOTTOM)

            -- create column of tiles under the mushroom
            for y = self.mapheight / 2, self.mapheight do
                self:setTile(x, y, TILE_BRICK)
            end

            -- next vertical scan line
            x = x + 1
        -- 10% chance to generate a bush away from the edge
        elseif math.random(10) == 1 and x < self.mapwidth - 3 then
            local bushLevel = self.mapheight / 2 - 1

            -- place bush then a column of brick underneath
            self:setTile(x, bushLevel, BUSH_LEFT)
            for y = self.mapheight / 2, self.mapheight do
                self:setTile(x, y, TILE_BRICK)
            end
            x = x + 1

            self:setTile(x, bushLevel, BUSH_RIGHT)
            for y = self.mapheight / 2, self.mapheight do
                self:setTile(x, y, TILE_BRICK)
            end
            x = x + 1

        -- 10% chance t0 not generate anything / create a gap
        elseif math.random(10) ~= 1 then

            -- create column of bricks
            for y = self.mapheight / 2, self.mapheight do
                self:setTile(x, y, TILE_BRICK)
            end

            --chance to create a jump block to hit
            if math.random(15) == 1 then
                self:setTile(x, self.mapheight / 2 - 4, JUMP_BLOCK)
            end
            x = x + 1
        else
            -- increment x so we can skip scanlines
            x = x + 2
        end
    end
--[[
-- half way down the map populates with bricks
    for y = self.mapheight / 2, self.mapheight do
        for x = 1, self.mapwidth do
            self:setTile(x, y, TILE_BRICK)
        end
    end
]]
end


function Map:collides(tile)
    local collidables = {
        TILE_BRICK, JUMP_BLOCK, JUMP_BLOCK_HIT, MUSHROOM_TOP, MUSHROOM_BOTTOM
    }

    for _, v in ipairs(collidables) do
        if tile.id == v then
            return true
        end
    end

    return false
end



function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tilewidth) + 1,
        y = math.floor(y / self.tileheight) + 1,
        id = self:getTile(math.floor(x / self.tilewidth) + 1, math.floor(y / self.tileheight) + 1)
    }
end


function Map:setTile(x, y, id)
   self.tiles[(y - 1) * self.mapwidth + x] = id
end


function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapwidth + x]
end


function Map:update(dt)
    self.camx = math.max(0, 
        math.min(self.player.x - VIRTUAL_WIDTH / 2, 
            math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.player.x)))

    self.player:update(dt)
end


function Map:render()
    for y = 1, self.mapheight do
        for x = 1, self.mapwidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.spritesheet, self.tileSprites[tile], 
                    (x - 1) * self.tilewidth, (y - 1) * self.tileheight)
            end
        end
    end

    self.player:render()

end

