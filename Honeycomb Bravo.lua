-- Honeycomb Bravo Plugin Script version v0.0.1
-- Based on HoneycombBravoHelper for Linux https://gitlab.com/honeycomb-xplane-linux from Daniel Peukert
--   License:		GNU GPLv3
-- Based also on https://github.com/jorgeuvo/Honeycomb-Bravo-Plugin

dofile(SCRIPT_DIRECTORY .. "/Honeycomb-Bravo-Plugin/globals.lua")
dofile(SCRIPT_DIRECTORY .. "/Honeycomb-Bravo-Plugin/helpers.lua")
dofile(SCRIPT_DIRECTORY .. "/Honeycomb-Bravo-Plugin/logging.lua")
dofile(SCRIPT_DIRECTORY .. "/Honeycomb-Bravo-Plugin/bravo.lua")
dofile(SCRIPT_DIRECTORY .. "/Honeycomb-Bravo-Plugin/profile.lua")


check_bravo()
get_profile()

-- Initialize our default state
all_leds_off()
send_hid_data()
--   load default datarefs
bind_datarefs("sample.csv")
hid_open(10571, 6401) -- MacOS Bravo must be reopened for .joy axes to operate
xpcall(bind_datarefs, exit_handler)

-- register flight loop callback
do_every_frame('handle_led_changes()')
do_on_exit('exit_handler()')

-------------------------- TODO ---------------------------
-- code below is not yet organized into the above structure
-----------------------------------------------------------

-- Register commands for switching autopilot modes used by the rotary encoder
local mode = 'IAS'

function setMode(modeString)
	mode = modeString
end

create_command(
	'HoneycombBravo/mode_ias',
	'Set autopilot rotary encoder mode to IAS.',
	'setMode("IAS")',
	'',
	''
)

create_command(
	'HoneycombBravo/mode_crs',
	'Set autopilot rotary encoder mode to CRS.',
	'setMode("CRS")',
	'',
	''
)

create_command(
	'HoneycombBravo/mode_hdg',
	'Set autopilot rotary encoder mode to HDG.',
	'setMode("HDG")',
	'',
	''
)

create_command(
	'HoneycombBravo/mode_vs',
	'Set autopilot rotary encoder mode to VS.',
	'setMode("VS")',
	'',
	''
)

create_command(
	'HoneycombBravo/mode_alt',
	'Set autopilot rotary encoder mode to ALT.',
	'setMode("ALT")',
	'',
	''
)

-- Commands for changing values of the selected autopilot mode with the rotary encoder for Default Aircrafts.
local airspeed_is_mach = dataref_table('sim/cockpit2/autopilot/airspeed_is_mach')
local airspeed = dataref_table('sim/cockpit2/autopilot/airspeed_dial_kts_mach')
local course = dataref_table('sim/cockpit2/radios/actuators/nav1_obs_deg_mag_pilot')
local heading = dataref_table('sim/cockpit2/autopilot/heading_dial_deg_mag_pilot')
local vs = dataref_table('sim/cockpit2/autopilot/vvi_dial_fpm')
local altitude = dataref_table('sim/cockpit2/autopilot/altitude_dial_ft')

-- Acceleration parameters
local last_mode = mode
local last_time = os.clock() - 10 -- arbitrarily in the past

local number_of_turns = 0
local factor = 1
local fast_threshold = 5 -- number of turns in 1 os.clock() interval to engage 'fast' mode
local fast_ias = 2
local fast_crs = 5
local fast_hdg = 5
local fast_vs = 1
local fast_alt = 10

local vs_multiple = 50
local alt_multiple = 100

if PROFILE == "laminar/C172" then
	altitude = dataref_table('sim/cockpit/autopilot/current_altitude')

	-- 20ft at a time and no acceleration factor to match simulated flight control
	alt_multiple = 20
	fast_alt = 1
elseif PROFILE == "B738" then
	airspeed_is_mach = dataref_table('laminar/B738/autopilot/mcp_speed_dial_kts_mach')
	airspeed = dataref_table('laminar/B738/autopilot/mcp_speed_dial_kts')
	course = dataref_table('laminar/B738/autopilot/course_pilot')
	heading = dataref_table('laminar/B738/autopilot/mcp_hdg_dial')
	altitude = dataref_table('laminar/B738/autopilot/mcp_alt_dial')
	vs_multiple = 100
