local Area = require('stdlib/area/area')

local recipes = require("scripts/recipes/recipes")

local sources = {}

local function off()
  return {
    count = 0
  }
end

function sources.on_resources_changed()
  -- reset the resources up to recipe's autogen
  if not global.custom_resources then
    global.items, global.fluids = recipes.get_default_resources()
    return
  end
end

function sources.on_init()
  global.sources = {}

  sources.on_resources_changed()
end


function sources.on_configuration_changed(event)
  sources.on_resources_changed()
end

--------------------------------------------------------------------------------

local function offset_pos(entity, offset)
  return {entity.position.x - offset, entity.position.y}
end

function sources.finish_source(entity)
  local surface = entity.surface
  local force = entity.force

  local container = surface.create_entity {
    name = "arcade_mode-source_item-container",
    position = offset_pos(entity, 2),
    force = force,
  }
  container.remove_unfiltered_items = true
  container.destructible = false
  entity.destructible = false

  global.sources[entity.unit_number] = {
    base = entity,
    container = container,
    target = off(),
  }
end

function sources.get_source(entity)
  if not global.sources[entity.unit_number] then
    sources.finish_source(entity)
  end
  return global.sources[entity.unit_number]
end


function sources.delete(entity)
  local source = sources.get_source(entity)

  if source.pump then source.pump.destroy() end
  if source.loader then source.loader.destroy() end
  if source.belt then source.belt.destroy() end

  if source.container then source.container.destroy() end
  global.sources[source.base.unit_number] = nil
end

local function reset(source)
  source.container.set_infinity_filter(1, nil)
  if source.pump then source.pump.destroy(); source.pump = nil end
  if source.loader then source.loader.destroy(); source.loader = nil end
  if source.belt then source.belt.destroy(); source.belt = nil end
  for _, e in pairs(source.base.surface.find_entities_filtered {
    type = "item-entity",
    area = source.base.bounding_box
  }) do
    e.destroy()
  end

  global.counter[source.base.force.name] = global.counter[source.base.force.name] + source.target.count
  source.target = off()
end




local function get_cost(source, target)
  local old = (source.target and source.target.count) or 0
  local new = (target and target.count) or 0
  return new - old
end

local function set_item(source, target)
  source.container.set_infinity_filter(1, {
    name = target.signal.name,
    count = 10,
    index = 1,
  })
  local loader = source.base.surface.create_entity {
    name = "arcade_mode-source_item-loader-"..target.count,
    position = offset_pos(source.base, 0),
    force = source.base.force,
    direction = defines.direction.east,
    fast_replace = true,
    type = "output"
  }
  loader.destructible = false
  source.loader = loader

  local belt = source.base.surface.create_entity {
    name = recipes.get_belt(target.count),
    position = offset_pos(source.base, -1),
    force = source.base.force,
    direction = defines.direction.east,
    fast_replace = true,
    -- type = "output"
  }
  belt.destructible = false
  source.belt = belt

  local cost = get_cost(source, target)

  source.target = target
  global.counter[source.base.force.name] = global.counter[source.base.force.name] - cost
end

local function set_fluid(source, target)
  local pump = source.base.surface.create_entity {
    name = "arcade_mode-source_fluid-".. target.signal.name,
    position = offset_pos(source.base, 2),
    force = source.base.force,
  }
  pump.destructible = false
  source.pump = pump

  pump.fluidbox[1] = {
    name = target.signal.name,
    amount = pump.fluidbox.get_capacity(1),
  }

  local cost = get_cost(source, target)
  source.target = target
  global.counter[source.base.force.name] = global.counter[source.base.force.name] - cost
end



local function refresh_display(source)
  local control = source.base.get_or_create_control_behavior()
  control.set_signal(1, (source.target.signal and source.target) or nil)
end



function sources.set_target(entity, target)
  local source = global.sources[entity.unit_number]

  if get_cost(source, target) > global.counter[source.base.force.name] then return false end

  reset(source)

  if not target then refresh_display(source); return end

  -- set type
  if target.signal and target.signal.type == "item" then
    set_item(source, target)
  elseif target.signal and target.signal.type == "fluid" then
    set_fluid(source, target)
  end

  refresh_display(source)
  return true
end

return sources