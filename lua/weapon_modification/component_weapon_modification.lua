BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced
local Constants = BE.ConstantsBriefingEnhanced
local COLORS = tweak_data.screen_colors
local COLUMNS = Constants.WEAPON_MODIFICATION_COLUMNS
local PAGE_SIZE = COLUMNS * Constants.WEAPON_MODIFICATION_ROWS

BE.ComponentWeaponModification = BE.ComponentWeaponModification or class()

local Component = BE.ComponentWeaponModification

-- Legacy global kept for compatibility with versions <= 1.6.1.
BriefingWeaponModificationsGui = Component

function Component:init(ws, fullscreen_ws, node)
	self._ws = ws
	self._fullscreen_ws = fullscreen_ws
	self._node = node
	self._category = (node:parameters().menu_component_data or {}).category or "primaries"
	self._type_index = 1
	self._selected_index = 1
	self._page = 1
	self._panel = ws:panel():panel({
		name = "bbm_weapon_modifications",
		layer = 50
	})
	self._fullscreen_panel = fullscreen_ws:panel():panel({
		name = "bbm_weapon_modifications_fullscreen",
		layer = 49
	})
	self._fullscreen_panel:rect({ color = Color.black, alpha = 0.38 })
	self:refresh()
end

function Component:close()
	if alive(self._panel) then
		self._ws:panel():remove(self._panel)
	end

	if alive(self._fullscreen_panel) then
		self._fullscreen_ws:panel():remove(self._fullscreen_panel)
	end
end

function Component:refresh()
	self._data = BE.ServiceWeaponModification:get_data(self._category)

	if not self._data then
		BE.ServiceDialog:show_error("bbm_weapon_error", self._category)
		managers.menu:back()
		return
	end

	self._type_index = math.clamp(self._type_index, 1, math.max(#self._data.part_types, 1))
	self._selected_index = math.max(self._selected_index, 1)
	self:_rebuild()
end

function Component:_current_type()
	return self._data.part_types[self._type_index]
end

function Component:_current_parts()
	return self._data.parts[self:_current_type()] or {}
end

function Component:_selected_part()
	return self:_current_parts()[self._selected_index]
end

function Component:_get_part_status(part)
	if part.equipped then
		return "bbm_part_equipped", COLORS.friend
	elseif part.type_locked then
		return "bbm_part_locked", COLORS.important_1
	elseif not part.can_modify then
		return "bbm_part_incompatible", COLORS.important_1
	elseif part.amount < 1 then
		return "bbm_part_unowned", COLORS.important_1
	elseif not part.can_afford then
		return "bbm_part_unaffordable", COLORS.important_1
	end

	return "bbm_part_available", COLORS.text
end

function Component:_get_part_action(part)
	if not part or part.type_locked then
		return nil
	end

	if part.equipped and part.id ~= part.default_part then
		return "remove"
	end

	if part.available and not part.equipped then
		return "install"
	end

	return nil
end

function Component:_select(index)
	local parts = self:_current_parts()

	if #parts == 0 then
		return
	end

	self._selected_index = math.clamp(index, 1, #parts)
	managers.menu_component:post_event("highlight")
	self:_rebuild()
end

function Component:_change_type(direction)
	if #self._data.part_types == 0 then
		return
	end

	self._type_index = (self._type_index - 1 + direction) % #self._data.part_types + 1
	self._selected_index = 1
	self._page = 1
	managers.menu_component:post_event("highlight")
	self:_rebuild()

	return true
end

function Component:_change_page(direction)
	local parts = self:_current_parts()
	local page_count = math.max(1, math.ceil(#parts / PAGE_SIZE))
	local target_page = math.clamp(self._page + direction, 1, page_count)

	if target_page == self._page then
		managers.menu_component:post_event("menu_error")
		return true
	end

	local position_on_page = (self._selected_index - 1) % PAGE_SIZE
	local first_index = (target_page - 1) * PAGE_SIZE + 1
	local last_index = math.min(target_page * PAGE_SIZE, #parts)
	local target_index = math.min(first_index + position_on_page, last_index)

	self:_select(target_index)

	return true
end

function Component:move_left()
	self:_select(self._selected_index - 1)

	return true
end

function Component:move_right()
	self:_select(self._selected_index + 1)

	return true
end

function Component:move_up()
	if self._selected_index <= COLUMNS then
		return self:_change_type(-1)
	end

	self:_select(self._selected_index - COLUMNS)

	return true
end

function Component:move_down()
	self:_select(self._selected_index + COLUMNS)

	return true
end

function Component:next_page()
	return self:_change_page(1)
end

function Component:previous_page()
	return self:_change_page(-1)
end

function Component:confirm_pressed()
	local part = self:_selected_part()

	if not part then
		return true
	end

	local action = self:_get_part_action(part)

	if action == "remove" then
		BE.ServiceWeaponModification:confirm_remove(self._category, self:_current_type(), part)
	elseif action == "install" then
		BE.ServiceWeaponModification:confirm_install(self._category, self:_current_type(), part)
	else
		managers.menu_component:post_event("menu_error")
	end

	return true
end

function Component:mouse_moved(x, y)
	if alive(self._previous_page_button)
		and self._previous_page_button:inside(x, y)
		and self._page > 1 then
		return true, "link"
	end

	if alive(self._next_page_button)
		and self._next_page_button:inside(x, y)
		and self._page < (self._page_count or 1) then
		return true, "link"
	end

	if alive(self._action_button) and self._action_button:inside(x, y) then
		return true, "link"
	end

	for _, tab in ipairs(self._tabs) do
		if tab:inside(x, y) then
			return true, "link"
		end
	end

	for _, cell in pairs(self._cells) do
		if cell:inside(x, y) then
			return true, "link"
		end
	end

	return false, "arrow"
end

function Component:mouse_pressed(button, x, y)
	if button ~= Idstring("0") then
		return
	end

	if alive(self._previous_page_button) and self._previous_page_button:inside(x, y) then
		return self:_change_page(-1)
	end

	if alive(self._next_page_button) and self._next_page_button:inside(x, y) then
		return self:_change_page(1)
	end

	if alive(self._action_button) and self._action_button:inside(x, y) then
		return self:confirm_pressed()
	end

	for index, tab in ipairs(self._tabs) do
		if tab:inside(x, y) then
			self._type_index = index
			self._selected_index = 1
			self:_rebuild()
			return true
		end
	end

	for index, cell in pairs(self._cells) do
		if cell:inside(x, y) then
			if self._selected_index == index then
				return self:confirm_pressed()
			end

			self:_select(index)
			return true
		end
	end
end

function Component:mouse_wheel_up()
	return self:_change_page(-1)
end

function Component:mouse_wheel_down()
	return self:_change_page(1)
end

function Component:mouse_double_click(_, button, x, y)
	if button ~= Idstring("0") then
		return
	end

	for index, cell in pairs(self._cells) do
		if cell:inside(x, y) then
			self._selected_index = index
			return self:confirm_pressed()
		end
	end
end
