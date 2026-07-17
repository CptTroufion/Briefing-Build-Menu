BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced
local Service = BE.ServiceOutfitMenu

BE.ControllerOutfit = BE.ControllerOutfit or {}

local PLAYER_STYLES_TAB = 1
local GLOVES_TAB = 2

function BE.ControllerOutfit:open_tab(selected_tab)
	if BE.StateBriefingSession:is_open() then
		return false
	end

	local active_menu = managers.menu and managers.menu:active_menu()
	local kit_menu = managers.menu and managers.menu:get_menu("kit_menu")
	local loadout_node = kit_menu and kit_menu.data and kit_menu.data._nodes and kit_menu.data._nodes.loadout

	if not active_menu
		or active_menu.id ~= "kit_menu"
		or not loadout_node
		or not BlackMarketGui
		or not BlackMarketGui.identifiers then
		BE.ServiceDialog:show_error("bbm_open_error", "The briefing outfit menu is unavailable.")
		return false
	end

	local node_data = Service:create_node_data(selected_tab)
	local success, error_message = pcall(managers.menu.open_node, managers.menu, "loadout", { node_data })

	if not success then
		BE.ServiceDialog:show_error("bbm_open_error", error_message)
		return false
	end

	local menu_component = managers.menu_component

	if menu_component and menu_component.on_ready_pressed_mission_briefing_gui then
		menu_component:on_ready_pressed_mission_briefing_gui(false)
	end

	return true
end

function BE.ControllerOutfit:open_player_styles()
	return self:open_tab(PLAYER_STYLES_TAB)
end

function BE.ControllerOutfit:open_gloves()
	return self:open_tab(GLOVES_TAB)
end
