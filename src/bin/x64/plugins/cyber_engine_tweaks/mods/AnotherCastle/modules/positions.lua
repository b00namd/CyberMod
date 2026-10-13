-- Orte der Quest. Feste Werte stehen in DEFAULTS, im Spiel festgelegte Orte
-- landen in positions.txt (eine Zeile pro Ort: name x y z yaw) und haben Vorrang.
local util = require("modules/util")

local FILE = "positions.txt"

local DEFAULTS = {
    -- luca    = { x = 0, y = 0, z = 0, yaw = 0 },
    -- castle1 = { x = 0, y = 0, z = 0, yaw = 0 },
}

local positions = { saved = {} }

function positions.load()
    positions.saved = {}
    local file = io.open(FILE, "r")
    if not file then return end

    for line in file:lines() do
        local name, x, y, z, yaw = line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
        if name and tonumber(x) then
            positions.saved[name] = { x = tonumber(x), y = tonumber(y), z = tonumber(z), yaw = tonumber(yaw) }
        end
    end
    file:close()
end

function positions.save()
    local file = io.open(FILE, "w")
    if not file then
        util.err("Konnte " .. FILE .. " nicht schreiben")
        return
    end

    for name, p in pairs(positions.saved) do
        file:write(string.format("%s %.3f %.3f %.3f %.2f\n", name, p.x, p.y, p.z, p.yaw))
    end
    file:close()
end

function positions.get(name)
    return positions.saved[name] or DEFAULTS[name]
end

-- Speichert die aktuelle Position und Blickrichtung des Spielers unter name
function positions.setFromPlayer(name)
    local player = Game.GetPlayer()
    local pos = player:GetWorldPosition()
    positions.saved[name] = { x = pos.x, y = pos.y, z = pos.z, yaw = player:GetWorldYaw() }
    positions.save()
    util.log(string.format("Position '%s' gesetzt: %.3f %.3f %.3f", name, pos.x, pos.y, pos.z))
    return positions.saved[name]
end

function positions.toVector(p)
    return Vector4.new(p.x, p.y, p.z, 1)
end

return positions
