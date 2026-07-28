local mod_path = ModPath
local required_script = string.lower(RequiredScript or "")

dofile(mod_path .. "lua/core/bootstrap.lua")
dofile(BriefingEnhanced.ModPath .. "lua/weapon_context_menu/controller_weapon_context_menu.lua")

local BE = BriefingEnhanced

BE.HookWeaponContextMenu = BE.HookWeaponContextMenu or {}

if required_script == "lib/managers/menu/missionbriefinggui"
	and not BE.HookWeaponContextMenu.mission_briefing then
	BE.HookWeaponContextMenu.mission_briefing = true

	local original_mouse_pressed = Hooks:GetFunction(MissionBriefingGui, "mouse_pressed")

	-- MissionBriefingGui discards non-left clicks before forwarding input to
	-- NewLoadoutTab, so this interaction must be consumed at the parent level.
	Hooks:OverrideFunction(MissionBriefingGui, "mouse_pressed", function(gui, button, x, y)
		if button == Idstring("1") and BE.ControllerWeaponContextMenu:try_show_briefing(gui, x, y) then
			return true
		end

		return original_mouse_pressed(gui, button, x, y)
	end)
elseif required_script == "lib/managers/menu/blackmarketgui"
	and not BE.HookWeaponContextMenu.blackmarket then
	BE.HookWeaponContextMenu.blackmarket = true

	local original_choose_weapon_mods = Hooks:GetFunction(BlackMarketGui, "choose_weapon_mods_callback")

	-- The vanilla callback enters the 3D crafting scene. Redirect it only for
	-- the marked briefing inventory and preserve every other BlackMarket flow.
	Hooks:OverrideFunction(BlackMarketGui, "choose_weapon_mods_callback", function(gui, data)
		local inventory = BE.ServiceWeaponInventory

		if inventory and inventory:is_active(data and data.category) then
			if BE.ControllerWeaponModification
				and BE.ControllerWeaponModification:open(data.category, data.slot) then
				return true
			end

			managers.menu_component:post_event("menu_error")
			return false
		end

		return original_choose_weapon_mods(gui, data)
	end)
end
