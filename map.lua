-- map.lua
local entity = require "entity"
local state = require "state"

local M = {}

local loadEntities = function(map, objectgroup)
    for _, object in ipairs(map.layers[objectgroup].objects) do
        local position = {
            x = object.x,
            y = object.y
        }
        object.position = position
        entity.new(object)
    end
end

M.new = function(arg)
    local map = nil
    local success, map = pcall(arg.data)
    local tilelayer = nil
    local objectgroup = nil

    local object = {}

    -- find layers
    for i, layer in ipairs(map.layers) do
        if layer.type == "tilelayer" then
            tilelayer = i
        elseif layer.type == "objectgroup" then
            objectgroup = i
        end
    end

    -- map properties
    --[[for k,v in pairs(map.properties) do
    local property = assert(loadstring(v))
    _,map.properties[k] = pcall("return " .. property)
    print(map.properties[k])
  end]]
    object.properties = function()
        return map.properties
    end

    -- tileset properties
    for _, tileset in ipairs(map.tilesets) do
        local tiles = {}
        for _, tile in ipairs(tileset.tiles) do
            tiles[tile.id + 1] = tile.properties
        end
        tileset.tiles = tiles
    end

    -- tile data
    local data = {}
    for x = 1, map.layers[1].width do
        data[x] = {}
        for y = 1, map.layers[1].height do
            data[x][y] = map.layers[1].data[x + ((y - 1) * map.layers[tilelayer].width)]
        end
    end
    map.layers[1].data = data

    loadEntities(map, objectgroup)

    -- render info
    local tileset = {}
    tileset.image = love.graphics.newImage("game/" .. map.tilesets[1].image)
    tileset.image:setFilter("linear", "linear")

    tileset.quads = {}
    local tile_width = map.tilesets[1].tilewidth
    local tile_height = map.tilesets[1].tileheight
    local tiles_x = map.tilesets[1].imagewidth / tile_width
    local tiles_y = map.tilesets[1].imageheight / tile_height
    local max_tiles = tiles_x * tiles_y

    -- Create quads for the tileset
    for i = 1, max_tiles do
        local quad_x = ((i - 1) % tiles_x) * tile_width
        local quad_y = math.floor((i - 1) / tiles_x) * tile_height
        tileset.quads[i] = love.graphics.newQuad(quad_x, quad_y, tile_width, tile_height, map.tilesets[1].imagewidth,
            map.tilesets[1].imageheight)
    end

    -- Prepare the SpriteBatch
    local batch = love.graphics.newSpriteBatch(tileset.image, map.width * map.height)
    batch:clear()

    -- Fill the SpriteBatch with map data
    for x = 1, map.layers[tilelayer].width do
        for y = 1, map.layers[tilelayer].height do
            local tile_id = map.layers[tilelayer].data[x][y]
            if tile_id > 0 and tileset.quads[tile_id] then
                batch:add(tileset.quads[tile_id], (x - 1) * tile_width, (y - 1) * tile_height)
            end
        end
    end

    -- Create and use a canvas
    local canvas = love.graphics.newCanvas(map.width * tile_width, map.height * tile_height)
    canvas:setWrap("repeat", "repeat")

    -- parallax
    local parallax = {}
    for i = 1, 3 do
        if map.properties["parallax" .. i] then
            parallax[i] = love.graphics.newImage("game/" .. map.properties["parallax" .. i])
        else
            break
        end
    end

    object.width = function()
        return map.width * map.tilewidth
    end

    object.height = function()
        return map.height * map.tileheight
    end

    -- getTileIndices(arg)
    object.getTileIndices = function(arg)
        return {
            x = math.ceil(arg.x / (map.tilesets[tilelayer].tilewidth * entity.scale)),
            y = math.ceil(arg.y / (map.tilesets[tilelayer].tileheight * entity.scale))
        }
    end

    -- getTileProperties(arg)
    object.getTileProperties = function(arg)
        if arg.x < 1 or arg.y < 1 or arg.x > map.layers[tilelayer].width or arg.y > map.layers[tilelayer].height then
            return {}
        end
        local tile_id = map.layers[tilelayer].data[arg.x][arg.y]
        local properties = {}
        if map.tilesets[tilelayer].tiles[tile_id] then
            for k, v in pairs(map.tilesets[tilelayer].tiles[tile_id]) do
                local f = assert(loadstring("return " .. v))
                _, properties[k] = pcall(f)
            end
        end
        return properties
    end

    -- getTileBounds(arg)
    object.getTileBounds = function(arg)
        return {
            top = (arg.y - 1) * (map.tilesets[tilelayer].tileheight * entity.scale),
            left = (arg.x - 1) * (map.tilesets[tilelayer].tilewidth * entity.scale),
            bottom = arg.y * (map.tilesets[tilelayer].tileheight * entity.scale),
            right = arg.x * (map.tilesets[tilelayer].tilewidth * entity.scale)
        }
    end

    -- prerender()
    object.prerender = function()
        canvas:renderTo(function()
            love.graphics.clear()
            love.graphics.setColor(255 / 255.0, 255 / 255.0, 255 / 255.0)
            love.graphics.draw(batch, 0, 0, 0, 1, 1, 0, 0, 0, 0)
        end)
    end

    -- render()
    object.render = function()
        local camera = state.get().camera.position
        love.graphics.setColor(255 / 255.0, 255 / 255.0, 255 / 255.0)
        local screen_width = love.graphics.getWidth() -- native_mode.width
        local screen_height = love.graphics.getHeight() -- native_mode.height
        for i = 1, #parallax do
            parallax[i]:setWrap('repeat', 'repeat')
            local image = parallax[i]
            local width = parallax[i]:getWidth()
            local height = parallax[i]:getHeight()
            local x = (i / 10) * (camera.x - (screen_width / 2))
            local y = (height - (screen_height / 2))
            if x < screen_width and x + width > 0 then
                love.graphics.draw(parallax[i], love.graphics
                    .newQuad(x, y, screen_width, screen_height, width * entity.scale, height * entity.scale), 0, -- x
                0, -- y
                0, -- rotation
                1, 1, -- scale_x, scale_y
                0, 0, -- origin_x, origin_y
                0, 0 -- shearing_x, shearing_y
                )
            end
            --[[love.graphics.draw(parallax[i],
        x - parallax[i]:getWidth(), -- x
        y, -- y
        0, -- rotation
        1, 1, -- scale_x, scale_y
        0, 0, -- origin_x, origin_y
        0, 0 -- shearing_x, shearing_y
      )
      love.graphics.draw(parallax[i],
        x + parallax[i]:getWidth(), -- x
        y, -- y
        0, -- rotation
        1, 1, -- scale_x, scale_y
        0, 0, -- origin_x, origin_y
        0, 0 -- shearing_x, shearing_y
         )]] --
        end
        love.graphics.draw(canvas,
            love.graphics.newQuad(camera.x - (love.graphics.getWidth() / 2), camera.y - (love.graphics.getHeight() / 2),
                screen_width, screen_height, canvas:getWidth() * entity.scale, canvas:getHeight() * entity.scale), 0, 0, -- x, y
            0, -- rotation
            1, 1, -- scale_x, scale_y
            0, 0, -- origin_x, origin_y
            0, 0 -- shearing_x, shearing_y
        )
    end

    -- canContain(arg)
    object.canContain = function(arg)
        local small = {
            top = arg.top,
            left = arg.left,
            bottom = arg.bottom,
            right = arg.right
        }
        local size = arg.size
        local big = {
            top = arg.top,
            left = arg.left,
            bottom = arg.top + size,
            right = arg.left + size
        }

        local max_i = size - (small.right - small.left) + 1
        local max_j = size - (small.bottom - small.top) + 1
        for i = 1, max_i do
            for j = 1, max_j do
                local fit = true
                for y = big.top, big.bottom do
                    for x = big.left, big.right do
                        if object.getTileProperties(x, y).solid then
                            fit = false
                        end
                    end
                end
                if fit == true then
                    return true
                end
                big.top = big.top + 1
                big.bottom = big.bottom + 1
            end
            big.top = big.top - size + 1
            big.bottom = big.bottom - size + 1
            big.left = big.left + 1
            big.right = big.right + 1
        end
    end

    object.reset = function()
        entity.clearAll()
        loadEntities(map, objectgroup)
        entity.scale = 1
    end

    object.prerender()

    return object
end

return M
