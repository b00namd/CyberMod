-- Entwickler-Fenster im CET-Overlay: Quest steuern, Orte festlegen, NPC-Optik testen
local util = require("modules/util")
local positions = require("modules/positions")
local world = require("modules/world")
local dialog = require("modules/dialog")
local chapter1 = require("modules/chapter1")

-- Farbvarianten zum Durchprobieren an Luca (Mesh-Teilpfad → Varianten aus den Spieldateien)
local COLOR_OPTIONS = {
    {
        label = "T-Shirt",
        meshPart = "t1_079_ma_tshirt__casual",
        values = { "green_flag", "green_japan", "green_monkey", "green_scull", "green_diver", "green_stripes_dirty" }
    },
    {
        label = "Haare",
        meshPart = "hh_020_ma__mullet",
        values = { "brown_liquorice", "brown_medium", "brown_ombre", "black_carbon", "ginger_copper", "blonde_dishwater", "goblin_green" }
    },
    {
        label = "Schnurrbart",
        meshPart = "hb_001_ma_c__handlebar_stache",
        values = { "brown_liquorice", "brown_ombre", "black_carbon", "ginger_copper", "blonde_dishwater", "gray_gunmetal" }
    },
    {
        label = "Augenbrauen",
        meshPart = "heb_001_ma_c__basehead",
        values = { "brown_05", "brown_01", "brown_03", "brown_08", "brown_10", "black_05" }
    },
    {
        label = "Haut",
        meshParts = { "h0_001_ma_c__basehead.mesh", "t0_000_ma_base__full" },
        values = { "02_ca_limestone", "01_ca_pale", "04_ca_almond", "03_ca_senna" }
    },
    {
        label = "Hose",
        meshPart = "l1_030_ma_pants__worker",
        values = { "green", "green_rich" }
    }
}

local dev = { lastPosition = nil, colorIndex = {} }

local function teleportTo(p)
    local player = Game.GetPlayer()
    local pos = player:GetWorldPosition()
    dev.lastPosition = { x = pos.x, y = pos.y, z = pos.z, yaw = player:GetWorldYaw() }
    Game.GetTeleportationFacility():Teleport(player, positions.toVector(p), EulerAngles.new(0, 0, p.yaw or 0))
end

-- Sucht den Wegpunkt, den man auf der Karte selbst setzt (Codeware: GetAllMappins)
local function findMapWaypoint()
    local customVariant = EnumInt(gamedataMappinVariant.CustomPositionVariant)
    for _, mappin in ipairs(Game.GetMappinSystem():GetAllMappins()) do
        if EnumInt(mappin:GetVariant()) == customVariant then
            return mappin:GetWorldPosition()
        end
    end
    return nil
end

function dev.teleportToWaypoint()
    local target = findMapWaypoint()
    if not target then
        util.notify("Kein Wegpunkt auf der Karte gesetzt", 3)
        return
    end
    util.log(string.format("Teleport zum Wegpunkt: %.1f / %.1f / %.1f", target.x, target.y, target.z))
    teleportTo({ x = target.x, y = target.y, z = target.z + 1, yaw = Game.GetPlayer():GetWorldYaw() })
end

function dev.teleportBack()
    if dev.lastPosition then
        teleportTo(dev.lastPosition)
    end
end

local function respawnLuca()
    local p = positions.get("luca")
    if p then
        world.spawnNPC("luca", chapter1.lucaRecord, p, chapter1.lucaAppearance)
    end
end

local function cycleColor(option, step)
    local entity = world.getNPC("luca")
    if not entity then
        util.notify("Luca ist gerade nicht in der Welt", 3)
        return
    end
    local index = ((dev.colorIndex[option.label] or 1) - 1 + step) % #option.values + 1
    dev.colorIndex[option.label] = index
    local value = option.values[index]
    local changed = 0
    for _, meshPart in ipairs(option.meshParts or { option.meshPart }) do
        changed = changed + AnotherCastleLook.SetMeshAppearance(entity, meshPart, CName.new(value))
    end
    util.log(string.format("Farbe %s -> %s (%d Meshes)", option.label, value, changed))
end

