BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.AdapterChat = BE.AdapterChat or {}

local function get_toggle_chat_key()
	local controller = managers.controller and managers.controller:get_settings("pc")
	local connection = controller and controller:get_connection("toggle_chat")
	local input_names = connection and connection:get_input_name_list()

	return input_names and input_names[1] and Idstring(input_names[1]) or nil
end

local function auto_translate_last(chat)
	local messages = chat._translatable_messages
	local last = messages and messages[#messages]

	if last then
		last:RequestTranslation()
	end
end

function BE.AdapterChat:install_translator()
	if not ChatTranslatorMessage then
		return
	end

	if ChatGui and not self._chat_gui_hooked then
		self._chat_gui_hooked = true
		Hooks:PostHook(ChatGui, "receive_message", "BriefingBuildMenu_ChatGui_receive_message", auto_translate_last)
	end

	if HUDChat and not self._hud_chat_hooked then
		self._hud_chat_hooked = true
		Hooks:PostHook(HUDChat, "receive_message", "BriefingBuildMenu_HUDChat_receive_message", auto_translate_last)
	end
end

function BE.AdapterChat:install_access()
	if not self._active_components_hooked then
		self._active_components_hooked = true

		Hooks:PostHook(MenuComponentManager, "set_active_components", "BriefingBuildMenu_MenuComponentManager_set_active_components", function(component_manager)
			if not BE.StateBriefingSession:is_open() then
				return
			end

			local chat = component_manager._game_chat_gui

			if chat then
				chat:set_params("inventory")
				chat:set_enabled(true)
			end
		end)
	end

	if not self._key_press_hooked then
		self._key_press_hooked = true
		local original_key_press = Hooks:GetFunction(MenuComponentManager, "key_press_controller_support")

		Hooks:OverrideFunction(MenuComponentManager, "key_press_controller_support", function(component_manager, object, key)
			local chat = component_manager._game_chat_gui
			local toggle_chat = get_toggle_chat_key()

			if BE.StateBriefingSession:is_open()
				and toggle_chat
				and key == toggle_chat
				and chat
				and not chat:enabled()
				and MenuCallbackHandler:can_toggle_chat() then
				chat:show()
				chat:open_page()
				return
			end

			return original_key_press(component_manager, object, key)
		end)
	end
end

function BE.AdapterChat:install()
	self:install_translator()
	self:install_access()
end

-- Compatibility facade for versions <= 1.6.1.
function BE:install_chat_translator_patch()
	return self.AdapterChat:install_translator()
end

function BE:install_chat_access_patch()
	return self.AdapterChat:install_access()
end

