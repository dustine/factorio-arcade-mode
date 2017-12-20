-- local Area = require('stdlib/area/area')

local recipes = require("scripts/recipes/recipes")
local mod_gui = require("mod-gui")
local sources = {}

--############################################################################--
--                                    INFO                                    --
--############################################################################--

function sources.on_resources_changed()
  -- reset the resources up to recipe's autogen
  if not global.custom_resources then
    global.items, global.fluids = recipes.get_default_resources()
    return
  end
end

--------------------------------------------------------------------------------

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
    name = recipes.get_proxy("item", target.count),
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

function sources.refresh_display(entity)
  refresh_display(sources.get(entity))
end

--############################################################################--
--                                    GUI                                     --
--############################################################################--

require "mod-gui"
sources.gui = {}
local gui = sources.gui

gui.version = 1
gui.name = "arcade_mode-gui_source"
gui.name_pattern = "arcade_mode%-gui_source"

function gui.on_init()
  global.sources.open = {}
end

function gui.on_configuration_changed()
end

--------------------------------------------------------------------------------

local function make_smart_slot(parent, name, signal, style)
  local rate = parent.add {
    type = "choose-elem-button",
    name = name,
    elem_type = "signal",
    style = style or "slot_button",
  }
  rate.locked = true
  rate.elem_value = signal
end

function gui.on_source_pick(source, player)
  local counter = global.limits[source.base.force.name].counter

  if not(player.cheat_mode) and counter <= 0 then
    player.surface.create_entity {
      name = "flying-text",
      position = player.position,
      text = {"status.arcade_mode-no-charges"},
      color = {r=1, g=0.5, b=0.5}
    }

    player.opened = nil
    return
  end

  local name = gui.name.."-pick"
  if player.gui.center[name] then
    player.gui.center[name].destroy()
    global.sources.open[player.index] = nil
    return
  end

  --[[ GUI ]]

  local pick = player.gui.center.add {
    type = "frame",
    name = name,
    caption = {"gui-caption.arcade_mode-pick"},
    direction = "vertical"
  }

  local resources = pick.add {
    type = "table",
    name = name.."-resources",
    column_count = 6,
    style = "slot_table"
  }

  for _, item in pairs(global.items) do
    make_smart_slot(resources, name.."-select-item/"..item.name, {name = item.name, type="item"}, "recipe_slot_button")
  end
  for i, fluid in pairs(global.fluids) do
    make_smart_slot(resources, name.."-select-fluid/"..fluid.name, {name = fluid.name, type="fluid"}, "recipe_slot_button")
  end

  local define = pick.add {
    type = "button",
    name = name.."-define",
    caption = {"gui-caption.arcade_mode-pick-define"},
    style = "slot_with_filter_button"
  }
  define.style.minimal_width = 32*6+2*5
  define.style.horizontally_stretchable = true
  define.style.horizontally_squashable = true

  player.opened = pick
end


local function get_counter_info(player)
  if player.cheat_mode then return "∞", "bold_blue_label" end

  local counter = global.limits[player.force.name].counter
  if counter <= 0 then return counter, "bold_red_label"
  else return counter, "caption_label" end
end

function gui.update_source_main(source, player)
  local name = gui.name.."-main"
  local main = player.gui.center[name]
  if not main then return end

  main.caption = (source.free and {"entity-name.arcade_mode-source_free"}) or{"entity-name.arcade_mode-source"}

  local counter = main[name.."-flow"][name.."-settings"][name.."-counter"]
  local counter_n, counter_style = get_counter_info(player)

  counter.caption = {"gui-caption.arcade_mode-main-counter", counter_n}
  counter.style = counter_style

  local type = source.target.signal.type
  local rate = main[name.."-flow"][name.."-settings"][name.."-rate"]
  rate[name.."-rate-info"].elem_value = (type and {
    type = "item",
    name = recipes.get_proxy(type, source.target.count)
  })
  rate[name.."-rate-minus"].enabled = source.target.count > 1
  rate[name.."-rate-plus"].enabled = type and (source.target.count < global.limits[player.force.name].speed[type])
end

