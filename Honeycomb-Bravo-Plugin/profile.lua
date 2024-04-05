function get_profile()
    if PLANE_ICAO == "B738" then
        -- Laminar B738 / Zibo B738
        PROFILE = "B738"
    elseif PLANE_ICAO == "C750" then
        -- Laminar Citation X
        PROFILE = "laminar/CitX"
    elseif PLANE_ICAO == "B752" or PLANE_ICAO == "B753" then
        -- FlightFactor 757
        PROFILE = "FF/757"
    elseif PLANE_ICAO == "B763" or PLANE_ICAO == "B764" then
        -- FlightFactor 767
        PROFILE = "FF/767"
    elseif PLANE_ICAO == "C172" and AIRCRAFT_FILENAME == "Cessna_172SP.acf" then
        -- Laminar C172
        PROFILE = "laminar/C172"
    elseif PLANE_ICAO == "A319" or PLANE_ICAO == "A20N" or PLANE_ICAO == "A321" or PLANE_ICAO == "A21N" or PLANE_ICAO == "A346" then
        -- Toliss A32x
        PROFILE = "Toliss/32x"
    end
    write_log('INFO Aircraft identified as ' .. PLANE_ICAO .. ' with filename ' .. AIRCRAFT_FILENAME)
    write_log('INFO Using profile ' .. PROFILE)
    write_log('INFO Number of engines: ' .. NUM_ENGINES)
end

function bind_datarefs(filename)
    if filename then
        CSV_PROFILE = parseCSV(SCRIPT_DIRECTORY .. 'profiles/' .. filename)
    else
        CSV_PROFILE = parseCSV(SCRIPT_DIRECTORY .. 'profiles/' .. PLANE_ICAO .. '.csv')
    end
    if CSV_PROFILE then
        write_log('INFO Found CSV Profile for ' .. PLANE_ICAO)
        for _, value in ipairs(CSV_PROFILE) do
            local name = value["name"]
            -- write_log('INFO Binding ' .. name)
            -- dumpTable(value, 2)
            -- remove default datarefs
            pcall(table.remove, DATAREFS[name], 1)

            -- get the datarefs string
            local dataref_str = value["datarefs"]
            dataref_str = string.gsub(dataref_str, '"', '')
            -- split the datarefs string by comma
            local datarefs = splitString(dataref_str, ';')
            -- get operators
            local operators = value["operators"]
            local operators_arr = splitString(operators, ';')
            -- get thresholds
            local thresholds = value["thresholds"]
            local thresholds_arr = splitString(thresholds, ';')
            if #datarefs ~= #operators_arr or #datarefs ~= #thresholds_arr then
                write_log('Warning Dataref ' .. name .. ' - ' .. "mismatched datarefs, operators, or thresholds")
                write_log('number of datarefs: ' .. #datarefs)
                for i = 0, #datarefs - 1 do
                    table.insert(operators_arr, operators_arr[1])
                    table.insert(thresholds_arr, thresholds_arr[1])
                end
            end

            local my_tbl = {}
            -- one led might be bound to multiple datarefs
            for i, dataref in ipairs(datarefs) do
                local df_var = XPLMFindDataRef(dataref)
                if df_var ~= nil then
                    table.insert(my_tbl,
                        {
                            dataref_table(dataref),
                            operator = operators_arr[i],
                            threshold = thresholds_arr[i]
                        }
                    )
                else
                    DELAYED_LOADING = true
                    table.insert(my_tbl,
                        {
                            dataref,
                            operator = operators_arr[i],
                            threshold = thresholds_arr[i]
                        }
                    )
                    write_log('WARN Dataref ' .. dataref .. ' - ' .. "delay loading")
                end
            end
            DATAREFS[name] = {
                datarefs = my_tbl,
                conditions =
                    value["conditions"],
                description = value["description"]

            }
            -- store to logs for debugging
            dumpTable(DATAREFS)
        end
        return
    end
    write_log('INFO No CSV Profile found for ' .. PLANE_ICAO)
    XPLMSpeakString("Warning, No Honeycomb Bravo CSV Profile found for:" .. PLANE_ICAO)
end

function save_profile()
    local file = io.open(SCRIPT_DIRECTORY .. 'profiles/' .. PLANE_ICAO .. '.csv', 'w')
    file:write('name,datarefs,operators,thresholds,conditions,description\n')
    if file then
        for key, value in pairs(DATAREFS) do
            file:write(key .. ',')
            for i = 1, #value["datarefs"] do
                file:write(value["datarefs"][i][1]["refname"])
                if i < #value["datarefs"] then
                    file:write(';')
                end
            end
            file:write(',')
            for i = 1, #value["datarefs"] do
                file:write(value["datarefs"][i]["operator"])
                if i < #value["datarefs"] then
                    file:write(';')
                end
            end
            file:write(',')
            for i = 1, #value["datarefs"] do
                file:write(value["datarefs"][i]["threshold"])
                if i < #value["datarefs"] then
                    file:write(';')
                end
            end
            file:write(',')
            file:write(value["conditions"])
            file:write(',')
            if value["description"] then
                file:write(value["description"])
            else
                file:write('No description')
            end
            file:write('\n')
        end
        file:close()
        write_log('INFO Profile saved to ' .. SCRIPT_DIRECTORY .. 'profiles/' .. PLANE_ICAO .. '.csv')
    else
        write_log('ERROR Unable to save profile to ' .. SCRIPT_DIRECTORY .. 'profiles/' .. PLANE_ICAO .. '.csv')
    end
end
