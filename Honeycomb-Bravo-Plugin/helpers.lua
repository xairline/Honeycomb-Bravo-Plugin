-- Helper functions
function int_to_bool(value)
    if value == 0 then
        return false
    else
        return true
    end
end

-- Function to split a string by a delimiter (in this case, a comma)
function splitString(s, delimiter)
    local result = {}
    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

-- Function to parse a CSV file
function parseCSV(filePath)
    local file = io.open(filePath, "r") -- Open the file for reading
    if not file then return nil, "File not found" end

    local header = splitString(file:read(), ",") -- Read the header line
    local data = {}

    for line in file:lines() do -- Iterate over each line in the file
        local values = splitString(line, ",")
        local row = {}
        for i, v in ipairs(header) do
            row[v] = values[i]
        end
        table.insert(data, row)
    end

    file:close() -- Always remember to close the file
    return data
end

function dumpTable(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            write_log(formatting)
            dumpTable(v, indent + 1)
        else
            write_log(formatting .. tostring(v))
        end
    end
end

function check_datarefs(tbl, num_of_engines, debug)
    local res = nil
    if tbl['conditions'] == 'any' then
        --  assume nothing is true until proven otherwise and we can return asap
        res = false
    elseif tbl['conditions'] == 'all' then
        --  assume everything is true until proven otherwise and we can return asap
        res = true
    else
        dumpTable(tbl)
    end
    for _, value in ipairs(tbl['datarefs']) do
        if tbl['conditions'] == 'any' then
            -- Check if any of the datarefs is true
            if check_dataref(value, tbl['operators'], tbl['thresholds'], tbl['conditions'], num_of_engines, debug) then
                return true
            end
        elseif tbl['conditions'] == 'all' then
            -- Check if all of the datarefs are true
            if not check_dataref(value, tbl['operators'], tbl['thresholds'], tbl['conditions'], num_of_engines, debug) then
                return false
            end
        end
    end
    return res
end

function check_dataref(tbl, operator, threshold, conditions, num_of_engines, debug)
    local funcCode = [[
        return function(x, debug)
            if debug then
                write_log('Dataref: ', x)
            end
            return x]] .. operator .. threshold .. [[
        end
    ]]
    local func = load(funcCode)()

    local res = nil
    if conditions == 'any' then
        --  assume nothing is true until proven otherwise and we can return asap
        res = false
    elseif conditions == 'all' then
        --  assume everything is true until proven otherwise and we can return asap
        res = true
    end
    if num_of_engines == nil then
        num_of_engines = 8
    end
    if tbl['reftype'] > 4 then
        for i = 0, num_of_engines - 1 do
            if conditions == 'any' then
                -- Check if any of the datarefs is true
                if func(tbl[i], debug) then
                    return true
                end
            elseif conditions == 'all' then
                -- Check if all of the datarefs are true
                if not func(tbl[i], debug) then
                    return false
                end
            end
        end
    else
        return func(tbl[0], debug)
    end

    return res
end
