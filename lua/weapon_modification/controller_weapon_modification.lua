BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ControllerWeaponModification = BE.ControllerWeaponModification or {}

local function add_cancel_option(options)
	table.insert(options, {
		text = managers.localization:text("dialog_cancel"),
		is_cancel_button = true
	})
end

function BE.ControllerWeaponModification:show_weapon_choice()
	local options = {
		{
			text = managers.localization:text("bbm_primary_weapon"),
			callback = function()
				self:open("primaries")
			end
		},
		{
			text = managers.localization:text("bbm_secondary_weapon"),
			callback = function()
				self:open("secondaries")
			end
		}
	}

	add_cancel_option(options)

	QuickMenu:new(
		managers.localization:text("bbm_weapon_modifications"),
		managers.localization:text("bbm_weapon_choice_description"),
		options,
		true
	)
end

function BE.ControllerWeaponModification:open(category)
	if not BE.FactoryBriefingNode:ensure_all() then
		return false
	end

	local menu = BE.FactoryBriefingNode:get_kit_menu()
	local node_name = BE.ConstantsBriefingEnhanced.NODE_NAMES.weapon_modification
	local node = menu and menu.data._nodes[node_name]

	if not node then
		return false
	end

	node:parameters().menu_component_data = { category = category }

	return BE.ControllerMenuNavigation:open("weapon_modifications", node_name)
end

function BE.ControllerWeaponModification:refresh()
	local gui = managers.menu_component and managers.menu_component._be_component_weapon_modification

	if gui then
		gui:refresh()
	end
end

-- Compatibility facade for versions <= 1.6.1.
function BE:show_weapon_choice()
	return self.ControllerWeaponModification:show_weapon_choice()
end

function BE:open_weapon_modifications(category)
	return self.ControllerWeaponModification:open(category)
end

function BE:refresh_weapon_modifications_gui()
	return self.ControllerWeaponModification:refresh()
end

