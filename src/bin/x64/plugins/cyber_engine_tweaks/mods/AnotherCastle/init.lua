-- Another Castle – Questmod für Cyberpunk 2077
-- Benötigt: Cyber Engine Tweaks, Codeware (NPCs, Texte), redscript
local util = require("modules/util")
local positions = require("modules/positions")
local world = require("modules/world")
local dialog = require("modules/dialog")
local chapter1 = require("modules/chapter1")
local dev = require("modules/dev")

local state = {
    overlay = false,
    active = false,         -- ein Spielstand ist geladen
    pendingRestart = false  -- ein (neuer) Spielstand wurde geladen
}

local function inGame()
    return Game.GetPlayer() ~= nil and not Game.GetSystemRequestsHandler():IsPreGame()
end

-- afterLoad: Spiel hat Marker und NPCs beim Laden selbst entfernt
local function sessionStart(afterLoad)
    util.clearTimers()
    dialog.active = false
    if afterLoad then
        world.forget()
    else
        world.clear()
    end
    state.active = true
    util.after(3, chapter1.onSessionStart)
    util.log("Sitzung gestartet")
end

local function sessionEnd()
    state.active = false
    util.clearTimers()
    dialog.active = false
    world.forget()
    util.log("Sitzung beendet")
end

registerForEvent("onInit", function()
    positions.load()
    dialog.init()

    Observe("PlayerPuppet", "OnGameAttached", function(player)
        if not player:IsReplacer() then
            state.pendingRestart = true
        end
    end)

    util.log("Another Castle geladen")
end)

-- Tasten werden im CET-Overlay unter "Bindings" belegt
registerHotkey("ac_teleport_waypoint", "Zum Karten-Wegpunkt teleportieren", function()
    if state.active then util.try("teleportToWaypoint", dev.teleportToWaypoint) end
end)

registerHotkey("ac_teleport_back", "Zurück zur letzten Position", function()
    if state.active then util.try("teleportBack", dev.teleportBack) end
end)

registerForEvent("onUpdate", function(dt)
    util.try("onUpdate", function()
        if not inGame() then
            if state.active then sessionEnd() end
            return
        end

        if not state.active then
            sessionStart(false)
        elseif state.pendingRestart then
            sessionStart(true)
        end
        state.pendingRestart = false

        util.updateTimers(dt)
        dialog.update(dt)
        chapter1.update()
    end)
end)

registerForEvent("onShutdown", function()
    dialog.hide()
    world.clear()
end)

registerForEvent("onOverlayOpen", function() state.overlay = true end)
registerForEvent("onOverlayClose", function() state.overlay = false end)

registerForEvent("onDraw", function()
    if state.overlay then
        dev.draw(state.active)
    end
end)
