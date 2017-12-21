-- local Area = require('stdlib/area/area')

local resources = require("scripts/resources/resources")

local sources = {}

--############################################################################--
--                                   LOGIC                                    --
--############################################################################--

local function signal_off()
  return {
    count = 0
  }
end

local function offset_pos(entity, offset)
  return {entity.position.x - offset, entity.position.y}
end

function sources.finish(entity)
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
    target = signal_off(),
  }
end

function sources.get(entity)
  if not global.sources[entity.unit_number] then
    sources.finish(entity)
  end
  return global.sources[entity.unit_number]
end

function sources.delete(entity)
  local source = sources.get_source(entity)

  if source.pump then source.pump.destroy() end
  if source.loader then source.loader.destroy() end
  if source.belt then source.belt.destroy() end
  for _, e in pairs(source.base.surface.find_entities_filtered {
    type = "item-entity",
    area = source.base.bounding_box
  }) do
    e.destroy()
  end

  if source.container then source.container.destroy() end
  global.sources[source.base.unit_number] = nil
end

local function get_cost(source, target)
  if source.free then return 0 end
  return ((target and target.count) or 0) - ((source.target and source.target.count) or 0)
end

local function set_cost(source, target)
  local limit = global.limits[source.base.force.name]
  limit.counter = limit.counter - get_cost(source, target)
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

  set_cost(source)
  source.free = nil
  source.target = signal_off()
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
  loader.rotatable = false
  loader.operable = false
  source.loader = loader

  local belt = source.base.surface.create_entity {
    name = resources.get_proxy("item", target.count),
    position = offset_pos(source.base, -1),
    force = source.base.force,
    direction = defines.direction.east,
    fast_replace = true,
    spill = false,
  }
  belt.destructible = false
  belt.rotatable = false
  belt.operable = false
  belt.minable = false
  source.belt = belt

  set_cost(source, target)
  source.target = target
end

local function set_fluid(source, target)
  if source.pump then source.pump.destroy(); source.pump = nil end

  local pump = source.base.surface.create_entity {
    name = "arcade_mode-source_fluid-".. target.signal.name,
    position = offset_pos(source.base, 2),
    force = source.base.force,
  }
  pump.destructible = false
  source.pump = pump

  -- cap pump so it starts full
  pump.fluidbox[1] = {
    name = target.signal.name,
    amount = pump.fluidbox.get_capacity(1),
  }

  set_cost(source, target)
  source.target = target
end

local function refresh_display(source)
  local control = source.base.get_or_create_control_behavior()
  control.set_signal(1, (source.target.signal and source.target) or nil)
end

function sources.refresh_display(entity)
  refresh_display(sources.get(entity))
end

function sources.set_target(entity, player, target)
  local source = global.sources[entity.unit_number]

  if not(player and player.cheat_mode) and get_cost(source, target) > global.limits[source.base.force.name].counter then return false end

  reset(source)

  if target and target.signal then
    source.free = player.cheat_mode

    -- set type
    if target.signal.type == "item" then
      set_item(source, target)
    elseif target.signal.type == "fluid" then
      set_fluid(source, target)
    end
  end

  refresh_display(source)
  return true
end

--############################################################################--
--                                   EVENTS                                   --
--############################################################################--

function sources.on_resources_changed()
  -- reset the resources up to recipe's autogen
  if not global.custom_resources then
    global.items, global.fluids = resources.get_default_resources()
    return
  end
end

function sources.on_init()
  global.sources = {}
  sources.on_resources_changed()
end

function sources.on_configuration_changed()
  sources.on_resources_changed()
end

return sources