function gui.on_source_main(source, player)
  local name = gui.name.."-main"
  if player.gui.center[name] then
    player.gui.center[name].destroy()
    global.sources.open[player.index] = nil
    return
  end

  local signal = source.base.get_control_behavior().get_signal(1)

  --[[ GUI ]]

  local main = player.gui.center.add {
    type = "frame",
    name = name,
    caption = (source.free and {"entity-name.arcade_mode-source_free"}) or{"entity-name.arcade_mode-source"},
    direction = "vertical"
  }

  local flow = main.add {
    type = "flow",
    name = name.."-flow",
    direction = "horizontal"
  }

  local camera = flow.add {
    type = "camera",
    name = name.."-camera",
    position = source.base.position
  }
  camera.style.width = 100
  camera.style.height = 100

  ---------------------------------------- SETTINGS

  local settings = flow.add {
    type = "flow",
    name = name.."-settings",
    direction = "vertical",
  }

  settings.add {
    type = "label",
    name = name.."-counter",
    caption = {"gui-caption.arcade_mode-main-counter", "?"},
  }

  ---------------------------------------- SETTINGS-TARGET

  local target = settings.add {
    type = "table",
    name = name.."-target",
    column_count = 2,
    style = "slot_table"
  }
  -- target.style.top_padding = 5

  make_smart_slot(target, name.."-target-info", signal.signal)

  target.add {
    type = "sprite-button",
    name = name.."-target-reset",
    sprite = "utility/reset",
    style = "slot_button",
  }

  ---------------------------------------- SETTINGS-RATE

  local rate = settings.add {
    type = "table",
    name = name.."-rate",
    column_count = 3,
  }
  rate.style.horizontal_spacing = 0
  -- rate.style.top_padding = 5

  local rate_minus = rate.add {
    type = "button",
    name = name.."-rate-minus",
    caption = "-",
    style = mod_gui.button_style
  }
  rate_minus.style.minimal_width = 18
  rate_minus.style.font = "default-large-semibold"

  make_smart_slot(rate, name.."-rate-info", {type = "item"})

  local rate_plus = rate.add {
    type = "button",
    name = name.."-rate-plus",
    caption = "+",
    style = mod_gui.button_style
  }
  rate_plus.style.minimal_width = 18
  rate_plus.style.font = "default-large-semibold"

  ----------------------------------------

  gui.update_source_main(source, player)
  player.opened = main
end



function gui.on_source_opened(entity, player)
  if not (player and player.valid) then return end

  local source = sources.get(entity)
  global.sources.open[player.index] = source.base

  if not source.target.signal then
    gui.on_source_pick(source, player)
  else
    gui.on_source_main(source, player)
  end
end

function gui.on_click(event)
  local element = event.element
  if not element.valid then return end
  if not element.name:match(gui.name_pattern) then return end

  local player = game.players[event.player_index]

  local entity = global.sources.open[player.index]
  if not entity or not entity.valid then
    player.opened.destroy()
    return
  end
  local source = sources.get(entity)

  local match = element.name:match("%-pick%-select%-([^%-]*/.+)$")
  if match then
    if sources.set_target(entity, player, {
      count = 1,
      signal = {
        type = match:match("^(.+)/"),
        name = match:match("/(.+)$")
    }}) then
      gui.on_source_main(source, player)
    end
    return
  end

  if element.name:match("%-main%-target%-reset$") then
    sources.set_target(entity)
    gui.on_source_pick(source, player)
  elseif element.name:match("%-main%-rate%-minus$") then
    sources.set_target(entity, player, {
      signal = source.target.signal,
      count = source.target.count - 1
    }, player)
    gui.update_source_main(source, player)
  elseif element.name:match("%-main%-rate%-plus$") then
    sources.set_target(entity, player, {
      signal = source.target.signal,
      count = source.target.count + 1
    })
    gui.update_source_main(source, player)
  end
end

function gui.on_closed(event)
  local element = event.element
  if not element or not element.name:match("arcade_mode%-gui_source") then return end
  -- local player = game.players[event.player_index]
  -- local source = source = global.sources[global.sources.open[player.index]]
  -- local source_info = sources.get_source(source)

  local name = element.name

  if name:match("arcade_mode%-gui_source") then
    element.destroy()

    -- if name:match("%-pick$") and source_info.target.signal then
    --   gui.on_source_main(source, player)
    -- end
  end
end

--############################################################################--
--                                   EVENTS                                   --
--############################################################################--

function sources.on_init()
  global.sources = {}
  sources.on_resources_changed()

  gui.on_init()
end

function sources.on_configuration_changed(event)
  sources.on_resources_changed()

  gui.on_configuration_changed(event)
end

return sources