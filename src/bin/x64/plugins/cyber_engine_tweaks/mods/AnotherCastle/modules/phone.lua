-- Handy: Kontakte, SMS und Antworten über das Journal des Spiels.
-- Die Einträge selbst stehen in texts/phone.json und kommen über AnotherCastle.archive ins Spiel.
-- Journal-Zustände werden im Spielstand gespeichert.
local util = require("modules/util")

local CLASS = {
    contact = "gameJournalContact",
    conversation = "gameJournalPhoneConversation",
    message = "gameJournalPhoneMessage",
    choiceGroup = "gameJournalPhoneChoiceGroup",
    choice = "gameJournalPhoneChoiceEntry"
}

local phone = {}

local function journal()
    return Game.GetJournalManager()
end

local function setState(path, class, state, notify)
    local option = notify and JournalNotifyOption.Notify or JournalNotifyOption.DoNotNotify
    if not journal():ChangeEntryState(path, class, state, option) then
        util.err("Journal-Eintrag nicht gefunden: " .. path)
    end
end

local function isState(path, class, state)
    local entry = journal():GetEntryByString(path, class)
    return entry ~= nil and EnumInt(journal():GetEntryState(entry)) == EnumInt(state)
end

-- Eine Unterhaltung mit einem Kontakt, z.B. phone.conversation("ac_luca_rossi", "ch1")
function phone.conversation(contactId, conversationId)
    local contactPath = "contacts/" .. contactId
    local base = contactPath .. "/" .. conversationId .. "/"
    local c = {}

    -- Kontakt und Unterhaltung im Handy sichtbar machen
    function c.open()
        setState(contactPath, CLASS.contact, gameJournalEntryState.Active, false)
        setState(contactPath .. "/" .. conversationId, CLASS.conversation, gameJournalEntryState.Active, false)
    end

    -- notify: mit Benachrichtigung und Ton wie eine echte SMS
    function c.send(messageId, notify)
        setState(base .. messageId, CLASS.message, gameJournalEntryState.Active, notify ~= false)
    end

    function c.offerChoices(groupId, choiceIds)
        setState(base .. groupId, CLASS.choiceGroup, gameJournalEntryState.Active, false)
        for _, choiceId in ipairs(choiceIds) do
            setState(base .. groupId .. "/" .. choiceId, CLASS.choice, gameJournalEntryState.Active, false)
        end
    end

    -- Gewählte Antwort (das Spiel setzt sie beim Auswählen auf Succeeded) oder nil
    function c.chosen(groupId, choiceIds)
        for _, choiceId in ipairs(choiceIds) do
            if isState(base .. groupId .. "/" .. choiceId, CLASS.choice, gameJournalEntryState.Succeeded) then
                return choiceId
            end
        end
        return nil
    end

    -- Für das Zurücksetzen der Quest: alles wieder ausblenden
    function c.reset(messageIds, groupId, choiceIds)
        for _, messageId in ipairs(messageIds) do
            setState(base .. messageId, CLASS.message, gameJournalEntryState.Inactive, false)
        end
        for _, choiceId in ipairs(choiceIds) do
            setState(base .. groupId .. "/" .. choiceId, CLASS.choice, gameJournalEntryState.Inactive, false)
        end
        setState(base .. groupId, CLASS.choiceGroup, gameJournalEntryState.Inactive, false)
        setState(contactPath .. "/" .. conversationId, CLASS.conversation, gameJournalEntryState.Inactive, false)
        setState(contactPath, CLASS.contact, gameJournalEntryState.Inactive, false)
    end

    return c
end

return phone
