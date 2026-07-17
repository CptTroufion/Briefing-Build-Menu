BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ControllerBriefingMenu = BE.ControllerBriefingMenu or {}

local function add_cancel_option(options)
	table.insert(options, {
		text = managers.localization:text("dialog_cancel"),
		is_cancel_button = true
	})
end

function BE.ControllerBriefingMenu:show()
	if BE.StateBriefingSession:is_open() or not managers.system_menu then
		return
	end

	local options = {
		{
			text = managers.localization:text("bbm_skilltree"),
			callback = function()
				BE.ControllerSkillTree:open()
			end
		},
		{
			text = managers.localization:text("menu_specialization"),
			callback = function()
				BE.ControllerPerkDeck:open()
			end
		},
		{
			text = managers.localization:text("bm_menu_player_styles"),
			callback = function()
				BE.ControllerOutfit:open_player_styles()
			end
		},
		{
			text = managers.localization:text("bm_menu_gloves"),
			callback = function()
				BE.ControllerOutfit:open_gloves()
			end
		},
		{
			text = managers.localization:text("bbm_weapon_modifications"),
			callback = function()
				BE.ControllerWeaponModification:show_weapon_choice()
			end
		}
	}

	if BE.AdapterPd2Builder and BE.AdapterPd2Builder:is_available() then
		table.insert(options, {
			text = managers.localization:text("bbm_import_build"),
			callback = function()
				BE.AdapterPd2Builder:import_build()
			end
		})
		table.insert(options, {
			text = managers.localization:text("bbm_export_build"),
			callback = function()
				BE.AdapterPd2Builder:export_build()
			end
		})
	end

	add_cancel_option(options)

	QuickMenu:new(
		managers.localization:text("bbm_dialog_title"),
		managers.localization:text("bbm_dialog_text"),
		options,
		true
	)
end

-- Compatibility facade for versions <= 1.6.1.
function BE:show_main_menu()
	return self.ControllerBriefingMenu:show()
end
