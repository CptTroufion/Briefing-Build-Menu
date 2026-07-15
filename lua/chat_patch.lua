BriefingBuildMenu = BriefingBuildMenu or {}

function BriefingBuildMenu:install_chat_translator_patch()
	if not ChatTranslatorMessage then
		return
	end

	local function auto_translate_last(chat)
		local messages = chat._translatable_messages
		local last = messages and messages[#messages]

		if last then
			last:RequestTranslation()
		end
	end

	if ChatGui and not self._ct_chatgui_hooked then
		self._ct_chatgui_hooked = true
		Hooks:PostHook(ChatGui, "receive_message", "BriefingBuildMenu_ChatGui_receive_message", auto_translate_last)
	end

	if HUDChat and not self._ct_hudchat_hooked then
		self._ct_hudchat_hooked = true
		Hooks:PostHook(HUDChat, "receive_message", "BriefingBuildMenu_HUDChat_receive_message", auto_translate_last)
	end
end

function BriefingBuildMenu:install_chat_access_patch()
	if not self._chat_mode_hooked then
		self._chat_mode_hooked = true

		Hooks:PostHook(MenuComponentManager, "set_active_components", "BriefingBuildMenu_MenuComponentManager_set_active_components", function(component_manager)
			if not BriefingBuildMenu.opened_from_briefing then
				return
			end

			local chat = component_manager._game_chat_gui

			if chat then
				chat:set_params("inventory")
				chat:set_enabled(true)
			end
		end)
	end

	if not self._orig_key_press_controller_support then
		self._orig_key_press_controller_support = MenuComponentManager.key_press_controller_support
		local connection = managers.controller:get_settings("pc"):get_connection("toggle_chat")
		local input_names = connection and connection:get_input_name_list()
		local toggle_chat = input_names and input_names[1] and Idstring(input_names[1])

		function MenuComponentManager:key_press_controller_support(o, k)
			local chat = self._game_chat_gui

			if BriefingBuildMenu.opened_from_briefing and toggle_chat and k == toggle_chat and chat and not chat:enabled() and MenuCallbackHandler:can_toggle_chat() then
				chat:show()
				chat:open_page()

				return
			end

			return BriefingBuildMenu._orig_key_press_controller_support(self, o, k)
		end
	end
end

Hooks:Add("MenuManagerPostInitialize", "BriefingBuildMenu_MenuManagerPostInitialize", function()
	BriefingBuildMenu:install_chat_translator_patch()
	BriefingBuildMenu:install_chat_access_patch()
end)
