local targets = require "scripts/targets/targets"

local gui = {}

gui.version = 1
gui.name = "arcade_mode-gui_targets"
gui.name_pattern = "arcade_mode%-gui_targets"

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

local function update_gui_define(player, override)
  local info = global.temp_targets[player.index]

  if override then
    for _, item in pairs(override.items) do
      table.insert(info.resources, {name = item.name, type="item"})
    end
    for _, fluid in pairs(override.fluids) do
      table.insert(info.resources, {name = fluid.name, type="fluid"})
    end
  end

  local name = gui.name.."-define"
  local resources_table = player.gui.center[name][name.."-resources"]
  resources_table.clear()

  for i, resource in ipairs(info.resources) do
    make_smart_slot(resources_table, name.."-filter-"..i, resource)
  end
  make_smart_slot(resources_table, name.."-filter-"..(#info.resources+1))

  player.gui.center[name][name.."-options"][name.."-reset"].enabled = not info.reset
end

local function reset_gui_define(player)
  global.temp_targets[player.index] = {
    resources = {},
    reset = true
  }

  update_gui_define(player, targets.get(true))
end

local function on_gui_define(player)
  if not(player and player.valid and player.admin) then return end

  local name = gui.name.."-define"
  if player.gui.center[name] then
    player.gui.center[name].destroy()
    global.open_sources[player.index] = nil
    return
  end

  global.temp_targets[player.index] = {
    resources = {},
    reset = global.custom_targets == nil
  }

  local define = player.gui.center.add {
    type = "frame",
    name = name,
    caption = {"gui-caption.arcade_mode-define"},
    direction = "vertical"
  }
  define.style.align = "center"

  define.add {
    type = "table",
    name = name.."-resources",
    column_count = 6,
    style = "slot_table"
  }

  local options = define.add {
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
  save.style.minimal_width = 32*5 + 2*5 - 3
  save.style.horizontally_stretchable = true
  save.style.horizontally_squashable = true

  update_gui_define(player, global.targets)
  player.opened = define
end

--############################################################################--
--                                   EVENTS                                   --
--############################################################################--

function gui.on_click(event)
  local player = game.players[event.player_index]
  if not(player and player.valid and player.admin) then return end

  local element = event.element
  if not(element.valid) then return end
  if element.name == "arcade_mode-gui_sources-pick-define" then
    -- gui-sources opens this gui remotely
    -- TODO: find a better way. event?
    on_gui_define(player)
    return
  end
  if not element.name:match(gui.name_pattern) then return end

  local info = global.temp_targets[player.index]

  if element.name:match("%-define%-reset$") then
    reset_gui_define(player)
  elseif element.name:match("%-define%-save$") then
    if info.reset then targets.set_custom_targets()
    else targets.set_custom_targets(info.resources) end
    update_gui_define(player)
  end
end

function gui.on_elem_changed(event)
  local player = game.players[event.player_index]
  if not(player and player.valid) then return end

  local element = event.element
  if not element.valid then return end
  local index = tonumber(element.name:match(gui.name_pattern.."%-define%-filter%-(%d+)$"))
  if not index then return end

  local info = global.temp_targets[player.index]
  if not element.elem_value then
    -- cleared a slot
    -- local elem = element
    -- for i = index, #info.resources do
    --   local new_elem = element.parent[gui.name.."-define-filter-"..(i+1)]
    --   elem.elem_value = new_elem.elem_value
    --   elem = new_elem
    -- end

    table.remove(info.resources, index)
    -- elem.destroy()
    info.reset = false
  else
    -- set a slot
    if element.elem_value.type ~= "item" and element.elem_value.type ~= "fluid" then
      -- invalid signal, revert to previous value
      -- element.elem_value = info.resources[index]
    else
      info.resources[index] = element.elem_value
      -- if index >= #info.resources then
      --   -- last slot, add an extra one
      --   make_smart_slot(element.parent, gui.name.."-define-filter-"..(#info.resources+1))
      -- end
      info.reset = false
    end
  end

  update_gui_define(player)
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

MOD.commands.arcmd_set_targets = function(event)
  on_gui_define(game.players[event.player_index])
end

return gui