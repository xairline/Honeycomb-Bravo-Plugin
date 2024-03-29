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

function bind_datarefs()
    CSV_PROFILE = parseCSV(SCRIPT_DIRECTORY .. 'profiles/' .. PLANE_ICAO .. '.csv')
    if CSV_PROFILE then
        write_log('INFO Found CSV Profil for ' .. PLANE_ICAO)
        for _, value in ipairs(CSV_PROFILE) do
            local name = value["name"]
            write_log('INFO Binding ' .. name)
            dumpTable(value, 2)
            -- remove default datarefs
            pcall(table.remove, DATAREFS[name], 1)

            -- get the datarefs string
            local dataref_str = value["datarefs"]
            dataref_str = string.gsub(dataref_str, '"', '')
            -- split the datarefs string by comma
            local datarefs = splitString(dataref_str, ';')
            local my_tbl = {}
            -- one led might be bound to multiple datarefs
            for _, dataref in ipairs(datarefs) do
                table.insert(my_tbl, dataref_table(dataref))
            end
            DATAREFS[name] = {
                datarefs = my_tbl,
                operators = value["operators"],
                thresholds = value["thresholds"],
                conditions =
                    value["conditions"]
            }
            -- store to logs for debugging
            -- dumpTable(DATAREFS)
        end
        return
    end
    write_log('INFO No CSV Profile found for ' .. PLANE_ICAO)
    XPLMSpeakString("Warning, No Honeycomb Bravo CSV Profile found for:" .. PLANE_ICAO)
end
