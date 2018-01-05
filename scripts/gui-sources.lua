local targets = require "scripts/targets/targets"
local sources = require "scripts/sources"

local gui = {}

-- gui.version = 1
gui.name = "arcade_mode-gui_sources"
gui.name_pattern = "arcade_mode%-gui_sources"

--############################################################################--
--                                    PICK                                    --
--############################################################################--

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

local function on_gui_pick(source, player)
  local counter = global.charges[source.base.force.name]

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
    global.open_sources[player.index] = nil
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

  for _, item in pairs(global.targets.items) do
    make_smart_slot(resources, name.."-select-item/"..item.name, {name = item.name, type="item"}, "recipe_slot_button")
  end
  for _, fluid in pairs(global.targets.fluids) do
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
  define.style.visible = player.admin

  player.opened = pick
end


local function get_counter_info(source, player)
  if player.cheat_mode then return "∞", "bold_blue_label" end

  local counter = global.charges[source.base.force.name]
  if counter <= 0 then return counter, "bold_red_label"
  else return counter, "caption_label" end
end

--############################################################################--
--                                    MAIN                                    --
--############################################################################--

local function update_gui_main(source, player)
  local name = gui.name.."-main"
  local main = player.gui.center[name]
  if not main then return end

  main.caption = (source.free and {"entity-name.arcade_mode-source_free"}) or {"entity-name.arcade_mode-source"}

  local counter = main[name.."-flow"][name.."-settings"][name.."-counter"]
  local counter_n, counter_style = get_counter_info(source, player)

  counter.caption = {"gui-caption.arcade_mode-main-counter", counter_n}
  counter.style = counter_style

  local type = source.target.signal.type
  local rate = main[name.."-flow"][name.."-settings"][name.."-rate"]
  rate[name.."-rate-info"].elem_value = (type and {
    type = "item",
    name = targets.get_proxy(type, source.target.count)
  })
  rate[name.."-rate-minus"].enabled = source.target.count > 1
  rate[name.."-rate-plus"].enabled = type and
    (source.target.count < global.limits[source.base.force.name].speed[type])
end

local function on_gui_main(source, player)
  local name = gui.name.."-main"
  if player.gui.center[name] then
    player.gui.center[name].destroy()
    global.open_sources[player.index] = nil
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
    tooltip = {"gui-caption.arcade_mode-main-target-reset"}
  }

  ---------------------------------------- SETTINGS-RATE

  local rate = settings.add {
    type = "table",
    name = name.."-rate",
    column_count = 3,
  }
  rate.style.horizontal_spacing = 0

  local rate_minus = rate.add {
    type = "button",
    name = name.."-rate-minus",
    caption = "-",
    style = "mod_gui_button"
  }
  rate_minus.style.minimal_width = 18
  rate_minus.style.font = "default-large-semibold"

  make_smart_slot(rate, name.."-rate-info", {type = "item"})

  local rate_plus = rate.add {
    type = "button",
    name = name.."-rate-plus",
    caption = "+",
    style = "mod_gui_button"
  }
  rate_plus.style.minimal_width = 18
  rate_plus.style.font = "default-large-semibold"

  ----------------------------------------

  update_gui_main(source, player)
  player.opened = main
end

--############################################################################--
--                                   EVENTS                                   --
--############################################################################--

function gui.on_opened(entity, player)
  if not (player and player.valid) then return end

  local source = sources.get(entity)
  global.open_sources[player.index] = source.base

  if not source.target.signal then
    on_gui_pick(source, player)
  else
    on_gui_main(source, player)
  end
end

function gui.on_click(event)
  local player = game.players[event.player_index]

  if not(player and player.valid) then return end

  local element = event.element
  if not(element.valid and element.name:match(gui.name_pattern)) then return end

  local entity = global.open_sources[player.index]
  if not(entity and entity.valid) then
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
      on_gui_main(source, player)
    end
    return
  end

  if element.name:match("%-main%-target%-reset$") then
    sources.set_target(entity)
    on_gui_pick(source, player)
  elseif element.name:match("%-main%-rate%-minus$") then
    sources.set_target(entity, player, {
      signal = source.target.signal,
      count = source.target.count - 1
    }, player)
    update_gui_main(source, player)
  elseif element.name:match("%-main%-rate%-plus$") then
    sources.set_target(entity, player, {
      signal = source.target.signal,
      count = source.target.count + 1
    })
    update_gui_main(source, player)
  end
end

function gui.on_closed(event)
  local element = event.element
  if not(element and element.valid and element.name:match(gui.name_pattern)) then return end
  element.destroy()
end

---------------------------------------------------

function gui.on_init()
  global.open_sources = {}
end

function gui.on_configuration_changed()
end

return gui