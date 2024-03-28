-- Helper functions
function int_to_bool(value)
    if value == 0 then
        return false
    else
        return true
    end
end

function get_ap_state(array)
    if array[0] >= 1 then
        return true
    else
        return false
    end
end

function array_has_true(array, max_lenght)
    if max_lenght == nil then
        max_lenght = 16
    end
    for i = 0, max_lenght do
        if array[i] == 1 then
            return true
        end
    end

    return false
end

function array_has_positives(array, max_lenght)
    if max_lenght == nil then
        max_lenght = 16
    end
    for i = 0, max_lenght do
        if not array[i] then
            write_log('ERROR array_has_positives: array[' .. i .. '] is nil')
            break
        end
        if array[i] > 0.01 then
            return true
        end
    end
    return false
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
            dumpTable(v, indent+1)
        else
            write_log(formatting .. tostring(v))
        end
    end
end