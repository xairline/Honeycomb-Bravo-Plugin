-- This Lua script contains functions related to the Honeycomb Bravo Throttle Quadrant.
-- It includes functions to check if the Bravo Throttle Quadrant is connected, get and set the state of LEDs,
-- turn off all LEDs, and send HID data to the Bravo Throttle Quadrant.

-- Function: check_bravo()
-- Description: Checks if the Honeycomb Bravo Throttle Quadrant is connected.
-- If not connected, it logs an error message and sets the DEBUG_MODE flag to true.
-- If connected, it logs an info message.
-- Parameters: None
function check_bravo()
    if BRAVO == nil then
        write_log('ERROR No Honeycomb Bravo Throttle Quadrant detected. Debug mode only.')
        -- text to speech warning so a pilot doesn't waste time setting up the flight
        --   only to find bravo is not connected
        XPLMSpeakString("No Honeycomb Bravo Throttle Quadrant detected. Debug mode only.")
        DEBUG_MODE = true
    else
        write_log('INFO Honeycomb Bravo Throttle Quadrant detected.')
    end
end

-- Function: set_led(led, state)
-- Description: Sets the state of a specific LED.
-- If the state is different from the current state, it updates the LED state in the BUFFER table
-- and sets the BUFFER_MODIFIED flag to true.
-- Parameters:
--   - led: A table containing the bank and bit of the LED.
--   - state: The state to set the LED to (true for on, false for off).
function set_led(led, state)
    if state ~= get_led(led) then
        BUFFER[led[1]][led[2]] = state
        BUFFER_MODIFIED = true
    end
end

-- Function: all_leds_off()
-- Description: Turns off all LEDs by setting the state of all LEDs in the BUFFER table to false.
-- It also sets the BUFFER_MODIFIED flag to true.
-- Parameters: None
function all_leds_off()
    for bank = 1, 4 do
        BUFFER[bank] = {}
        for bit = 1, 8 do
            BUFFER[bank][bit] = false
        end
    end

    BUFFER_MODIFIED = true
end

-- Function: send_hid_data()
-- Description: Sends HID data to the Honeycomb Bravo Throttle Quadrant.
-- It converts the state of LEDs in the BUFFER table to a byte array and sends it as a feature report.
-- If DEBUG_MODE is true, it writes the LED states to the log instead of sending the feature report.
-- Parameters: None
function send_hid_data()
    local data = {}

    for bank = 1, 4 do
        data[bank] = 0

        for bit = 1, 8 do
            if BUFFER[bank][bit] == true then
                data[bank] = BITWISE.bor(data[bank], BITWISE.lshift(1, bit - 1))
            end
        end
    end
    local bytes_written = 2147483647
    if not DEBUG_MODE then
        bytes_written = hid_send_filled_feature_report(BRAVO, 0, 65, data[1], data[2], data[3], data[4]) -- 65 = 1 byte (report ID) + 64 bytes (data)
    else
        write_leds_to_log(BUFFER)
    end
    if bytes_written == -1 then
        write_log('ERROR Feature report write failed, an error occurred')
    elseif bytes_written < 65 then
        write_log('ERROR Feature report write failed, only ' .. bytes_written .. ' bytes written')
    else
        BUFFER_MODIFIED = false
    end
end

-- Function: get_led(led)
-- Description: Gets the state of a specific LED.
-- Parameters:
--   - led: A table containing the bank and bit of the LED.
-- Returns:
--   - The state of the LED (true for on, false for off).
function get_led(led)
    return BUFFER[led[1]][led[2]]
end

function exit_handler()
    all_leds_off()
    send_hid_data()
end

function nav_hdg_led()
    -- HDG & NAV
    if BITWISE.band(DATAREFS['AP_STATE'].datarefs[1][0], 2) > 0 then
        -- Heading Select Engage
        set_led(LED.FCU_HDG, true)
        set_led(LED.FCU_NAV, false)
    elseif BITWISE.band(DATAREFS['AP_STATE'].datarefs[1][0], 512) > 0 or BITWISE.band(DATAREFS['AP_STATE'].datarefs[1][0], 524288) > 0 then
        -- Nav Engaged or GPSS Engaged
        set_led(LED.FCU_HDG, false)
        set_led(LED.FCU_NAV, true)
    elseif ONLY_USE_AUTOPILOT_STATE then
        -- Aircraft known to use autopilot_state
        set_led(LED.FCU_HDG, false)
        set_led(LED.FCU_NAV, false)
    else
        -- HDG
        set_led(LED.FCU_HDG, check_datarefs(DATAREFS['AP']) and check_datarefs(DATAREFS['HDG']))

        -- NAV
        set_led(LED.FCU_NAV, check_datarefs(DATAREFS['AP']) and check_datarefs(DATAREFS['NAV']))
    end
