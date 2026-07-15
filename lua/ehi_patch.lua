BriefingBuildMenu = BriefingBuildMenu or {}

local BBM = BriefingBuildMenu

function BBM:install_ehi_patch()
	if self._ehi_patch_done then
		return
	end

	self._ehi_patch_done = true

	if not MissionBriefingGui.AddXPBreakdown then
		return
	end

	self._ehi_xp_elements = {}
	local original_add_xp_breakdown = MissionBriefingGui.AddXPBreakdown

	function MissionBriefingGui:AddXPBreakdown(...)
		local workspace_panel = alive(self._full_workspace) and self._full_workspace:panel()

		if not workspace_panel then
			return original_add_xp_breakdown(self, ...)
		end

		local previous_child_count = #workspace_panel:children()
		local result = original_add_xp_breakdown(self, ...)
		local elements = BBM._ehi_xp_elements

		for index = #elements, 1, -1 do
			if not alive(elements[index]) then
				table.remove(elements, index)
			end
		end

		local children = workspace_panel:children()

		for index = previous_child_count + 1, #children do
			table.insert(elements, children[index])
		end

		return result
	end
end

function BBM:hide_ehi_xp_overview()
	if not self._ehi_xp_elements then
		return
	end

	local visibility = {}

	for _, element in ipairs(self._ehi_xp_elements) do
		if alive(element) then
			visibility[element] = element:visible()
			element:set_visible(false)
		end
	end

	self._ehi_xp_visibility = visibility
end

function BBM:show_ehi_xp_overview()
	local visibility = self._ehi_xp_visibility

	if not visibility then
		return
	end

	self._ehi_xp_visibility = nil

	for element, was_visible in pairs(visibility) do
		if alive(element) then
			element:set_visible(was_visible)
		end
	end
end
