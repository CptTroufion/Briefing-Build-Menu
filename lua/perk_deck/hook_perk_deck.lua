local mod_path = ModPath

dofile(mod_path .. "lua/core/bootstrap.lua")
dofile(BriefingEnhanced.ModPath .. "lua/perk_deck/controller_perk_deck.lua")

local BE = BriefingEnhanced

BE.HookPerkDeck = BE.HookPerkDeck or {}

if not BE.HookPerkDeck.installed then
	BE.HookPerkDeck.installed = true

	Hooks:PostHook(SpecializationGuiNew, "close", "BriefingBuildMenu_SpecializationGuiNew_close", function()
		BE.StateBriefingSession:finish("specialization")
	end)
end

