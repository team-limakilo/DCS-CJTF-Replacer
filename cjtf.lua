local io = require("io")

local CJTF_BLUE = 80
local CJTF_RED  = 81

-- Checks if the group contains any client slots
local function isClientGroup(group)
    local isClient = false
    local containsAI = false
    for _, unit in pairs(group.units) do
        if unit.skill == "Client" then
            isClient = true
        else
            containsAI = true
        end
    end
    if isClient and containsAI then
        print(string.format("Warning: group '%s' contains both AI and client slots", group.name))
    end
    return isClient
end

-- Process individual groups, removing client slots from the original list
-- and adding them to the new one
local function processGroups(groups, newlist, country)
    local remove = {}
    for id, group in ipairs(groups) do
        if isClientGroup(group) then
            print(string.format("Removing client group '%s' from %s", group.name, country))
            table.insert(newlist, group)
            table.insert(remove, 1, id)
            -- Fixup callsigns because CJTF Blue/Red only allow table callsigns (like NATO)
            for _, unit in pairs(group.units) do
                if type(unit.callsign) == "number" then
                    print(string.format(
                        "Warning: unit '%s' has russian callsign (%s); changing to Enfield 1-1",
                        unit.name, tostring(unit.callsign)))
                    unit.callsign = {
                        [1] = 1,
                        [2] = 1,
                        [3] = 1,
                        ["name"] = "Enfield11",
                    }
                end
            end
        end
    end
    for _, id in ipairs(remove) do
        table.remove(groups, id)
    end
end

-- Pulls all client slots into the CTJF of their respective coalition
local function processMission(mission, coalition, cjtf)
    -- Verify that the CJTF is correctly set up
    local cjtf_found = false
    for _, country in pairs(mission.coalitions[coalition]) do
        if country == cjtf then
            cjtf_found = true
            break
        end
    end
    assert(cjtf_found, string.format("Error: CJTF %s is not set as %sFOR", coalition, coalition:upper()))
    -- Extract all client groups into a list
    local client_planes = {}
    local client_helis  = {}
    for _, country in pairs(mission.coalition[coalition].country) do
        if country.plane ~= nil then
            processGroups(country.plane.group, client_planes, country.name)
        end
        if country.helicopter ~= nil then
            processGroups(country.helicopter.group, client_helis, country.name)
        end
    end
    -- Re-add client slots into the corresponding CJTF list
    for _, country in pairs(mission.coalition[coalition].country) do
        if country.id == cjtf then
            if country.plane == nil then
                country.plane = {
                    group = {}
                }
            end
            if country.helicopter == nil then
                country.helicopter = {
                    group = {}
                }
            end
            for _, group in pairs(client_planes) do
                print(string.format("Adding client group '%s' to CJTF %s", group.name, coalition))
                table.insert(country.plane.group, group)
            end
            for _, group in pairs(client_helis) do
                print(string.format("Adding client group '%s' to CJTF %s", group.name, coalition))
                table.insert(country.helicopter.group, group)
            end
        end
    end
end

-- Loads the mission table
local function loadMission()
    local func = loadfile("mission")
    local env = {}
    setfenv(func, env)
    local result = xpcall(func, debug.traceback)
    assert(result)
    return assert(env.mission)
end

-- Escapes backslashes and quotes in strings
local function sanitize(str)
    str = str:gsub('\\', '\\\\')
    str = str:gsub('\n', '\\\n')
    str = str:gsub('"', '\\"')
    return str
end

-- Converts lua datatypes back into lua code
local function serialize(data, indent, name, top)
    if type(data) == "boolean" or type(data) == "number" or type(data) == "nil" then
        return tostring(data)
    elseif type(data) == "string" then
        return string.format('"%s"', sanitize(data))
    elseif type(data) == "table" then
        local buf = string.format('\n%s{', indent)
        local newindent = indent.."    "
        for k, v in pairs(data) do
            if type(k) == "string" then
                k = '"'..k..'"'
            end
            buf = string.format('%s\n%s[%s] = %s,',
                buf, newindent, tostring(k), serialize(v, newindent, k, false))
        end
        if top then
            return string.format('%s\n%s} -- end of %s', buf, indent, name)
        else
            return string.format('%s\n%s}, -- end of [%s]', buf, indent, serialize(name))
        end
    else
        error(string.format("Unsupported data type: %s (key: %s)", type(data), serialize(name)))
    end
end

-- Saves the mission table back to disk
local function saveMission(mission, suffix)
    local file = io.open("mission"..suffix, "w+")
    file:write("-- modified by cjtf.lua\n")
    file:write("mission = "..serialize(mission, "", "mission", true))
end

local mission = loadMission()
processMission(mission, "red", CJTF_RED)
processMission(mission, "blue", CJTF_BLUE)
saveMission(mission, ".new")
