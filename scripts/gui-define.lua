local targets = require "scripts/targets/targets"

local gui = {}

-- gui.version = 1
gui.name = "arcade_mode-gui_define"
gui.name_pattern = "arcade_mode%-gui_define"

-- TODO: refactor this to common as both gui files use this
local function make_smart_slot(parent, name, signal, style)
  local rate = parent.add {
    type = "choose-elem-button",
    name = name,
    elem_type = "signal",
    style = style or "slot_button",
  }
  -- rate.locked = true
  rate.elem_value = signal
end

local function update_gui(player, override)
  local info = global.temp_targets[player.index]

  if override then
    info.resources = {}
    for _, item in pairs(override.items) do
      table.insert(info.resources, {name = item.name, type="item"})
    end
    for _, fluid in pairs(override.fluids) do
      table.insert(info.resources, {name = fluid.name, type="fluid"})
    end
  end

  local name = gui.name
  local resources_table = player.gui.center[name][name.."-resources"]
  resources_table.clear()

  for i, resource in ipairs(info.resources) do
    make_smart_slot(resources_table, name.."-filter-"..i, resource)
  end
  make_smart_slot(resources_table, name.."-filter-"..(#info.resources+1))

  player.gui.center[name][name.."-options"][name.."-reset"].enabled = not info.reset
end

local function reset_gui(player)
  global.temp_targets[player.index] = {
    resources = {},
    reset = true
  }

  update_gui(player, targets.get(true))
end

local function on_gui(player)
  if not(player and player.valid and player.admin) then return end

  local name = gui.name
  if player.gui.center[name] then
    player.gui.center[name].destroy()
    global.open_sources[player.index] = nil
    return
  end

  global.temp_targets[player.index] = {
    resources = {},
    reset = global.custom_targets == nil
  }

  local main = player.gui.center.add {
    type = "frame",
    name = name,
    caption = {"gui-caption.arcade_mode-define"},
    direction = "vertical"
  }
  main.style.align = "center"

  main.add {
    type = "table",
    name = name.."-resources",
    column_count = 6,
    style = "slot_table"
  }

  local options = main.add {
    type = "table",
    name = name.."-options",
    column_count = 2
  }
  options.style.align = "right"
  options.style.horizontally_stretchable = true

  options.add {
    type = "sprite-button",
    name = name.."-reset",
    tooltip = {"gui-caption.arcade_mode-define-reset"},
    sprite = "utility/reset",
    style = "not_available_slot_button"
  }

  local save = options.add {
    type = "button",
    name = name.."-save",
    caption = {"gui-caption.arcade_mode-define-save"},
    style = "slot_with_filter_button"
  }
  save.style.width = 36*5 + 2*4
  save.style.horizontally_stretchable = true
  save.style.horizontally_squashable = true

  update_gui(player, global.targets)
  player.opened = main
end

--############################################################################--
--                                   EVENTS                                   --
--############################################################################--

function gui.on_click(event)
  local player = game.players[event.player_index]
  if not(player and player.valid and player.admin) then return end

  local element = event.element
  if not(element.valid) then return end
  -- if element.name == "arcade_mode-gui_sources-pick-define" then
  --   -- gui-sources opens this gui remotely
  --   -- TODO: find a better way. event?
  --   on_gui(player)
  --   return
  -- end
  if not element.name:match(gui.name_pattern) then return end

  local info = global.temp_targets[player.index]

  if element.name:match("%-reset$") then
    reset_gui(player)
  elseif element.name:match("%-save$") then
    if info.reset then targets.set_custom_targets()
    else targets.set_custom_targets(info.resources) end
    update_gui(player, targets.get())
  end
end

function gui.on_elem_changed(event)
  local player = game.players[event.player_index]
  if not(player and player.valid) then return end

  local element = event.element
  if not element.valid then return end
  local index = tonumber(element.name:match(gui.name_pattern.."%-filter%-(%d+)$"))
  if not index then return end

  local info = global.temp_targets[player.index]
  if not element.elem_value then
    table.remove(info.resources, index)
    info.reset = false
  else
    -- set a slot
    if not(element.elem_value.type == "item" or element.elem_value.type == "fluid") then
      info.resources[index] = element.elem_value
      info.reset = false
    end
  end

  update_gui(player)
end

function gui.on_closed(event)
  local element = event.element
  if not (element and element.valid and element.name:match(gui.name_pattern)) then return end
  element.destroy()
end

---------------------------------------------------

function gui.on_init()
  global.temp_targets = {}
end

function gui.on_configuration_changed()
end

MOD.commands.arcmd_define = function(event)
  on_gui(game.players[event.player_index])
end

return gui