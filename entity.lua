-- entity.lua
local M = {}

local manager = {
  entities = {}
}

M.new = function (arg)
  local self = arg
  
  local object = {}
  object.falling = true
  object.render = function ()
    love.graphics.setColor({0,255,0})
    love.graphics.circle("fill", self.position.x, self.position.y, 16, 16)
  end
  object.update = function (dt)
    self.velocity.x = self.velocity.x + dt*self.acceleration.x
    self.velocity.y = self.velocity.y + dt*self.acceleration.y
    self.position.x = self.position.x + dt*self.velocity.x
    self.position.y = self.position.y + dt*self.velocity.y
    local map = gauge.state.get().map
    if map then
      local tile_indices = map.worldToLocal(self.position)
      if map.getTileProperties(tile_indices).solid == true then
        self.position.y = map.getTileBounds(tile_indices).top
        self.velocity.y = 0
        self.acceleration.y = 0
        object.falling = false
      end
    end
  end
  object.position = function (arg)
    self.position.x = arg.x or self.position.x
    self.position.y = arg.y or self.position.y
    return self.position
  end
  object.velocity = function (arg)
    self.velocity.x = arg.x or self.velocity.x
    self.velocity.y = arg.y or self.velocity.y
    return self.velocity
  end
  object.acceleration = function (arg)
    self.acceleration.x = arg.x or self.acceleration.x
    self.acceleration.y = arg.y or self.acceleration.y
    return self.acceleration
  end
  object.bearing = function ()
    local hypotenuse = math.sqrt( math.pow(self.velocity.x,2) + math.pow(self.velocity.y,2) )
    return math.acos( self.velocity.x/hypotenuse )
  end
  table.insert(manager.entities, object)
  
  return object
end

M.render = function ()
  for _,entity in ipairs(manager.entities) do
    entity.render()
  end
end

M.update = function (dt)
  for _,entity in ipairs(manager.entities) do
    entity.update(dt)
  end
end





return M
