BriefingBuildMenu = BriefingBuildMenu or {}

local BBM = BriefingBuildMenu

local function get_kit_menu()
	local menu = managers.menu and managers.menu:get_menu("kit_menu")
	return menu and menu.data and menu.data._nodes and menu or nil
end

local function create_node(menu, node_name, parameters)
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

local function ensure_node(menu, node_name, parameters)
	return menu.data._nodes[node_name] or create_node(menu, node_name, parameters)
end

function BBM:ensure_menu_nodes()
	local menu = get_kit_menu()

	if not menu then
		return false
	end

	ensure_node(menu, self.NODE_NAMES.skilltree, {
		menu_components = "skilltree_new",
		topic_id = "bbm_skilltree"
	})

	local specialization_node = ensure_node(menu, self.NODE_NAMES.specialization, {
		menu_components = "skilltree",
		topic_id = "menu_specialization"
	})
	specialization_node:parameters().menu_component_data = {
		hide_skilltree = true
	}

	ensure_node(menu, self.NODE_NAMES.weapon_modifications, {
		menu_components = "bbm_weapon_modifications",
		topic_id = "bbm_weapon_modifications"
	})

	if managers.menu_component and not managers.menu_component._active_components.bbm_weapon_modifications then
		managers.menu_component._active_components.bbm_weapon_modifications = {
			create = callback(managers.menu_component, managers.menu_component, "create_bbm_weapon_modifications"),
			close = callback(managers.menu_component, managers.menu_component, "close_bbm_weapon_modifications")
		}
	end

	return true
end

function BBM:open_weapon_modifications(category)
	if not self:ensure_menu_nodes() then
		return
	end

	local menu = get_kit_menu()
	local node = menu and menu.data._nodes[self.NODE_NAMES.weapon_modifications]

	if not node then
		return
	end

	node:parameters().menu_component_data = { category = category }
	self:open_node("weapon_modifications", self.NODE_NAMES.weapon_modifications)
end

function BBM:open_skilltree()
	if self:ensure_menu_nodes() then
		self:open_node("skilltree", self.NODE_NAMES.skilltree)
	end
end

function BBM:open_specialization()
	if self:ensure_menu_nodes() then
		self:open_node("specialization", self.NODE_NAMES.specialization)
	end
end
