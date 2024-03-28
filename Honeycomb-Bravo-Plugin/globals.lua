-- LED definitions
LED = {
    FCU_HDG = { 1, 1 },
    FCU_NAV = { 1, 2 },
    FCU_APR = { 1, 3 },
    FCU_REV = { 1, 4 },
    FCU_ALT = { 1, 5 },
    FCU_VS = { 1, 6 },
    FCU_IAS = { 1, 7 },
    FCU_AP = { 1, 8 },
    LDG_L_GREEN = { 2, 1 },
    LDG_L_RED = { 2, 2 },
    LDG_N_GREEN = { 2, 3 },
    LDG_N_RED = { 2, 4 },
    LDG_R_GREEN = { 2, 5 },
    LDG_R_RED = { 2, 6 },
    ANC_MSTR_WARNG = { 2, 7 },
    ANC_ENG_FIRE = { 2, 8 },
    ANC_OIL = { 3, 1 },
    ANC_FUEL = { 3, 2 },
    ANC_ANTI_ICE = { 3, 3 },
    ANC_STARTER = { 3, 4 },
    ANC_APU = { 3, 5 },
    ANC_MSTR_CTN = { 3, 6 },
    ANC_VACUUM = { 3, 7 },
    ANC_HYD = { 3, 8 },
    ANC_AUX_FUEL = { 4, 1 },
    ANC_PRK_BRK = { 4, 2 },
    ANC_VOLTS = { 4, 3 },
    ANC_DOOR = { 4, 4 },
}

DEBUG_MODE = false
BRAVO = hid_open(10571, 6401)

-- Plugin Profile: a profile represents using aircraft-specific datarefs
PROFILE = "default"

-- Switches for specific plugin behavior that transcends profiles
SHOW_ANC_HYD = true
ONLY_USE_AUTOPILOT_STATE = false
local num_of_engines = dataref_table('sim/aircraft/engine/acf_num_engines')
NUM_ENGINES = num_of_engines[0]

-- Support variables & functions for sending LED data via HID
BUFFER = {}
MASTER_STATE = false
BUFFER_MODIFIED = false

-- 3rd Party Libraries
BITWISE = require 'bit'

-- Default Datarefs
DATAREFS = {
    ---- Leds
    BUS_VOLTAGE = {
        datarefs = { dataref_table('sim/cockpit2/electrical/bus_volts') },
        operators = ">",
        thresholds = 0,
        conditions = "any"
    },
    ---- Autopilot
    HDG = { datarefs = { dataref_table('sim/cockpit2/autopilot/heading_mode') } },
    NAV = { datarefs = { dataref_table('sim/cockpit2/autopilot/nav_status') } },
    APR = { datarefs = { dataref_table('sim/cockpit2/autopilot/approach_status') } },
    REV = { datarefs = { dataref_table('sim/cockpit2/autopilot/backcourse_status') } },
    ALT = { datarefs = { dataref_table('sim/cockpit2/autopilot/altitude_hold_status') } },
    VS = { datarefs = { dataref_table('sim/cockpit2/autopilot/vvi_status') } },
    IAS = { datarefs = { dataref_table('sim/cockpit2/autopilot/autothrottle_on') } },
    AP = { datarefs = { dataref_table('sim/cockpit2/autopilot/servos_on') } },
    AP_STATE = { datarefs = { dataref_table("sim/cockpit/autopilot/autopilot_state") } }, -- see https://developer.x-plane.com/article/accessing-the-x-plane-autopilot-from-datarefs}/
    ---- Landing gear LEDs
    GEAR = { datarefs = { dataref_table('sim/flightmodel2/gear/deploy_ratio') } },
    RETRACTABLE_GEAR = { datarefs = { dataref_table('sim/aircraft/gear/acf_gear_retract') } },
    ---- Annunciator panel - top row
    MASTER_WARN = { datarefs = { dataref_table('sim/cockpit2/annunciators/master_warning') } },
    FIRE = { datarefs = { dataref_table('sim/cockpit2/annunciators/engine_fires') } },
    OIL_LOW_P = { datarefs = { dataref_table('sim/cockpit2/annunciators/oil_pressure_low') } },
    FUEL_LOW_P = { datarefs = { dataref_table('sim/cockpit2/annunciators/fuel_pressure_low') } },
    ANTI_ICE = { datarefs = { dataref_table('sim/cockpit2/annunciators/pitot_heat') } },
    ANTI_ICE_FLIP = false,
    ENG_STARTER = { datarefs = { dataref_table('sim/cockpit2/engine/actuators/starter_hit') } },
    APU = { datarefs = { dataref_table('sim/cockpit2/electrical/APU_running') } },
    ---- Annunciator panel - bottom row
    MASTER_CAUTION = { datarefs = { dataref_table('sim/cockpit2/annunciators/master_caution') } },
    VACUUM = { datarefs = { dataref_table('sim/cockpit2/annunciators/low_vacuum') } },
    HYDRO_LOW_P = { datarefs = { dataref_table('sim/cockpit2/annunciators/hydraulic_pressure') } },
    AUX_FUEL_PUPM = {
        datarefs = {
            dataref_table('sim/cockpit2/fuel/transfer_pump_right'),
            dataref_table('sim/cockpit2/fuel/transfer_pump_left')
        },
        operators = "==",
        thresholds = 2,
        conditions = "any"
    },
    PARKING_BRAKE = { datarefs = { dataref_table('sim/cockpit2/controls/parking_brake_ratio') } },
    VOLT_LOW = { datarefs = { dataref_table('sim/cockpit2/annunciators/low_voltage') } },
    DOORS = { datarefs = { dataref_table('sim/flightmodel2/misc/door_open_ratio') } }
}


-- Misc
DOOR_LAST_FLASHING = -1
DOOR_LAST_STATE = true

VERSION = "v0.0.1"
