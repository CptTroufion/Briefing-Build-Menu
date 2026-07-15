BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced
local Constants = BE.ConstantsBriefingEnhanced

BE.FactoryBriefingNode = BE.FactoryBriefingNode or {}

function BE.FactoryBriefingNode:get_kit_menu()
	local menu = managers.menu and managers.menu:get_menu("kit_menu")

	return menu and menu.data and menu.data._nodes and menu or nil
end

function BE.FactoryBriefingNode:create(menu, node_name, parameters)
	local node = CoreMenuNode.MenuNode:new({
		_meta = "node",
		name = node_name,
		menu_components = parameters.menu_components,
		topic_id = parameters.topic_id,
		scene_state = parameters.scene_state,
		back_callback = parameters.back_callback,
		modifier = parameters.modifier
	})

	for key, value in pairs(parameters.node_parameters or {}) do
		node:parameters()[key] = value
	end

	node:set_callback_handler(menu.callback_handler)
	menu.data._nodes[node_name] = node

	return node
end


function BE.FactoryBriefingNode:ensure(menu, node_name, parameters)
	return menu.data._nodes[node_name] or self:create(menu, node_name, parameters)
end


function BE.FactoryBriefingNode:ensure_all()
	local menu = self:get_kit_menu()

	if not menu then
		return false
	end

	self:ensure(menu, Constants.NODE_NAMES.skill_tree, {
		menu_components = "skilltree_new",
		topic_id = "bbm_skilltree"
	})

	local perk_deck_node = self:ensure(menu, Constants.NODE_NAMES.perk_deck, {
		menu_components = "skilltree",
		topic_id = "menu_specialization"
	})
	perk_deck_node:parameters().menu_component_data = {
		hide_skilltree = true
	}

	self:ensure(menu, Constants.NODE_NAMES.weapon_modification, {
		menu_components = Constants.WEAPON_COMPONENT,
		topic_id = "bbm_weapon_modifications"
	})

	if managers.menu_component
		and managers.menu_component._active_components
		and not managers.menu_component._active_components[Constants.WEAPON_COMPONENT] then
		managers.menu_component._active_components[Constants.WEAPON_COMPONENT] = {
			create = callback(managers.menu_component, managers.menu_component, "create_be_component_weapon_modification"),
			close = callback(managers.menu_component, managers.menu_component, "close_be_component_weapon_modification")
		}
	end

	return true
end

-- Compatibility facade for versions <= 1.6.1.
function BE:ensure_menu_nodes()
	return self.FactoryBriefingNode:ensure_all()
end
