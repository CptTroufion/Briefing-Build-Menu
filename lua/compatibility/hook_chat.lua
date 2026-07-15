local mod_path = ModPath

dofile(mod_path .. "lua/core/bootstrap.lua")
dofile(BriefingEnhanced.ModPath .. "lua/compatibility/adapter_chat.lua")

Hooks:Add("MenuManagerPostInitialize", "BriefingBuildMenu_MenuManagerPostInitialize", function()
	BriefingEnhanced.AdapterChat:install()
end)