end

function ias_led()
    -- IAS
    if BITWISE.band(DATAREFS['AP_STATE'].datarefs[1][0], 8) > 0 then
        -- Speed-by-pitch Engage AKA Flight Level Change
        -- See "Aliasing of Flight-Level Change With Speed Change" on https://developer.x-plane.com/article/accessing-the-x-plane-autopilot-from-datarefs/
        set_led(LED.FCU_IAS, true)
    else
        set_led(LED.FCU_IAS, check_datarefs(DATAREFS['AP']) and check_datarefs(DATAREFS['IAS']))
    end
end

function landing_gear_led()
    -- Landing gear
    local gear_leds = {}

    for i = 1, 3 do
        gear_leds[i] = { nil, nil } -- green, red

        if DATAREFS.RETRACTABLE_GEAR.datarefs[0][0] == 0 then
            -- No retractable landing gear
        else
            if DATAREFS.GEAR.datarefs[0][i - 1] == 0 then
                -- Gear stowed
                gear_leds[i][1] = false
                gear_leds[i][2] = false
            elseif DATAREFS.GEAR.datarefs[0][i - 1] == 1 then
                -- Gear deployed
                gear_leds[i][1] = true
                gear_leds[i][2] = false
            else
                -- Gear moving
                gear_leds[i][1] = false
                gear_leds[i][2] = true
            end
        end
    end

    set_led(LED.LDG_N_GREEN, gear_leds[1][1])
    set_led(LED.LDG_N_RED, gear_leds[1][2])
    set_led(LED.LDG_L_GREEN, gear_leds[2][1])
    set_led(LED.LDG_L_RED, gear_leds[2][2])
    set_led(LED.LDG_R_GREEN, gear_leds[3][1])
    set_led(LED.LDG_R_RED, gear_leds[3][2])
end

function door_led()
    -- DOOR
    -- local door_state = 0 -- 0 closed, 1 open, 2 moving
    set_led(LED.ANC_DOOR, check_datarefs(DATAREFS['DOORS']))
end

function handle_led_changes()
    if not check_datarefs(DATAREFS['BUS_VOLTAGE']) then
        MASTER_STATE = false
        all_leds_off()
        send_hid_data()
        return
    end

    nav_hdg_led()
    ias_led()
    landing_gear_led()
    door_led()
    set_led(LED.ANC_VACUUM, check_datarefs(DATAREFS['VACUUM']))
    set_led(LED.ANC_HYD, check_datarefs(DATAREFS['HYDRO_LOW_P']))
    set_led(LED.ANC_AUX_FUEL, check_datarefs(DATAREFS['AUX_FUEL_PUPM']))
    set_led(LED.ANC_PRK_BRK, check_datarefs(DATAREFS['PARKING_BRAKE']))
    set_led(LED.ANC_VOLTS, check_datarefs(DATAREFS['VOLT_LOW']))
    set_led(LED.FCU_ALT, check_datarefs(DATAREFS['AP']) and check_datarefs(DATAREFS['ALT']))
    set_led(LED.FCU_VS, check_datarefs(DATAREFS['AP']) and check_datarefs(DATAREFS['VS']))
    set_led(LED.FCU_AP, check_datarefs(DATAREFS['AP']))
    set_led(LED.ANC_ENG_FIRE, check_datarefs(DATAREFS['FIRE']))
    set_led(LED.ANC_OIL, check_datarefs(DATAREFS['OIL_LOW_P'], NUM_ENGINES))
    set_led(LED.ANC_FUEL, check_datarefs(DATAREFS['FUEL_LOW_P'], NUM_ENGINES))
    set_led(LED.ANC_ANTI_ICE, check_datarefs(DATAREFS['ANTI_ICE']))
    set_led(LED.FCU_APR, check_datarefs(DATAREFS['APR']))
    set_led(LED.FCU_REV, check_datarefs(DATAREFS['REV']))
    set_led(LED.ANC_MSTR_WARNG, check_datarefs(DATAREFS['MASTER_WARN']))
    set_led(LED.ANC_STARTER, check_datarefs(DATAREFS['ENG_STARTER']))
    set_led(LED.ANC_APU, check_datarefs(DATAREFS['APU']))
    set_led(LED.ANC_MSTR_CTN, check_datarefs(DATAREFS['MASTER_CAUTION']))

    -- If we have any LED changes, send them to the device
    if BUFFER_MODIFIED == true then
        send_hid_data()
    end
end
