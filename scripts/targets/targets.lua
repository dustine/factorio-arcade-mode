require 'stdlib/utils/string'

local targets = {}
local vanilla = require "vanilla"

MOD.events.on_targets_changed = script.generate_event_name()

--############################################################################--
--                                   LOGIC                                    --
--############################################################################--

local function sort_prototype(lht, rht)
  if lht.order == rht.order then
    return lht.name < rht.name
  else return lht.order < rht.order end
end

local function sort_prototypes(t)
  table.sort(t, sort_prototype)
end

local function to_prototypes(items, fluids)
  fluids = fluids or items.fluids
  items = (items and items.items) or items or {}

  local prototypes = {items = {}, fluids = {}}
  for _, i in pairs(items) do
    local name = (type(i) == "table" and i.name) or i
    if game.item_prototypes[name] then
      table.insert(prototypes.items, game.item_prototypes[name])
    elseif not fluids and game.fluid_prototypes[name] then
      table.insert(prototypes.fluids, game.fluid_prototypes[name])
    end
  end
  if fluids then
    for _, f in pairs(fluids) do
      local name = (type(f) == "table" and f.name) or f
      if game.fluid_prototypes[name] then
        table.insert(prototypes.fluids, game.fluid_prototypes[name])
      end
    end
  end

  sort_prototypes(prototypes.items)
  sort_prototypes(prototypes.fluids)
  return prototypes
end

--############################################################################--
--                                  GENERATE                                  --
--############################################################################--

local function check_validity(check)
  check = check or global.targets

  for index, prototype in pairs(check.items) do
    if not(prototype.valid) then table.remove(check.items, index) end
  end

  for index, prototype in pairs(check.fluids) do
    if not(prototype.valid) then table.remove(check.fluids, index) end
  end
end

function targets.get(ignore_custom)
  -- custom targets
  if not ignore_custom and global.custom_targets then
    return global.custom_targets
  end

  local ov_prototypes = to_prototypes(string.split(settings.global["arcade_mode-resources-override"].value, " "))

  if #ov_prototypes.items + #ov_prototypes.fluids > 0 then
    -- override setting
    return ov_prototypes
  else
    -- mod compat targets
    return to_prototypes(vanilla)
  end
end

function targets.generate()
  local before = global.targets
  -- TODO: lazy equal...
  global.targets = targets.get()
  check_validity()
  if global.targets ~= before then
    script.raise_event(MOD.events.on_targets_changed, global.targets)
  end
end

--############################################################################--
--                                   OTHERS                                   --
--############################################################################--

function targets.get_proxy(type, level)
  if type == "item" then
    if level == 1 then return "transport-belt" end
    if level == 2 then return "fast-transport-belt" end
    if level == 3 then return "express-transport-belt" end
  elseif type == "fluid" then return "offshore-pump" end
end

function targets.set_custom_targets(new_targets)
  log(serpent.block(new_targets))
  if not new_targets then
    global.custom_targets = nil
  else
    global.custom_targets = to_prototypes(new_targets)
  end

  targets.generate()
end

--############################################################################--
--                                   EVENTS                                   --
--############################################################################--

function targets.on_init()
  global.targets = {
    items = {},
    fluids = {}
  }

  targets.generate()
end

function targets.on_configuration_changed()
  targets.generate()
end

function targets.on_runtime_mod_setting_changed(event)
  if event.setting == "arcade_mode-resources-override" then
    targets.generate()
  end
end

return targets