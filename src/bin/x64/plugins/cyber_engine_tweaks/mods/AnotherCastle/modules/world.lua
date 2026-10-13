-- Kartenmarker und NPCs (NPCs über Codeware DynamicEntitySystem)
local util = require("modules/util")
local positions = require("modules/positions")

local TAG = "AnotherCastle"

local world = { pins = {}, npcs = {} }

function world.addPin(name, p)
    world.removePin(name)
    local data = MappinData.new({
        mappinType = "Mappins.DefaultStaticMappin",
        variant = gamedataMappinVariant.DefaultQuestVariant,
        visibleThroughWalls = true
    })
    world.pins[name] = Game.GetMappinSystem():RegisterMappin(data, positions.toVector(p))
end

function world.removePin(name)
    if world.pins[name] then
        Game.GetMappinSystem():UnregisterMappin(world.pins[name])
        world.pins[name] = nil
    end
end

function world.spawnNPC(name, record, p, appearance)
    world.despawnNPC(name)
    local spec = DynamicEntitySpec.new()
    spec.recordID = TweakDBID.new(record)
    spec.appearanceName = CName.new(appearance or "random")
    spec.position = positions.toVector(p)
    spec.orientation = EulerAngles.new(0, 0, p.yaw or 0):ToQuat()
    spec.persistState = false
    spec.persistSpawn = false
    -- Achtung: spec.tags liefert in CET nur eine Kopie, Listen deshalb immer komplett zuweisen
    spec.tags = { CName.new(TAG) }
    local id = Game.GetDynamicEntitySystem():CreateEntity(spec)
    world.npcs[name] = id
    util.log("NPC '" .. name .. "' gespawnt: " .. record)

    world.logWhenReady(name, id)
end

-- Entwicklungshilfe: Bauteile ins Log schreiben, sobald der NPC in der Welt ist
-- (erscheint erst, wenn der Spieler in der Nähe ist)
function world.logWhenReady(name, id)
    util.after(1, function()
        if world.npcs[name] ~= id then return end  -- inzwischen entfernt oder neu gespawnt
        if not world.getNPC(name) then
            world.logWhenReady(name, id)
            return
        end
        util.after(2, function() world.logNPCComponents(name) end)
    end)
end

function world.despawnNPC(name)
    if world.npcs[name] then
        Game.GetDynamicEntitySystem():DeleteEntity(world.npcs[name])
        world.npcs[name] = nil
    end
end

function world.getNPC(name)
    if not world.npcs[name] then return nil end
    return Game.GetDynamicEntitySystem():GetEntity(world.npcs[name])
end

-- Schreibt die Bauteile eines NPCs (Meshes, Farbvarianten) ins Log, über Look.reds
function world.logNPCComponents(name)
    local entity = world.getNPC(name)
    if not entity then
        util.log("NPC '" .. name .. "' ist (noch) nicht in der Welt")
        return false
    end
    util.log("=== Bauteile von '" .. name .. "' ===")
    for line in AnotherCastleLook.Describe(entity):gmatch("[^\n]+") do
        util.log(line)
    end
    return true
end

-- Entfernt alle Marker und NPCs des Mods
function world.clear()
    for name in pairs(world.pins) do
        util.try("removePin", world.removePin, name)
    end
    world.pins = {}
    world.npcs = {}
    util.try("DeleteTagged", function() Game.GetDynamicEntitySystem():DeleteTagged(TAG) end)
end

-- Nach dem Laden eines Spielstands sind Marker ohnehin weg, nur die Tabellen leeren
function world.forget()
    world.pins = {}
    world.npcs = {}
end

return world
