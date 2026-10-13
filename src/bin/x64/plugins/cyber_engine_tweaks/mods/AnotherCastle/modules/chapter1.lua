-- Kapitel 1 – Rohrbruch: SMS von Luca, Treffen, Gespräch, Marker zur ersten Burg
local util = require("modules/util")
local positions = require("modules/positions")
local world = require("modules/world")
local dialog = require("modules/dialog")

local FACT = "ac_stage"
local STAGE = { NONE = 0, MEET_LUCA = 1, CASTLE1 = 2 }
local TALK_RADIUS = 2.5
local DESPAWN_DISTANCE = 60
local AUTOSTART_DELAY = 15

local chapter1 = {
    STAGE = STAGE,
    autoStart = true,
    -- Eigener NPC-Eintrag (luca.yaml) mit eigenem Aussehen (AnotherCastle.archive): Vokuhila, grünes T-Shirt
    lucaRecord = "Character.ac_luca_rossi",
    lucaAppearance = "ac_luca",
    read = {},    -- bereits gewählte Dialogoptionen
    busy = false  -- Luca spricht gerade
}

function chapter1.getStage()
    return util.getFact(FACT)
end

local function setStage(stage)
    util.setFact(FACT, stage)
    util.log("Stage -> " .. stage)
end

-- Treffpunkt mit Luca. Ist noch keiner festgelegt, steht Luca 6 m vor dem Spieler,
-- damit sich der Ablauf sofort testen lässt.
local function lucaPosition()
    local p = positions.get("luca")
    if p then return p end

    local player = Game.GetPlayer()
    local pos = player:GetWorldPosition()
    local forward = player:GetWorldForward()
    positions.saved.luca = {
        x = pos.x + forward.x * 6,
        y = pos.y + forward.y * 6,
        z = pos.z,
        yaw = player:GetWorldYaw() + 180
    }
    positions.save()
    util.log("Kein Treffpunkt festgelegt, Luca steht vor dem Spieler")
    return positions.saved.luca
end

-- Stellt Marker und NPCs passend zum Fortschritt her (nach dem Laden oder Zurücksetzen)
function chapter1.setupStage()
    local stage = chapter1.getStage()
    if stage == STAGE.MEET_LUCA then
        local p = lucaPosition()
        world.addPin("luca", p)
        world.spawnNPC("luca", chapter1.lucaRecord, p, chapter1.lucaAppearance)
    elseif stage == STAGE.CASTLE1 then
        local p = positions.get("castle1")
        if p then world.addPin("castle1", p) end
    end
end

function chapter1.start()
    if chapter1.getStage() ~= STAGE.NONE then return end
    setStage(STAGE.MEET_LUCA)
    chapter1.read = {}

    util.sayLines("AC-Name-Luca", { "AC-Ch1-Sms-1", "AC-Ch1-Sms-2", "AC-Ch1-Sms-3" }, function()
        chapter1.setupStage()
        util.notify(util.text("AC-Ch1-Objective-Meet"), 5)
    end)
end

local function accept()
    setStage(STAGE.CASTLE1)
    world.removePin("luca")

    local p = positions.get("castle1")
    if p then world.addPin("castle1", p) end

    util.notify(util.text("AC-Ch1-Objective-Castle1"), 5)
    util.after(6, function() util.notify(util.text("AC-Hint-ToBeContinued"), 4) end)
end

local function talk(key, lines, onDone)
    chapter1.busy = true
    chapter1.read[key] = true
    util.sayLines("AC-Name-Luca", lines, function()
        chapter1.busy = false
        if onDone then onDone() end
    end)
end

local function showDialog()
    dialog.show(util.text("AC-Name-Luca"), {
        {
            text = util.text("AC-Ch1-Choice-What"),
            read = chapter1.read.what,
            onSelect = function() talk("what", { "AC-Ch1-What-1", "AC-Ch1-What-2", "AC-Ch1-What-3" }) end
        },
        {
            text = util.text("AC-Ch1-Choice-Why"),
            read = chapter1.read.why,
            onSelect = function() talk("why", { "AC-Ch1-Why-1", "AC-Ch1-Why-2" }) end
        },
        {
            text = util.text("AC-Ch1-Choice-Accept"),
            onSelect = function() talk("accept", { "AC-Ch1-Accept-1", "AC-Ch1-Accept-2" }, accept) end
        }
    })
end

function chapter1.onSessionStart()
    chapter1.read = {}
    chapter1.busy = false
    chapter1.setupStage()

    if chapter1.autoStart and chapter1.getStage() == STAGE.NONE then
        util.after(AUTOSTART_DELAY, chapter1.start)
    end
end

function chapter1.update()
    local stage = chapter1.getStage()
    local p = positions.get("luca")
    if not p or not world.npcs.luca then return end

    local distance = util.distance(Game.GetPlayer():GetWorldPosition(), p)

    -- Nach dem Gespräch verschwindet Luca, sobald der Spieler weit genug weg ist
    if stage == STAGE.CASTLE1 then
        if distance > DESPAWN_DISTANCE then world.despawnNPC("luca") end
        return
    end

    if stage ~= STAGE.MEET_LUCA or chapter1.busy then return end

    if distance <= TALK_RADIUS and not dialog.active then
        showDialog()
    elseif distance > TALK_RADIUS + 0.5 and dialog.active then
        dialog.hide()
    end
end

function chapter1.reset()
    dialog.hide()
    util.clearTimers()
    world.clear()
    setStage(STAGE.NONE)
    chapter1.read = {}
    chapter1.busy = false
end

return chapter1
