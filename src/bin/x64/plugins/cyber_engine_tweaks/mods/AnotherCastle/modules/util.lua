-- Hilfsfunktionen: Log, Texte, Bildschirmnachrichten, Timer, Facts
local util = {}

local timers = {}
local loggedErrors = {}

-- Das CET-Log (AnotherCastle.log) wird erst beim Beenden geschrieben.
-- debug.log wird sofort geschrieben, damit es sich während des Spielens auslesen lässt.
local DEBUG_FILE = "debug.log"

local function writeDebug(level, msg)
    local file = io.open(DEBUG_FILE, "a")
    if file then
        file:write(os.date("%H:%M:%S") .. " [" .. level .. "] " .. msg .. "\n")
        file:close()
    end
end

function util.log(msg)
    msg = tostring(msg)
    spdlog.info(msg)
    writeDebug("info", msg)
end

-- Jeder Fehler wird nur einmal geloggt, sonst füllt ein Fehler in onUpdate das Log in jedem Frame
function util.err(msg)
    msg = tostring(msg)
    if loggedErrors[msg] then return end
    loggedErrors[msg] = true
    spdlog.error(msg)
    writeDebug("FEHLER", msg)
    print("[AnotherCastle] FEHLER: " .. msg)
end

-- Führt fn geschützt aus, damit ein Fehler nicht den ganzen Mod stoppt
function util.try(label, fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        util.err(label .. ": " .. tostring(result))
    end
    return ok, result
end

-- Übersetzter Text aus Localization.reds (Codeware)
function util.text(key)
    local value = GetLocalizedTextByKey(key)
    if value == nil or value == "" then
        return key
    end
    return value
end

-- Nachricht oben in der Bildschirmmitte
function util.notify(text, duration)
    local msg = SimpleScreenMessage.new()
    msg.message = text
    msg.duration = duration or 5
    msg.isShown = true

    local defs = GetAllBlackboardDefs()
    local bb = Game.GetBlackboardSystem():Get(defs.UI_Notifications)
    bb:SetVariant(defs.UI_Notifications.OnscreenMessage, ToVariant(msg), true)
end

-- Anzeigedauer abhängig von der Textlänge
function util.readTime(text)
    return 2.5 + #text / 20
end

-- Zeigt mehrere Zeilen eines Sprechers nacheinander an und ruft danach onDone auf
function util.sayLines(speakerKey, lineKeys, onDone)
    local delay = 0
    for _, key in ipairs(lineKeys) do
        local text = util.text(speakerKey) .. ": " .. util.text(key)
        local duration = util.readTime(text)
        util.after(delay, function() util.notify(text, duration) end)
        delay = delay + duration + 0.3
    end
    if onDone then
        util.after(delay, onDone)
    end
end

function util.after(seconds, fn)
    table.insert(timers, { remaining = seconds, fn = fn })
end

function util.clearTimers()
    timers = {}
end

function util.updateTimers(dt)
    for i = #timers, 1, -1 do
        local timer = timers[i]
        timer.remaining = timer.remaining - dt
        if timer.remaining <= 0 then
            table.remove(timers, i)
            util.try("Timer", timer.fn)
        end
    end
end

-- Quest-Fortschritt als Fact: wird automatisch im Spielstand gespeichert
function util.getFact(name)
    return Game.GetQuestsSystem():GetFactStr(name)
end

function util.setFact(name, value)
    Game.GetQuestsSystem():SetFactStr(name, value)
end

function util.distance(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

return util