local function colorRow(option)
    local index = dev.colorIndex[option.label] or 1
    if ImGui.Button("<##" .. option.label) then
        util.try("cycleColor", cycleColor, option, -1)
    end
    ImGui.SameLine()
    if ImGui.Button(">##" .. option.label) then
        util.try("cycleColor", cycleColor, option, 1)
    end
    ImGui.SameLine()
    ImGui.Text(option.label .. ": " .. option.values[index])
end

local function logLucaComponents()
    if world.logNPCComponents("luca") then
        util.notify("Lucas Bauteile stehen im Log", 3)
    else
        util.notify("Luca ist gerade nicht in der Welt", 3)
    end
end

local TIME_PRESETS = { { "Morgen", 7 }, { "Mittag", 12 }, { "Abend", 18 }, { "Nacht", 23 } }

local function setHour(hour)
    Game.GetTimeSystem():SetGameTimeByHMS(hour, 0, 0)
    util.log("Tageszeit -> " .. hour .. ":00")
end

local function timeRow()
    local now = Game.GetTimeSystem():GetGameTime()
    local hour, minute = GameTime.Hours(now), GameTime.Minutes(now)
    ImGui.Text(string.format("Tageszeit: %02d:%02d", hour, minute))
    for i, preset in ipairs(TIME_PRESETS) do
        if i > 1 then ImGui.SameLine() end
        if ImGui.Button(preset[1]) then
            util.try("setHour", setHour, preset[2])
        end
    end
    local newHour, changed = ImGui.SliderInt("Stunde", hour, 0, 23)
    if changed then
        util.try("setHour", setHour, newHour)
    end
end

local function positionRow(label, name)
    local p = positions.get(name)
    if p then
        ImGui.Text(string.format("%s: %.1f / %.1f / %.1f", label, p.x, p.y, p.z))
    else
        ImGui.Text(label .. ": nicht festgelegt")
    end

    if ImGui.Button("Hier festlegen##" .. name) then
        util.try("setPosition", function()
            positions.setFromPlayer(name)
            world.clear()
            chapter1.setupStage()
        end)
    end
    if p then
        ImGui.SameLine()
        if ImGui.Button("Hinteleportieren##" .. name) then
            util.try("teleport", teleportTo, p)
        end
    end
end

function dev.draw(active)
    if ImGui.Begin("Another Castle (Dev)", ImGuiWindowFlags.AlwaysAutoResize) then
        if not active then
            ImGui.Text("Kein Spielstand geladen.")
        else
            ImGui.Text("Fortschritt (ac_stage): " .. tostring(chapter1.getStage()))
            ImGui.Text("Dialog aktiv: " .. tostring(dialog.active) .. "   Luca spricht: " .. tostring(chapter1.busy))

            if ImGui.Button("Kapitel 1 starten") then
                util.try("start", chapter1.start)
            end
            ImGui.SameLine()
            if ImGui.Button("Quest zurücksetzen") then
                util.try("reset", chapter1.reset)
            end

            ImGui.Separator()
            util.try("timeRow", timeRow)

            ImGui.Separator()
            ImGui.Text("Teleport")
            if ImGui.Button("Zum Karten-Wegpunkt") then
                util.try("teleportToWaypoint", dev.teleportToWaypoint)
            end
            ImGui.SameLine()
            if ImGui.Button("Zurück") then
                util.try("teleportBack", dev.teleportBack)
            end

            ImGui.Separator()
            ImGui.Text("Orte (Luca schaut in deine Blickrichtung)")
            positionRow("Treffpunkt Luca", "luca")
            positionRow("Burg 1 (Northside)", "castle1")

            ImGui.Separator()
            ImGui.Text("Luca-Optik")
            chapter1.lucaRecord = ImGui.InputText("Record", chapter1.lucaRecord, 200)
            chapter1.lucaAppearance = ImGui.InputText("Appearance", chapter1.lucaAppearance, 200)
            if ImGui.Button("Luca neu spawnen") then
                util.try("respawn", respawnLuca)
            end
            ImGui.SameLine()
            if ImGui.Button("Lucas Bauteile ins Log") then
                util.try("logLucaComponents", logLucaComponents)
            end

            ImGui.Text("Farben an Luca ausprobieren")
            for _, option in ipairs(COLOR_OPTIONS) do
                colorRow(option)
            end

            ImGui.Separator()
            dialog.logInput = ImGui.Checkbox("Tasteneingaben im Dialog loggen", dialog.logInput)
        end
    end
    ImGui.End()
end

return dev
