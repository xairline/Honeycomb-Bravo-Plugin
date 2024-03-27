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

function handle_led_changes()
	if BUS_VOLTAGE[0] > 0 or array_has_positives(BUS_VOLTAGE) then
		MASTER_STATE = true

		-- HDG & NAV
		if BITWISE.band(AP_STATE[0], 2) > 0 then
			-- Heading Select Engage
			set_led(LED.FCU_HDG, true)
			set_led(LED.FCU_NAV, false)
		elseif BITWISE.band(AP_STATE[0], 512) > 0 or BITWISE.band(AP_STATE[0], 524288) > 0 then
			-- Nav Engaged or GPSS Engaged
			set_led(LED.FCU_HDG, false)
			set_led(LED.FCU_NAV, true)
		elseif ONLY_USE_AUTOPILOT_STATE then
			-- Aircraft known to use autopilot_state
			set_led(LED.FCU_HDG, false)
			set_led(LED.FCU_NAV, false)
		else
			if PROFILE == "Toliss/32x" then
				if int_to_bool(AP[0]) or int_to_bool(AP[1]) then
					if HDG[0] == 101 then
						set_led(LED.FCU_HDG, true)
						set_led(LED.FCU_NAV, false)
					else
						set_led(LED.FCU_HDG, false)
						set_led(LED.FCU_NAV, true)
					end
				else
					set_led(LED.FCU_HDG, false)
					set_led(LED.FCU_NAV, false)
				end
			else
				-- HDG
				set_led(LED.FCU_HDG, get_ap_state(HDG))

				-- NAV
				set_led(LED.FCU_NAV, get_ap_state(NAV))
			end
		end

		-- APR
		set_led(LED.FCU_APR, get_ap_state(APR))

		-- REV
		set_led(LED.FCU_REV, get_ap_state(REV))

		-- ALT
		local alt_bool

		if ALT[0] > 1 then
			alt_bool = true
		else
			alt_bool = false
		end

		if PROFILE == "Toliss/32x" then
			if ALT[0] == 0 or (not int_to_bool(ap1[0]) and not int_to_bool(ap2[0])) then
				set_led(LED.FCU_ALT, false)
			else
				set_led(LED.FCU_ALT, true)
			end
		else
			set_led(LED.FCU_ALT, alt_bool)
		end

		-- VS
		if PROFILE == "Toliss/32x" then
			if VS[0] == 107 and (int_to_bool(ap1[0]) or int_to_bool(ap2[0])) then
				set_led(LED.FCU_VS, true)
			else
				set_led(LED.FCU_VS, false)
			end
		else
			set_led(LED.FCU_VS, get_ap_state(VS))
		end

		-- IAS
		if BITWISE.band(AP_STATE[0], 8) > 0 then
			-- Speed-by-pitch Engage AKA Flight Level Change
			-- See "Aliasing of Flight-Level Change With Speed Change" on https://developer.x-plane.com/article/accessing-the-x-plane-autopilot-from-datarefs/
			set_led(LED.FCU_IAS, true)
		else
			set_led(LED.FCU_IAS, get_ap_state(IAS))
		end

		-- AUTOPILOT
		if PROFILE == "Toliss/32x" then
			set_led(LED.FCU_AP, int_to_bool(AP[0]) or int_to_bool(AP[1]))
		else
			set_led(LED.FCU_AP, int_to_bool(AP[0]))
		end

		-- Landing gear
		local gear_leds = {}

		for i = 1, 3 do
			gear_leds[i] = { nil, nil } -- green, red

			if RETRACTABLE_GEAR[0] == 0 then
				-- No retractable landing gear
			else
				if GEAR[i - 1] == 0 then
					-- Gear stowed
					gear_leds[i][1] = false
					gear_leds[i][2] = false
				elseif GEAR[i - 1] == 1 then
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

		-- MASTER WARNING
		set_led(LED.ANC_MSTR_WARNG, int_to_bool(MASTER_WARN[0]))

		-- ENGINE/APU FIRE
		if PROFILE == 'Toliss/32x' then
			my_fire = false
			if apu_fire[20] > 0 then
				my_fire = true
			end
			for i = 11, 17 do
				if i == 11 or i == 13 or i == 15 or i == 17 then
					if eng_fire[i] ~= nil and eng_fire[i] > 0 then
						my_fire = true
						break
					end
				end
			end
			set_led(LED.ANC_ENG_FIRE, my_fire)
		else
			set_led(LED.ANC_ENG_FIRE, array_has_true(FIRE))
		end

		-- LOW OIL PRESSURE
		if PROFILE == "Toliss/32x" then
			low_oil_light = false
			for i = 0, NUM_ENGINES - 1 do
				if OIL_LOW_P[i] ~= nil and OIL_LOW_P[i] < 0.075 then
					low_oil_light = true
					break
				end
			end
			set_led(LED.ANC_OIL, low_oil_light)
		else
			set_led(LED.ANC_OIL, array_has_true(OIL_LOW_P))
		end

		-- LOW FUEL PRESSURE
		if PROFILE == "Toliss/32x" then
			low_fuel_light = false
			for i = 0, NUM_ENGINES - 1 do
				if FUEL_LOW_P[i] ~= nil and FUEL_LOW_P[i] < 0.075 then
					low_fuel_light = true
					break
				end
			end
			set_led(LED.ANC_FUEL, low_fuel_light)
		else
			set_led(LED.ANC_FUEL, array_has_true(FUEL_LOW_P))
		end

		-- ANTI ICE
		if not ANTI_ICE_FLIP then
			set_led(LED.ANC_ANTI_ICE, array_has_positives(ANTI_ICE, 10))
		else
			set_led(LED.ANC_ANTI_ICE, not array_has_positives(ANTI_ICE, 10))
		end

		-- STARTER ENGAGED
		set_led(LED.ANC_STARTER, array_has_true(ENG_STARTER))

		-- APU
		set_led(LED.ANC_APU, int_to_bool(apu[0]))

		-- MASTER CAUTION
		set_led(LED.ANC_MSTR_CTN, int_to_bool(MASTER_CAUTION[0]))

		-- VACUUM
		if PROFILE == "Toliss/32x" then
			if VACUUM[0] < 1 then
				set_led(LED.ANC_VACUUM, true)
			else
				set_led(LED.ANC_VACUUM, false)
			end
		else
			set_led(LED.ANC_VACUUM, int_to_bool(VACUUM[0]))
		end

		-- LOW HYD PRESSURE
		if PROFILE == "Toliss/32x" then
			low_hyd_light = true
			for i = 0, 2 do
				if HYDRO_LOW_P[i] > 2500 then
					low_hyd_light = false
					break
				end
			end
			set_led(LED.ANC_HYD, low_hyd_light)
		else
			if SHOW_ANC_HYD then
				set_led(LED.ANC_HYD, int_to_bool(HYDRO_LOW_P[0]))
			else
				-- For planes that don't have a hydraulic pressure annunciator
				set_led(LED.ANC_HYD, false)
			end
		end

		-- AUX FUEL PUMP
		local aux_fuel_pump_bool

		if AUX_FUEL_PUPM_L[0] == 2 or AUX_FUEL_PUPM_R[0] == 2 then
			aux_fuel_pump_bool = true
		else
			aux_fuel_pump_bool = false
		end

		set_led(LED.ANC_AUX_FUEL, aux_fuel_pump_bool)

		-- PARKING BRAKE
		local parking_brake_bool

		if PARKING_BRAKE[0] > 0 then
			parking_brake_bool = true
		else
			parking_brake_bool = false
		end

		set_led(LED.ANC_PRK_BRK, parking_brake_bool)

		-- LOW VOLTS
		if VOLT_LOW_MIN ~= -1 then
			set_led(LED.ANC_VOLTS, VOLT_LOW[0] < VOLT_LOW_MIN)
		else
			set_led(LED.ANC_VOLTS, int_to_bool(VOLT_LOW[0]))
		end

		-- DOOR
		local door_state = 0 -- 0 closed, 1 open, 2 moving

		if CANOPY[0] > 0.01 then
			if CANOPY[0] < 0.99 then
				door_state = 2
			else
				door_state = 1
			end
		end

		if door_state == 0 then
			for i = 0, 9 do
				if DOORS[i] > 0.01 then
					if DOORS[i] < 0.99 then
						door_state = 2
					else
						door_state = 1
					end
					break
				end
			end
		end

		if door_state == 0 then
			for i = 0, 9 do
				if DOORS_ARRAY[i] ~= nil then
					for _, value in ipairs(DOORS_ARRAY[i]) do
						if value > 0.01 then
							if value < 0.99 then
								door_state = 2
							else
								door_state = 1
							end
							break
						end
					end
				end
			end
		end

		if door_state == 0 then
			if CABIN_DOOR[0] > 0.01 then
				if CABIN_DOOR[0] < 0.99 then
					door_state = 2
				else
					door_state = 1
				end
			end
		end

		if door_state == 2 then
			set_led(LED.ANC_DOOR, DOOR_LAST_STATE)

			if os.clock() * 1000 - DOOR_LAST_FLASHING > 200 then
				DOOR_LAST_STATE = not DOOR_LAST_STATE
				DOOR_LAST_FLASHING = os.clock() * 1000
			end
		else
			set_led(LED.ANC_DOOR, door_state == 1)
		end
	elseif MASTER_STATE == true then
		-- No bus voltage, disable all LEDs
		MASTER_STATE = false
		all_leds_off()
	end

	-- If we have any LED changes, send them to the device
	if BUFFER_MODIFIED == true then
		send_hid_data()
	end
end