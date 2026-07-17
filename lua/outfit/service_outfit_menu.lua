BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ServiceOutfitMenu = BE.ServiceOutfitMenu or {}

local CONTEXT_MARKER = "briefing_enhanced_outfit"

local function create_tab(name, populate_method, category, identifier)
	return {
		name = name,
		on_create_func_name = populate_method,
		category = category,
		override_slots = { 3, 3 },
		identifier = identifier,
		[CONTEXT_MARKER] = true
	}
end

local function remove_action(item, action_name)
	for index = #item, 1, -1 do
		if item[index] == action_name then
			table.remove(item, index)
		end
	end
end

function BE.ServiceOutfitMenu:create_node_data(selected_tab)
	local data = {
		create_tab(
			"bm_menu_player_styles",
			"populate_player_styles",
			"player_styles",
			BlackMarketGui.identifiers.player_style
		),
		create_tab(
			"bm_menu_gloves",
			"populate_gloves",
			"gloves",
			BlackMarketGui.identifiers.glove
		)
	}

	data.topic_id = "bm_menu_outfits"
	data.selected_tab = selected_tab
	data.skip_blur = true
	data.use_bgs = true
	data.panel_grid_w_mul = 0.6
	data.is_loadout = true
	data[CONTEXT_MARKER] = true

	return data
end

function BE.ServiceOutfitMenu:remove_unsafe_actions(data, action_names)
	if type(data) ~= "table" or not data[CONTEXT_MARKER] then
		return
	end

	for _, item in ipairs(data) do
		if type(item) == "table" then
			for _, action_name in ipairs(action_names) do
				remove_action(item, action_name)
			end
		end
	end
end
