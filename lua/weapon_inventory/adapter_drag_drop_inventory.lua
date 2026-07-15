BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.AdapterDragDropInventory = BE.AdapterDragDropInventory or {}

function BE.AdapterDragDropInventory:is_available()
	if not (BLT and BLT.Mods and BLT.Mods.GetModByName) then
		return false
	end

	local mod = BLT.Mods:GetModByName("Drag and Drop Inventory")

	return mod ~= nil
		and mod:IsEnabled()
		and DragDropInventory ~= nil
		and managers.blackmarket ~= nil
		and managers.blackmarket.pickup_crafted_item ~= nil
		and managers.blackmarket.place_crafted_item ~= nil
		and managers.multi_profile ~= nil
		and managers.multi_profile.ddi_swap_item ~= nil
end

function BE.AdapterDragDropInventory:enable_for_loadout_node(node_data)
	if node_data and self:is_available() then
		-- The dependency ignores loadout nodes. This node keeps explicit vanilla
		-- actions, so presenting it as a regular weapon grid is safe here.
		node_data.is_loadout = false
	end
end

-- Compatibility facade for versions <= 1.6.1.
function BE:is_drag_drop_inventory_available()
	return self.AdapterDragDropInventory:is_available()
end
