MOD = {}
MOD.name = "ArcadeMode"
MOD.if_name = "arcade_mode"
MOD.interfaces = {}
MOD.commands = {}
MOD.events = {}
-- MOD.config = require "control.config"

require "stdlib/utils/table"

--############################################################################--
--                                   LOGIC                                    --
--############################################################################--

local function init_force(force)
  global.limits = global.limits or {}
  global.charges = global.charges or {}

  global.limits[force] = global.limits[force] or {
    charges = 1,
    speed = {
      item = 1,
      fluid = 1
    }
  }
  global.charges[force] = global.charges[force] or 1

  return global.limits[force]
end

MOD.events.on_charges_changed = script.generate_event_name()
MOD.interfaces.charges_changed_id = function() return MOD.events.on_charges_changed end

MOD.events.on_charge_limit_changed = script.generate_event_name()
MOD.interfaces.charge_limit_changed_id = function() return MOD.events.on_charge_limit_changed end

local function get_charges(force)
  local charges = global.charges and global.charges[force]
  if not charges then
    init_force(force)
    return global.charges[force]
  else return charges end
end
MOD.interfaces.get_charges = get_charges

local function get_limits(force)
  local limits = global.limits and global.limits[force]
  if not limits then return table.deepcopy(init_force(force))
  else return table.deepcopy(limits) end
end
MOD.interfaces.get_limits = get_limits

-- Uses the amount of charges for a specific force
-- Negative amount frees charges
-- returns true if sucessful
local function use_charges(force, amount, simulate)
  amount = tonumber(amount)

  local previous = global.charges[force]
  if not previous then return false end

  local limits = global.limits[force]
  if not limits then limits = init_force(force) end

  local current = previous - amount
  if current < 0 then return false
  elseif simulate then return true end

  global.charges[force] = math.min(limits.charges, current)
  if current ~= previous then
    script.raise_event(MOD.events.on_charges_changed,
      {force = game.forces[force], previous_amount = previous, amount = current})
  end
  return true
end
MOD.interfaces.use_charges = use_charges

-- Sets the charges for a force to a new amount
-- is_relative (false by default) makes amount into a +/- quantity
local function set_charges_limit(force, amount, is_relative)
  amount = tonumber(amount)

  local limits = global.limits[force]
  if not limits then limits = init_force(force) end
  local previous_limit = limits.charges

  if is_relative then
    limits.charges = limits.charges + amount
  else
    limits.charges = amount
  end

  if previous_limit ~= limits.charges then
    script.raise_event(MOD.events.on_charge_limit_changed, {
      force = game.forces[force], previous_amount = previous_limit, amount = limits.charges
    })
  end

  local previous_charges = global.charges[force]
  local current_charges = previous_charges + (limits.charges - previous_limit)
  global.charges[force] = math.min(current_charges, limits.charges)
  if current_charges ~= previous_charges then
    script.raise_event(MOD.events.on_charges_changed,
      {force = game.forces[force], previous_amount = previous_charges, amount = current_charges})
  end
end
MOD.interfaces.set_charges = set_charges_limit

MOD.commands.arcmd_charges = function(event)
  local player = game.players[event.player_index]
  local number = tonumber(event.parameter)

  if number and player.admin then set_charges_limit(player.force, number)
  else player.print(get_charges(player.force)) end
end

--############################################################################--
--                                   EVENTS                                   --
--############################################################################--

local targets = require "scripts/targets/targets"
local sources = require "scripts/sources"
local gui_counter = require "scripts/gui-counter"
local gui_sources = require "scripts/gui-sources"
local gui_targets = require "scripts/gui-targets"


script.on_event(defines.events.on_research_finished, function(event)
  local force = event.research.force.name
  if not global.limits or not global.limits[force] then
    init_force(force)
  end
  if event.research.name:match("arcade_mode%-unlock") then
    set_charges_limit(force, math.max(global.limits[force].charges, event.research.level + 1))
  elseif event.research.name:match("arcade_mode%-upgrade") then
    global.limits[force].speed.item = math.max(global.limits[force].speed.item, event.research.level + 1)
  end
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
  if event.destination.name ~= "arcade_mode-source" then return end
  if event.source.name ~= "arcade_mode-source" then return end

  local player = game.players[event.player_index]
  local signal = sources.get(event.source).target

  if not sources.set_target(event.destination, player, signal) then
    player.surface.create_entity {
      name = "flying-text",
      position = player.position,
      text = {"status.arcade_mode-no-charges"},
      color = {r=1, g=0.5, b=0.5}
    }
    sources.refresh_display(event.destination)
  end
end)

script.on_event(defines.events.script_raised_built, sources.on_script_raised_built)

local function on_mined_entity(event)
  local entity = event.entity
  if entity.name ~= "arcade_mode-source" then return end
  sources.delete(entity)
end

script.on_event(defines.events.on_robot_mined_entity, on_mined_entity)
script.on_event(defines.events.on_player_mined_entity, on_mined_entity)

script.on_event(MOD.events.on_targets_changed, function(event)
  sources.on_targets_changed(event)

  game.print({"status.arcade_mode-on-targets-changed"}, {r=0.5, g=0.8, b=1})
end)

script.on_event(defines.events.on_force_created, function(event)
  init_force(event.force)
end)

--------------------------------------------------------------------------------
--                                    GUI                                     --
--------------------------------------------------------------------------------

script.on_event(defines.events.on_gui_opened, gui_sources.on_opened)

script.on_event(defines.events.on_gui_click, function(event)
  gui_counter.on_click(event)
  gui_sources.on_click(event)
  gui_targets.on_click(event)
end)

script.on_event(defines.events.on_gui_closed, function(event)
  gui_sources.on_closed(event)
  gui_targets.on_closed(event)
end)

script.on_event(defines.events.on_gui_elem_changed, gui_targets.on_elem_changed)

script.on_event(defines.events.on_player_changed_force, gui_counter.on_player_changed_force)

script.on_event(defines.events.on_player_created, gui_counter.on_player_created)

script.on_event(MOD.events.on_charge_limit_changed, gui_counter.on_charge_limit_changed)

script.on_event(MOD.events.on_charges_changed, gui_counter.on_charges_changed)

--############################################################################--
--                                 INTERFACES                                 --
--############################################################################--

script.on_init(function()
  for _, force in pairs(game.forces) do
    init_force(force)
  end

  targets.on_init()
  sources.on_init()
  gui_counter.on_init()
  gui_sources.on_init()
  gui_targets.on_init()
end)

script.on_configuration_changed(function()
  targets.on_configuration_changed()
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, targets.on_runtime_mod_setting_changed)

remote.add_interface(MOD.if_name, MOD.interfaces)
for name, command in pairs(MOD.commands) do
  commands.add_command(name, {"command-help."..name}, command)
end