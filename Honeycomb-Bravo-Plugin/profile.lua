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
        NUM_ENGINES = 2
        if PLANE_ICAO == "A346" then
            NUM_ENGINES = 4
        end
    end
    write_log('INFO Aircraft identified as ' .. PLANE_ICAO .. ' with filename ' .. AIRCRAFT_FILENAME)
    write_log('INFO Using profile ' .. PROFILE)
end

function get_datarefs()
    if PLANE_ICAO == "C172" or PLANE_ICAO == "SR22" then
        SHOW_ANC_HYD = false
        ONLY_USE_AUTOPILOT_STATE = true -- as the normal hdg and nav datarefs indicate hdg when they shouldn't
    end
    
    -- Disable the hydraulics annunciator on SEL aircraft, see https://forums.x-plane.org/index.php?/files/file/89635-honeycomb-bravo-plugin/&do=findComment&comment=396048
    if
        PLANE_ICAO == "C172" or
        PLANE_ICAO == "SR22" or
        PLANE_ICAO == "SR20" or
        PLANE_ICAO == "S22T" or
        PLANE_ICAO == "SR22T" or
        PLANE_ICAO == "P28A" or
        PLANE_ICAO == "C208" or
        PLANE_ICAO == "K100" or
        PLANE_ICAO == "KODI" or
        PLANE_ICAO == "DA40" or
        PLANE_ICAO == "RV10" or
        false then
        SHOW_ANC_HYD = false
    end

    -- Bus voltage as a master LED switch
    if PROFILE == "laminar/CitX" then
        -- On the C750 bus_volts is only on when the Standby Power is on, but the lights and indicators in the sim are on before that
        BUS_VOLTAGE = dataref_table('laminar/CitX/APU/DC_volts')
    elseif PROFILE == "B738" then
        BUS_VOLTAGE = dataref_table('laminar/B738/electric/batbus_status')
    elseif PROFILE == "Toliss/32x" then
        BUS_VOLTAGE = dataref_table('AirbusFBW/DCBusVoltages')
    end

    -- AP
    if PROFILE == "B738" then
        HDG = dataref_table('laminar/B738/autopilot/hdg_sel_status')
        NAV = dataref_table('laminar/B738/autopilot/lnav_status')
        APR = dataref_table('laminar/B738/autopilot/app_status')
        REV = dataref_table('laminar/B738/autopilot/vnav_status1')
        ALT = dataref_table('laminar/B738/autopilot/alt_hld_status')
        VS = dataref_table('laminar/B738/autopilot/vs_status')
        IAS = dataref_table('laminar/B738/autopilot/speed_status1')
        AP = dataref_table('laminar/B738/autopilot/cmd_a_status')
    elseif PROFILE == "Toliss/32x" then
        HDG = dataref_table('AirbusFBW/APLateralMode') -- 101
        NAV = dataref_table('AirbusFBW/APLateralMode') -- 1
        APR = dataref_table('AirbusFBW/APPRilluminated')
        REV = dataref_table('AirbusFBW/ENGRevArray')
        ALT = dataref_table('AirbusFBW/ALTmanaged')    -- 101
        VS = dataref_table('AirbusFBW/APVerticalMode') --107
        IAS = dataref_table('AirbusFBW/SPDmanaged')
        AP = { dataref_table('AirbusFBW/AP1Engage'), dataref_table('AirbusFBW/AP2Engage') }
    end

    -- Annunciator panel - top row
    if PROFILE == "B738" then
        FIRE = dataref_table('laminar/B738/annunciator/six_pack_fire')
        FUEL_LOW_P = dataref_table('laminar/B738/annunciator/six_pack_fuel')
        ANTI_ICE = dataref_table('laminar/B738/annunciator/six_pack_ice')
    elseif PROFILE == "FF/757" or PROFILE == "FF/767" then
        MASTER_WARN = dataref_table('inst/loopwarning')
        FIRE = dataref_table('sim/cockpit/warnings/annunciators/engine_fires')
        ANTI_ICE = dataref_table('sim/cockpit2/ice/ice_window_heat_on')
        ANTI_ICE_FLIP = true
    elseif PROFILE == "Toliss/32x" then
        MASTER_WARN = dataref_table('AirbusFBW/MasterWarn')
        apu_fire = dataref_table('AirbusFBW/OHPLightsATA26')
        eng_fire = dataref_table('AirbusFBW/OHPLightsATA70')
        OIL_LOW_P = dataref_table('AirbusFBW/ENGOilPressArray')
        FUEL_LOW_P = dataref_table('AirbusFBW/ENGFuelFlowArray')
        ANTI_ICE = dataref_table('AirbusFBW/OHPLightsATA30')
        ENG_STARTER = dataref_table('AirbusFBW/StartValveArray')
        apu = dataref_table('AirbusFBW/APUAvail')
    end

    -- Annunciator panel - bottom row
    if PROFILE == "B738" then
        MASTER_CAUTION = dataref_table('laminar/B738/annunciator/master_caution_light')
        HYDRO_LOW_P = dataref_table('laminar/B738/annunciator/six_pack_hyd')
        PARKING_BRAKE = dataref_table('laminar/B738/annunciator/parking_brake')
        DOORS = dataref_table('laminar/B738/annunciator/six_pack_doors')
        CABIN_DOOR = dataref_table('laminar/B738/toggle_switch/flt_dk_door')
    elseif PROFILE == "FF/757" then
        MASTER_CAUTION = dataref_table('inst/warning')
        DOORS_ARRAY[0] = dataref_table('anim/door/FL')
        DOORS_ARRAY[1] = dataref_table('anim/door/FR')
        DOORS_ARRAY[2] = dataref_table('anim/door/ML')
        DOORS_ARRAY[3] = dataref_table('anim/door/MR')
        DOORS_ARRAY[4] = dataref_table('anim/door/BL')
        DOORS_ARRAY[5] = dataref_table('anim/door/BR')
        DOORS_ARRAY[6] = dataref_table('1-sim/anim/doors/cargoBack/anim')
        DOORS_ARRAY[7] = dataref_table('1-sim/anim/doors/cargoSide/anim')
        DOORS_ARRAY[8] = dataref_table('anim/doorC') -- 757 freighter cargo door
        VOLT_LOW = dataref_table('sim/cockpit2/electrical/bus_volts')
        VOLT_LOW_MIN = 28
    elseif PROFILE == "FF/767" then
        MASTER_CAUTION = dataref_table('sim/cockpit/warnings/annunciators/master_caution')
        DOORS_ARRAY[0] = dataref_table('1-sim/anim/doors/FL/anim')
        DOORS_ARRAY[1] = dataref_table('1-sim/anim/doors/FR/anim')
        DOORS_ARRAY[2] = dataref_table('1-sim/anim/doors/BL/anim')
        DOORS_ARRAY[3] = dataref_table('1-sim/anim/doors/BR/anim')
        DOORS_ARRAY[4] = dataref_table('1-sim/anim/doors/cargoFront/anim')
        DOORS_ARRAY[5] = dataref_table('1-sim/anim/doors/cargoBack/anim')
        DOORS_ARRAY[6] = dataref_table('1-sim/anim/doors/cargoSide/anim')
        VOLT_LOW = dataref_table('sim/cockpit2/electrical/bus_volts')
        VOLT_LOW_MIN = 25
    elseif PROFILE == "Toliss/32x" then
        MASTER_CAUTION = dataref_table('AirbusFBW/MasterCaut')
        VACUUM = dataref_table('sim/cockpit/misc/vacuum')
        HYDRO_LOW_P = dataref_table('AirbusFBW/HydSysPressArray')
        -- aux_fuel_pump_l = dataref_table('sim/cockpit/switches/fuel_pump_l')
        -- aux_fuel_pump_r = dataref_table('sim/cockpit/switches/fuel_pump_r')
        PARKING_BRAKE = dataref_table('AirbusFBW/ParkBrake')
        -- this dataref indicates whether the battery is charging, not the actual voltage
        VOLT_LOW = dataref_table('sim/cockpit2/electrical/battery_amps')
        VOLT_LOW_MIN = 0
        -- canopy = dataref_table('sim/cockpit/switches/canopy_open')
        -- doors = dataref_table('sim/cockpit/switches/door_open')
        CABIN_DOOR = dataref_table('AirbusFBW/PaxDoorArray')
        DOORS_ARRAY[0] = dataref_table('AirbusFBW/PaxDoorArray')
        DOORS_ARRAY[1] = dataref_table('AirbusFBW/CargoDoorArray')
        DOORS_ARRAY[2] = dataref_table('AirbusFBW/BulkDoor')
    elseif PROFILE == 'DH8D' then
        VOLT_LOW = dataref_table('sim/cockpit2/electrical/battery_voltage_actual_volts')
        VOLT_LOW_MIN = 20
        CABIN_DOOR = dataref_table('FJS/Q4XP/Manips/CabinMainDoor_Anim')
        DOORS_ARRAY[0] = dataref_table('FJS/Q4XP/Manips/CabinDoors_Anim')
        DOORS_ARRAY[1] = dataref_table('FJS/Q4XP/Manips/CargoDoor_Anim')
    end
end
