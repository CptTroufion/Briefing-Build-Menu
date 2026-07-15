BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}
BriefingBuildMenu = BriefingEnhanced

local BE = BriefingEnhanced

BE.ModPath = BE.ModPath or ModPath

if not BE._core_loaded then
	BE._core_loaded = true

	dofile(BE.ModPath .. "lua/core/constants_briefing_enhanced.lua")
	dofile(BE.ModPath .. "lua/core/service_outfit.lua")
	dofile(BE.ModPath .. "lua/core/service_dialog.lua")
	dofile(BE.ModPath .. "lua/core/state_briefing_session.lua")
	dofile(BE.ModPath .. "lua/core/controller_menu_navigation.lua")
	dofile(BE.ModPath .. "lua/core/facade_legacy.lua")
end

