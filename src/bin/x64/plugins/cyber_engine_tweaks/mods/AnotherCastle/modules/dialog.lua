-- Dialogauswahl im Stil des Spiels (Auswahlbox rechts neben dem Fadenkreuz).
-- Die Box wird über das UIInteractions-Blackboard angezeigt, Eingaben kommen über PlayerPuppet.OnAction.
local util = require("modules/util")

local HUB_ID = 7770001

local dialog = {
    active = false,
    title = "",
    choices = {},       -- { text = "...", read = bool, onSelect = function }
    selected = 0,       -- 0-basiert wie im Spiel
    logInput = false,   -- Eingaben ins Log schreiben (Debug)
    lastInput = 0,
    clock = 0
}

local function blackboard()
    local defs = GetAllBlackboardDefs()
    return Game.GetBlackboardSystem():Get(defs.UIInteractions), defs.UIInteractions
end

local function buildHubs()
    local hubs = gameinteractionsvisDialogChoiceHubs.new()
    if not dialog.active then
        return hubs
    end

    local list = {}
    for _, choice in ipairs(dialog.choices) do
        local data = gameinteractionsvisListChoiceData.new()
        data.localizedName = choice.text
        data.inputActionName = "None"
        if choice.read then
            local choiceType = gameinteractionsChoiceTypeWrapper.new()
            choiceType:SetType(gameinteractionsChoiceType.AlreadyRead)
            data.type = choiceType
        end
        table.insert(list, data)
    end

    local hub = gameinteractionsvisListChoiceHubData.new()
    hub.id = HUB_ID
    hub.title = dialog.title
    hub.choices = list
    hub.activityState = gameinteractionsvisEVisualizerActivityState.Active
    hub.hubPriority = 1

    hubs.choiceHubs = { hub }
    return hubs
end

local function push()
    local bb, def = blackboard()
    if not bb then return end  -- z.B. beim Beenden des Spiels
    bb:SetVariant(def.DialogChoiceHubs, ToVariant(buildHubs()), true)
    if dialog.active then
        bb:SetInt(def.ActiveChoiceHubID, HUB_ID, true)
        bb:SetInt(def.SelectedIndex, dialog.selected, true)
    end
end

function dialog.show(title, choices)
    dialog.active = true
    dialog.title = title
    dialog.choices = choices
    dialog.selected = 0
    util.try("dialog.show", push)
end

function dialog.hide()
    if not dialog.active then return end
    dialog.active = false
    dialog.choices = {}
    util.try("dialog.hide", push)
end

local function move(step)
    local count = #dialog.choices
    if count == 0 then return end
    dialog.selected = (dialog.selected + step) % count
    util.try("dialog.move", push)
end

local function apply()
    local choice = dialog.choices[dialog.selected + 1]
    if not choice then return end
    dialog.hide()
    util.try("dialog.onSelect", choice.onSelect)
end

local function onAction(action)
    if not dialog.active then return end

    local name = Game.NameToString(ListenerAction.GetName(action))
    local actionType = ListenerAction.GetType(action).value

    if dialog.logInput then
        util.log("Eingabe: " .. name .. " / " .. tostring(actionType))
    end

    -- Kurze Sperre, damit ein Tastendruck nicht doppelt zählt
    if dialog.clock - dialog.lastInput < 0.15 then return end
    if actionType == "BUTTON_RELEASED" then return end

    if name == "ChoiceScrollUp" then
        dialog.lastInput = dialog.clock
        move(-1)
    elseif name == "ChoiceScrollDown" then
        dialog.lastInput = dialog.clock
        move(1)
    elseif (name == "ChoiceApply" or name == "Choice1") and actionType == "BUTTON_PRESSED" then
        dialog.lastInput = dialog.clock
        apply()
    end
end

function dialog.init()
    Observe("PlayerPuppet", "OnAction", function(_, action)
        util.try("dialog.onAction", onAction, action)
    end)

    -- Das Spiel überschreibt die Auswahlbox, sobald es eigene Interaktionen aktualisiert.
    -- Solange unser Dialog läuft, ersetzen wir die Daten durch unsere eigenen.
    util.try("Override OnDialogsData", function()
        Override("InteractionUIBase", "OnDialogsData", function(this, value, wrapped)
            if dialog.active then
                value = ToVariant(buildHubs())
            end
            wrapped(value)
        end)
    end)
end

function dialog.update(dt)
    dialog.clock = dialog.clock + dt
end

return dialog
