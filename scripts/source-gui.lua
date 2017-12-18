
local sources = require "sources"
require "mod-gui"

local source_gui = {}

local gui = {}
gui.version = 1
gui.name = "arcade_mode-gui_source"
gui.name_pattern = "arcade_mode%-gui_source"

function source_gui.on_configuration_changed(event)
end

-------------------------------------------------------------------------------

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

function source_gui.on_init()
  if global.source_gui ~= nil then return end
  global.source_gui = {}
  global.source_gui.version = gui.version

  global.source_gui.source = {}
end



function source_gui.on_source_pick(source, player)
  log("pick")
  local counter = global.counter[source.force.name]

  if counter <= 0 then
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
    global.source_gui.source[player.index] = nil
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



function source_gui.on_source_main(source, player)
  local name = gui.name.."-main"
  if player.gui.center[name] then
    player.gui.center[name].destroy()
    global.source_gui.source[player.index] = nil
    return
  end

  local counter = global.counter[source.force.name]
  local signal = source.get_control_behavior().get_signal(1)

  --[[ GUI ]]

  local main = player.gui.center.add {
    type = "frame",
    name = name,
    caption = {"entity-name.arcade_mode-source"},
    direction = "vertical"
  }

  main.add {
    type = "label",
    name = name.."-counter",
    caption = {"gui-caption.arcade_mode-main-counter", counter},
    style = (counter <= 0 and "bold_red_label") or "caption_label"
  }

  local main_frame = main.add {
    type = "flow",
    name = name.."-flow",
    direction = "horizontal"
  }

  local camera = main_frame.add {
    type = "camera",
    name = name.."-camera",
    position = source.position
  }
  camera.style.width = 100
  camera.style.height = 100

  local settings = main_frame.add {
    type = "table",
    name = name.."-settings",
    column_count = 2,
    style = "slot_table"
  }
  settings.style.vertical_spacing = 5

  make_smart_slot(settings, name.."-target", signal.signal)

  settings.add {
    type = "sprite-button",
    name = name.."-target-reset",
    sprite = "utility/reset",
    style = "slot_button",
  }

  make_smart_slot(settings, name.."-rate", {type = "item", name = "transport-belt"})

  local rate_adjust = settings.add {
    type = "table",
    name = name.."-rate-adjust",
    column_count = 2,
  }
  rate_adjust.style.horizontal_spacing = 0

  rate_adjust.add {
    type = "button",
    name = name.."-rate-minus",
    caption = "-",
    style = mod_gui.button_style
  }
  rate_adjust.add {
    type = "button",
    name = name.."-rate-plus",
    caption = "+",
    style = mod_gui.button_style
  }

  player.opened = main
end



function source_gui.on_source_opened(source, player)
  if not (player and player.valid) then return end

  log("source opened")

  global.source_gui.source[player.index] = source
  local source_info = sources.get_source(source)

  if not source_info.target.signal then
    source_gui.on_source_pick(source, player)
  else
    source_gui.on_source_main(source, player)
  end
end

function source_gui.on_gui_click(event)
  local element = event.element
  if not element.valid then return end
  if not element.name:match(gui.name_pattern) then return end

  local player = game.players[event.player_index]
  local source = global.source_gui.source[player.index]
  if not source or not source.valid then return end

  local match = element.name:match("%-pick%-select%-([^%-]*/.+)$")
  if match then
    log("pick select")
    if sources.set_target(source, {
      count = 1,
      signal = {
        type = match:match("^(.+)/"),
        name = match:match("/(.+)$")
    }}) then
      source_gui.on_source_main(source, player)
    end
    return
  end

  if element.name:match("%-target%-reset$") then
    sources.set_target(source)
    source_gui.on_source_pick(source, player)
    return
  end
end

function source_gui.on_gui_closed(event)
  local element = event.element
  if not element or not element.name:match("arcade_mode%-gui_source") then return end
  local player = game.players[event.player_index]
  local source = global.source_gui.source[player.index]
  local source_info = sources.get_source(source)

  local name = element.name
  log("delete "..name)

  if name:match("arcade_mode%-gui_source") then
    element.destroy()

    -- if name:match("%-pick$") and source_info.target.signal then
    --   source_gui.on_source_main(source, player)
    -- end
  end
end

return source_gui