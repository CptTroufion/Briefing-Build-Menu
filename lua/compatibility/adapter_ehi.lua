BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.AdapterEhi = BE.AdapterEhi or {
	_xp_elements = {}
}

function BE.AdapterEhi:install()
	if self._installed then
		return true
	end

	if not MissionBriefingGui.AddXPBreakdown then
		return false
	end

	self._installed = true

	Hooks:PreHook(MissionBriefingGui, "AddXPBreakdown", "BriefingEnhanced_Ehi_BeforeAddXpBreakdown", function(gui)
		local workspace_panel = alive(gui._full_workspace) and gui._full_workspace:panel()

		gui._be_ehi_previous_child_count = workspace_panel and #workspace_panel:children() or nil
	end)

	Hooks:PostHook(MissionBriefingGui, "AddXPBreakdown", "BriefingEnhanced_Ehi_AfterAddXpBreakdown", function(gui)
		local workspace_panel = alive(gui._full_workspace) and gui._full_workspace:panel()
		local previous_child_count = gui._be_ehi_previous_child_count

		gui._be_ehi_previous_child_count = nil

		if not (workspace_panel and previous_child_count) then
			return
		end

		for index = #BE.AdapterEhi._xp_elements, 1, -1 do
			if not alive(BE.AdapterEhi._xp_elements[index]) then
				table.remove(BE.AdapterEhi._xp_elements, index)
			end
		end

		local children = workspace_panel:children()

		for index = previous_child_count + 1, #children do
			table.insert(BE.AdapterEhi._xp_elements, children[index])
		end
	end)

	return true
end

function BE.AdapterEhi:hide_xp_overview()
	local visibility = {}

	for _, element in ipairs(self._xp_elements) do
		if alive(element) then
			visibility[element] = element:visible()
			element:set_visible(false)
		end
	end

	self._xp_visibility = visibility
end

function BE.AdapterEhi:show_xp_overview()
	local visibility = self._xp_visibility

	if not visibility then
		return
	end

	self._xp_visibility = nil

	for element, was_visible in pairs(visibility) do
		if alive(element) then
			element:set_visible(was_visible)
		end
	end
end

-- Compatibility facade for versions <= 1.6.1.
function BE:install_ehi_patch()
	return self.AdapterEhi:install()
end

function BE:hide_ehi_xp_overview()
	return self.AdapterEhi:hide_xp_overview()
end

function BE:show_ehi_xp_overview()
	return self.AdapterEhi:show_xp_overview()
end