elseif PROFILE == "FF/757" or PROFILE == "FF/767" then
	airspeed = dataref_table('757Avionics/ap/spd_act')
	course = dataref_table('sim/cockpit/radios/nav2_obs_degm') -- nav2 targets ILS rather than VOR on nav1
	heading = dataref_table('757Avionics/ap/hdg_act')
	vs = dataref_table('757Avionics/ap/vs_act')
	altitude = dataref_table('757Avionics/ap/alt_act')
	vs_multiple = 100
	-- elseif PROFILE == "MD11" then
	-- 	altitude = dataref_table('Rotate/aircraft/controls_c/fgs_alt_sel_up')
end

function change_value(increase)
	local sign
	local vs_string
	local alt_string

	if increase == true then
		sign = 1
	else
		sign = -1
	end

	if mode == last_mode and os.clock() < last_time + 1 then
		number_of_turns = number_of_turns + 1
	else
		number_of_turns = 0
		factor = 1
	end

	if number_of_turns > fast_threshold then
		if mode == 'IAS' then
			factor = fast_ias
		elseif mode == 'CRS' then
			factor = fast_crs
		elseif mode == 'HDG' then
			factor = fast_hdg
		elseif mode == 'VS' then
			factor = fast_vs
		elseif mode == 'ALT' then
			factor = fast_alt
		else
			factor = 1
		end
	else
		factor = 1
	end

	if mode == 'IAS' then
		if airspeed_is_mach[0] == 1 then
			-- Float math is not precise, so we have to round the result
			airspeed[0] = math.max(0, (math.floor((airspeed[0] * 100) + 0.5) + (sign * factor)) / 100) -- changed for kts in else below, have not tested this yet
		else
			airspeed[0] = math.max(0, (math.floor(airspeed[0]) + (sign * factor)))
		end
		if PROFILE == "MD11" then
			if increase == true then
				command_once("Rotate/aircraft/controls_c/fgs_spd_sel_up")
			else
				command_once("Rotate/aircraft/controls_c/fgs_spd_sel_dn")
			end
		end
	elseif mode == 'CRS' then
		if course[0] == 0 and sign == -1 then
			course[0] = 359
		else
			course[0] = (course[0] + (sign * factor)) % 360
		end
	elseif mode == 'HDG' then
		if heading[0] == 0 and sign == -1 then
			heading[0] = 359
		else
			heading[0] = (heading[0] + (sign * factor)) % 360
		end
		if PROFILE == "MD11" then
			if increase == true then
				command_once("Rotate/aircraft/controls_c/fgs_hdg_sel_up")
			else
				command_once("Rotate/aircraft/controls_c/fgs_hdg_sel_dn")
			end
		end
	elseif mode == 'VS' then
		vs[0] = math.floor((vs[0] / vs_multiple) + (sign * factor)) * vs_multiple
		if PROFILE == "MD11" then
			if increase == true then
				command_once("Rotate/aircraft/controls_c/fgs_pitch_sel_up")
			else
				command_once("Rotate/aircraft/controls_c/fgs_pitch_sel_dn")
			end
		end
	elseif mode == 'ALT' then
		altitude[0] = math.max(0, math.floor((altitude[0] / alt_multiple) + (sign * factor)) * alt_multiple)
		if PROFILE == "MD11" then
			if increase == true then
				command_once("Rotate/aircraft/controls_c/fgs_alt_sel_up")
			else
				command_once("Rotate/aircraft/controls_c/fgs_alt_sel_dn")
			end
		end
	end
	last_mode = mode
	last_time = os.clock()
end

create_command(
	'HoneycombBravo/increase',
	'Increase the value of the autopilot mode selected with the rotary encoder.',
	'change_value(true)',
	'',
	''
)

create_command(
	'HoneycombBravo/decrease',
	'Decrease the value of the autopilot mode selected with the rotary encoder.',
	'change_value(false)',
	'',
	''
)

-- Register commands for keeping thrust reversers (all or separate engines) on while the commands are active
local reversers = dataref_table('sim/cockpit2/engine/actuators/prop_mode')

function get_prop_mode(state)
	if state == true then
		return 3
	else
		return 1
	end
end

function reversers_all(state)
	for i = 0, 7 do
		reversers[i] = get_prop_mode(state)
	end
end

function reverser(engine, state)
	reversers[engine - 1] = get_prop_mode(state)
end

create_command(
	'HoneycombBravo/thrust_reversers',
	'Hold all thrust reversers on.',
	'reversers_all(true)',
	'',
	'reversers_all(false)'
)

for i = 1, 8 do
	create_command(
		'HoneycombBravo/thrust_reverser_' .. i,
		'Hold thrust reverser #' .. i .. ' on.',
		'reverser(' .. i .. ', true)',
		'',
		'reverser(' .. i .. ', false)'
	)
end
