-- Honeycomb Bravo Plugin Configurator version v0.0.1
-- Based on HoneycombBravoHelper for Linux https://gitlab.com/honeycomb-xplane-linux from Daniel Peukert
--   License:		GNU GPLv3
-- Based also on https://github.com/jorgeuvo/Honeycomb-Bravo-Plugin

-- dofile(SCRIPT_DIRECTORY .. "/Honeycomb-Bravo-Plugin/globals.lua")
-- dofile(SCRIPT_DIRECTORY .. "/Honeycomb-Bravo-Plugin/helpers.lua")
dofile(SCRIPT_DIRECTORY .. "/Honeycomb-Bravo-Plugin/logging.lua")
-- dofile(SCRIPT_DIRECTORY .. "/Honeycomb-Bravo-Plugin/bravo.lua")
-- dofile(SCRIPT_DIRECTORY .. "/Honeycomb-Bravo-Plugin/profile.lua")

--[[
IMGUI Blank Template
Author: Joe Kipfer 2019-06-06
Use in conjuction with Folko's IMGUI Demo script for some great examples and explaination.
When Using IMGUI Demo script mentioned above, don't forget to put the imgui demo.jpg in with it or
you'll get an error.
]]

if not SUPPORTS_FLOATING_WINDOWS then
	-- to make sure the script doesn't stop with old FlyWithLua versions
	logMsg("imgui not supported by your FlyWithLua version")
	return
end
-----------------------------------Variables go here--------------------------------------------
--Set you variables here, datarefs, etc...









-------------------------------------Build Your GUI Here----------------------------------------

function hc_bravo_configurator_on_build(hc_bravo_configurator_wnd, x, y) --<-- your GUI code goes in this section.
	for key, value in pairs(DATAREFS) do
		imgui.PushStyleColor(imgui.constant.Col.Text, 0xFFA8A800)
		imgui.TextUnformatted(key)
		imgui.PopStyleColor()
		imgui.SameLine()
		imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF00FA9A)
		imgui.TextUnformatted("   " .. value["conditions"])
		imgui.PopStyleColor()

		local datarefs = value["datarefs"]
		local buffer = {}
		for i = 1, #datarefs do
			imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF00BFFF)
			imgui.SetNextItemWidth(400)
			imgui.InputText("##" .. key .. "-" .. i .. "-refname", datarefs[i][1]["refname"], 80)
			imgui.PopStyleColor()

			imgui.SameLine()
			imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF00BFFF)
			imgui.SetNextItemWidth(40)
			imgui.InputText("##" .. key .. "-" .. i .. "-operator", datarefs[i]["operator"], 20)
			imgui.PopStyleColor()

			imgui.SameLine()
			imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF00BFFF)
			imgui.SetNextItemWidth(40)
			imgui.InputText("##" .. key .. "-" .. i .. "-threshold", datarefs[i]["threshold"], 20)
			imgui.PopStyleColor()

			imgui.SameLine()
			imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF00FA9A)
			if datarefs[i][1]["reftype"] > 4 then
				imgui.TextUnformatted("Values: [" ..
					datarefs[i][1][0] ..
					"," .. datarefs[i][1][1] ..
					"," .. datarefs[i][1][2] ..
					"," .. datarefs[i][1][3] ..
					"," .. datarefs[i][1][4] ..
					"," .. datarefs[i][1][5] ..
					"," .. datarefs[i][1][6] ..
					"," .. datarefs[i][1][7] ..
					"]")
			else
				imgui.TextUnformatted("Value: " .. datarefs[i][1][0])
			end
			imgui.PopStyleColor()


			-- imgui.TextUnformatted("   " .. datarefs[i][1]["refname"])
		end
		imgui.Spacing()

		-- imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF00BFFF)
		-- imgui.TextUnformatted("")
		-- imgui.PopStyleColor()
	end
end -- function hc_bravo_configurator_on_build

-------------------------------------------------------------------------------------------------







-------------------Show Hide Window Section with Toggle functionaility---------------------------

hc_bravo_configurator_wnd = nil           -- flag for the show_wnd set to nil so that creation below can happen - float_wnd_create

function hc_bravo_configurator_show_wnd() -- This is called when user toggles window on/off, if the next toggle is for ON
	hc_bravo_configurator_wnd = float_wnd_create(800, 500, 1, true)
	float_wnd_set_title(hc_bravo_configurator_wnd, "Honeycomb Bravo Configurator " .. VERSION)
	float_wnd_set_imgui_builder(hc_bravo_configurator_wnd, "hc_bravo_configurator_on_build")
end

function hc_bravo_configurator_hide_wnd() -- This is called when user toggles window on/off, if the next toggle is for OFF
	if hc_bravo_configurator_wnd then
		float_wnd_destroy(hc_bravo_configurator_wnd)
	end
end

hc_bravo_configurator_show_only_once = 0
hc_bravo_configurator_hide_only_once = 0

function toggle_hc_bravo_configurator_window() -- This is the toggle window on/off function
	hc_bravo_configurator_show_window = not hc_bravo_configurator_show_window
	if hc_bravo_configurator_show_window then
		if hc_bravo_configurator_show_only_once == 0 then
			hc_bravo_configurator_show_wnd()
			hc_bravo_configurator_show_only_once = 1
			hc_bravo_configurator_hide_only_once = 0
		end
	else
		if hc_bravo_configurator_hide_only_once == 0 then
			hc_bravo_configurator_hide_wnd()
			hc_bravo_configurator_hide_only_once = 1
			hc_bravo_configurator_show_only_once = 0
		end
	end
end

------------------------------------------------------------------------------------------------






----"add_macro" - adds the option to the FWL macro menu in X-Plane
----"create command" - creates a show/hide toggle command that calls the toggle_hc_bravo_configurator_window()
add_macro("Honeycomb Bravo Configurator", "hc_bravo_configurator_show_wnd()",
	"hc_bravo_configurator_hide_wnd()", "deactivate")
create_command("hc_bravo_configurator_menus/show_toggle", "open/close Honeycomb Bravo Configurator Menu window",
	"toggle_hc_bravo_configurator_window()", "", "")

--[[
footnotes:  If changing color using PushStyleColor, here are common color codes:
    BLACK       = 0xFF000000;
    DKGRAY      = 0xFF444444;
    GRAY        = 0xFF888888;
    LTGRAY      = 0xFFCCCCCC;
    WHITE       = 0xFFFFFFFF;
    RED         = 0xFFFF0000;
    GREEN       = 0xFF00FF00;
    BLUE        = 0xFF0000FF;
    YELLOW      = 0xFFFFFF00;
    CYAN        = 0xFF00FFFF;
    MAGENTA     = 0xFFFF00FF;
    ]]
