-- main.lua

local sandbox = require "sandbox"

local gauge = {}
gauge.event = require "event"
gauge.entity = require "entity"
gauge.input = require "input"
gauge.state = require "state"
gauge.map = require "map"
gauge.music = require "music"

local tween = require "tween"

local errorMessage = nil

-- celiaTheme = gauge.music.new({file="game/carefulwiththatcakecelia.ogg", volume=1, loop=true})
--littleTheme.play()
--bigTheme.play()
-- celiaTheme.play()

love.load = function ()
  local context = gauge.input.context.new({active = true})
  context.map = function (raw_in, map_in)
    if raw_in.key.pressed["escape"] then
      map_in.actions["quit"] = true
    end
    return map_in
  end
  gauge.event.subscribe("input",
    function (input)
      if input.actions.quit then
        os.exit(0)
      end
    end
  )

  local modes = love.window.getFullscreenModes()
  table.sort(modes, function(a, b)
      return a.width * a.height > b.width * b.height
  end)
  
  local native_mode = modes[1]
  love.window.setMode(1024, 768, { fullscreen = false })
  

  local game_state = gauge.state.new()
  gauge.event.subscribe("loadMap", function (arg)
    local info = love.filesystem.getInfo(arg.file)
    if info then
      game_state.map = gauge.map.new({
        data = love.filesystem.load(arg.file)
      })
      gauge.event.notify("input", {
        actions = {reset = true},
        states = {},
        ranges = {}
      })
    else
      gauge.event.notify("input", {
        actions = {quit = true},
        states = {},
        ranges = {}
      })
    end
  end)
  game_state.render = function ()
    love.graphics.push()
    -- love.graphics.scale(game_state.camera.scale)
    if game_state.map then
      game_state.map.render()
    end
    love.graphics.translate(
      (love.graphics.getWidth() / 2) - game_state.camera.position.x,
      (love.graphics.getHeight() / 2) - game_state.camera.position.y)
    gauge.entity.render()
    love.graphics.pop()
  end
  game_state.update = function (dt)
    gauge.entity.update(dt)
  end
  game_state.map = nil
  game_state.camera = {
    position = {
      x = 0,
      y = 0
    },
    speed = 0.05,
    max_distance = 150,
    scale = 1,
    zoom = false
  }
  gauge.state.push(game_state)

  local untrusted_code = assert(love.filesystem.load("game/main.lua"))
  local trusted_code = sandbox.new(untrusted_code, {gauge=gauge, math=math, print=print, tween=tween, love=love})
  local success, err = pcall(trusted_code)

  if not success then
    errorMessage = err
  end
  
end

love.update = function (dt)
  if dt > 1/60 then dt = 1/60 end

  local input = gauge.input.update(dt)
  if input then
    gauge.event.notify("input", input)
  end
  
  if dt > 0 then
    tween.update(dt)
  end
  gauge.state.get().update(dt)
end

local function printTable(tbl, x, y)
  local lineHeight = 20
  for k, v in pairs(tbl) do
      love.graphics.print(k .. ": " .. tostring(v), x, y)
      y = y + lineHeight
  end
end

love.draw = function ()
  local state = gauge.state.get()
  -- printTable(state, 100, 100)

  if errorMessage then
    -- Display the error message
    love.graphics.setColor(1, 0, 0) -- Red text
    love.graphics.printf("Error: " .. errorMessage, 10, 10, love.graphics.getWidth() - 20)
  end

  gauge.state.get().render()
end

love.keypressed = function (key, unicode)
  gauge.input.keyPressed(key)
end

love.keyreleased = function (key, unicode)
  gauge.input.keyReleased(key)
end

love.joystickpressed = function (joystick, button)
  gauge.input.joystickPressed(joystick, button)
end

love.joystickreleased = function (joystick, button)
  gauge.input.joystickReleased(joystick, button)
end

love.focus = function (f)

end

love.quit = function ()

end
