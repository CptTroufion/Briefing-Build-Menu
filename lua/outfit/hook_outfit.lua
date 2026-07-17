local mod_path = ModPath

dofile(mod_path .. "lua/core/bootstrap.lua")
dofile(BriefingEnhanced.ModPath .. "lua/outfit/service_outfit_menu.lua")

local BE = BriefingEnhanced
local Service = BE.ServiceOutfitMenu

BE.HookOutfit = BE.HookOutfit or {}

if not BE.HookOutfit.installed then
	BE.HookOutfit.installed = true

	Hooks:PostHook(BlackMarketGui, "populate_player_styles", "BriefingBuildMenu_BlackMarketGui_populate_player_styles", function(_, data)
		Service:remove_unsafe_actions(data, { "trd_preview", "trd_customize" })
	end)

	Hooks:PostHook(BlackMarketGui, "populate_gloves", "BriefingBuildMenu_BlackMarketGui_populate_gloves", function(_, data)
		Service:remove_unsafe_actions(data, { "hnd_preview", "hnd_customize" })
	end)
end
