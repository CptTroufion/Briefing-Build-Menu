BriefingBuildMenu = BriefingBuildMenu or {}

local BBM = BriefingBuildMenu

local function add_cancel_option(options)
	table.insert(options, {
		text = managers.localization:text("dialog_cancel"),
		is_cancel_button = true
	})
end

function BBM:show_weapon_choice()
	local options = {
		{
			text = managers.localization:text("bbm_primary_weapon"),
			callback = callback(self, self, "open_weapon_modifications", "primaries")
		},
		{
			text = managers.localization:text("bbm_secondary_weapon"),
			callback = callback(self, self, "open_weapon_modifications", "secondaries")
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

function BBM:show_main_menu()
	if self:is_open() or not managers.system_menu then
		return
	end

	local options = {
		{
			text = managers.localization:text("bbm_skilltree"),
			callback = callback(self, self, "open_skilltree")
		},
		{
			text = managers.localization:text("menu_specialization"),
			callback = callback(self, self, "open_specialization")
		},
		{
			text = managers.localization:text("bbm_weapon_modifications"),
			callback = callback(self, self, "show_weapon_choice")
		}
	}

	if self:get_pd2builder_path() then
		table.insert(options, {
			text = managers.localization:text("bbm_import_build"),
			callback = callback(self, self, "import_build")
		})
		table.insert(options, {
			text = managers.localization:text("bbm_export_build"),
			callback = callback(self, self, "export_build")
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

Hooks:PostHook(MissionBriefingGui, "init", "BriefingBuildMenu_MissionBriefingGui_init", function(self)
	BBM:install_ehi_patch()
	BBM:reset_open_state()
	BBM:ensure_menu_nodes()

	if alive(self._panel) then
		local old_button = self._panel:child(BBM.OLD_BUTTON_NAME)

		if alive(old_button) then
			self._panel:remove(old_button)
		end

		local existing_button = self._panel:child(BBM.BUTTON_NAME)

		if alive(existing_button) then
			self._panel:remove(existing_button)
		end
	end

	local button = self._panel:text({
		name = BBM.BUTTON_NAME,
		text = utf8.to_upper(managers.localization:text("bbm_button")),
		blend_mode = "add",
		layer = 2,
		font = tweak_data.menu.pd2_large_font,
		font_size = tweak_data.menu.pd2_large_font_size * 0.85,
		color = tweak_data.screen_colors.button_stage_3
	})
	local _, _, width, height = button:text_rect()

	button:set_size(width, height)

	if alive(self._ready_button) then
		button:set_right(self._ready_button:right())
		button:set_bottom(self._ready_button:top() - 10)
	else
		button:set_rightbottom(self._panel:w() - 10, self._panel:h() - 80)
	end
end)

Hooks:PostHook(MissionBriefingGui, "hide", "BriefingBuildMenu_MissionBriefingGui_hide", function(self)
	if not BBM:is_open() then
		return
	end

	self._panel:set_alpha(0)
	self._fullscreen_panel:set_alpha(0)

	local briefing_hud = managers.hud and managers.hud._hud_mission_briefing

	if briefing_hud and briefing_hud._backdrop then
		briefing_hud._backdrop:hide()
	end
end)

Hooks:PostHook(MissionBriefingGui, "close", "BriefingBuildMenu_MissionBriefingGui_close", function(self)
	if BBM:is_open() then
		BBM:reset_open_state()
	end
end)

if not BBM._original_mouse_pressed then
	BBM._original_mouse_pressed = MissionBriefingGui.mouse_pressed

	function MissionBriefingGui:mouse_pressed(button, x, y)
		local build_button = alive(self._panel) and self._panel:child(BBM.BUTTON_NAME)

		if build_button and self._enabled and not self._displaying_asset and button == Idstring("0") and build_button:inside(x, y) then
			local state = game_state_machine and game_state_machine:current_state()

			if not (state and state.blackscreen_started and state:blackscreen_started()) then
				managers.menu_component:post_event("menu_enter")
				BBM:show_main_menu()
				return true
			end
		end

		return BBM._original_mouse_pressed(self, button, x, y)
	end
end

if not BBM._original_mouse_moved then
	BBM._original_mouse_moved = MissionBriefingGui.mouse_moved

	function MissionBriefingGui:mouse_moved(x, y)
		local build_button = alive(self._panel) and self._panel:child(BBM.BUTTON_NAME)

		if build_button and self._enabled and not self._displaying_asset and build_button:inside(x, y) then
			if not self._bbm_button_highlighted then
				self._bbm_button_highlighted = true
				managers.menu_component:post_event("highlight")
				build_button:set_color(tweak_data.screen_colors.button_stage_2)
			end

			return true, "link"
		elseif build_button and self._bbm_button_highlighted then
			self._bbm_button_highlighted = nil
			build_button:set_color(tweak_data.screen_colors.button_stage_3)
		end

		return BBM._original_mouse_moved(self, x, y)
	end
end
