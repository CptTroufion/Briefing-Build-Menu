BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced
local Constants = BE.ConstantsBriefingEnhanced

BE.ComponentWeaponModification = BE.ComponentWeaponModification or class()

local Component = BE.ComponentWeaponModification
local FONT = tweak_data.menu.pd2_medium_font
local LARGE_FONT = tweak_data.menu.pd2_large_font
local COLORS = tweak_data.screen_colors
local COLUMNS = Constants.WEAPON_MODIFICATION_COLUMNS
local ROWS = Constants.WEAPON_MODIFICATION_ROWS
local PAGE_SIZE = COLUMNS * ROWS

local function upper(text)
	return utf8.to_upper(text or "")
end

local function fit_text(text)
	local _, _, width, height = text:text_rect()

	text:set_size(math.min(width, text:parent():w()), height)
end

local function get_part_icon(part_id)
	local tweak = tweak_data.blackmarket.weapon_mods[part_id] or {}
	local path = "guis/"

	if tweak.texture_bundle_folder then
		path = path .. "dlcs/" .. tweak.texture_bundle_folder .. "/"
	end

	return path .. "textures/pd2/blackmarket/icons/mods/" .. part_id
end

function Component:_rebuild()
	self._panel:clear()
	self._cells = {}
	self._tabs = {}
	self._action_button = nil
	self._previous_page_button = nil
	self._next_page_button = nil

	local width, height = self._panel:w(), self._panel:h()
	local margin = 32
	local title = self._panel:text({
		text = managers.localization:text("bbm_blackmarket_title", {
			WEAPON = upper(self._data.weapon.name)
		}),
		font = LARGE_FONT,
		font_size = tweak_data.menu.pd2_large_font_size,
		color = COLORS.text,
		layer = 2,
		x = margin,
		y = 12
	})

	fit_text(title)

	local weapon_name = self._panel:text({
		text = upper(managers.localization:text(
			self._category == "primaries" and "bbm_primary_weapon" or "bbm_secondary_weapon"
		)),
		font = FONT,
		font_size = 22,
		color = COLORS.friend,
		x = margin,
		y = title:bottom() + 2
	})

	fit_text(weapon_name)

	local tab_y = math.floor(height * 0.56)
	local tabs_top = tab_y
	local tab_x = margin
	local tab_bottom = tab_y

	for index, part_type in ipairs(self._data.part_types) do
		local selected = index == self._type_index
		local label = upper(managers.localization:text("bm_menu_" .. part_type))
		local estimated_width = string.len(label) * 11 + 18

		if tab_x + estimated_width > width - margin then
			tab_x = margin
			tab_y = tab_y + 28
		end

		local tab = self._panel:text({
			text = label,
			font = FONT,
			font_size = 20,
			color = selected and COLORS.button_stage_2 or COLORS.button_stage_3,
			x = tab_x,
			y = tab_y
		})

		fit_text(tab)
		tab:set_w(tab:w() + 18)
		self._tabs[index] = tab
		tab_x = tab:right() + 4
		tab_bottom = math.max(tab_bottom, tab:bottom())
	end

	local content_top = tab_bottom + 14
	local details_width = math.max(280, width * 0.27)
	local grid_width = width - details_width - margin * 3
	local grid_height = math.min(170, height - content_top - 70)

	self._panel:rect({
		x = margin - 8,
		y = tab_y - 5,
		w = grid_width + 16,
		h = height - tab_y - 48,
		color = Color.black,
		alpha = 0.42,
		layer = -1
	})

	local cell_width = (grid_width - 12 * (COLUMNS - 1)) / COLUMNS
	local cell_height = (grid_height - 12 * (ROWS - 1)) / ROWS
	local parts = self:_current_parts()
	local page_count = math.max(1, math.ceil(#parts / PAGE_SIZE))

	self._page_count = page_count
	self._page = math.clamp(math.ceil(self._selected_index / PAGE_SIZE), 1, page_count)

	local first = (self._page - 1) * PAGE_SIZE + 1

	for visible_index = 1, PAGE_SIZE do
		local part_index = first + visible_index - 1
		local part = parts[part_index]

		if part then
			local column = (visible_index - 1) % COLUMNS
			local row = math.floor((visible_index - 1) / COLUMNS)
			local cell = self._panel:panel({
				x = margin + column * (cell_width + 12),
				y = content_top + row * (cell_height + 12),
				w = cell_width,
				h = cell_height
			})
			local selected = part_index == self._selected_index

			cell:rect({
				color = selected and COLORS.button_stage_3 or Color.black,
				alpha = selected and 0.55 or 0.35
			})

			local icon = get_part_icon(part.id)

			if DB:has(Idstring("texture"), Idstring(icon)) then
				cell:bitmap({
					texture = icon,
					blend_mode = "add",
					x = 8,
					y = 8,
					w = cell:w() - 16,
					h = cell:h() - 60
				})
			end

			cell:text({
				text = upper(part.name),
				font = FONT,
				font_size = 17,
				color = selected and COLORS.button_stage_2 or COLORS.text,
				x = 8,
				y = cell:h() - 48,
				w = cell:w() - 16,
				h = 24,
				wrap = false,
				ellipsis = true
			})

			local status_id, status_color = self:_get_part_status(part)

			cell:text({
				text = managers.localization:text(status_id),
				font = FONT,
				font_size = 15,
				color = status_color,
				x = 8,
				y = cell:h() - 25,
				w = cell:w() - 16,
				h = 20
			})

			self._cells[part_index] = cell
		end
	end

	self._previous_page_button = self._panel:text({
		text = managers.localization:text("bbm_previous_page"),
		font = FONT,
		font_size = 18,
		color = self._page > 1 and COLORS.button_stage_3 or Color(0.35, 1, 1, 1),
		x = margin,
		y = height - 38
	})
	fit_text(self._previous_page_button)

	local page = self._panel:text({
		text = managers.localization:text("bbm_page", {
			CURRENT = self._page,
			TOTAL = page_count
		}),
		font = FONT,
		font_size = 18,
		color = COLORS.text,
		x = self._previous_page_button:right() + 18,
		y = height - 38
	})
	fit_text(page)

	self._next_page_button = self._panel:text({
		text = managers.localization:text("bbm_next_page"),
		font = FONT,
		font_size = 18,
		color = self._page < page_count and COLORS.button_stage_3 or Color(0.35, 1, 1, 1),
		x = page:right() + 18,
		y = height - 38
	})
	fit_text(self._next_page_button)

	local cash = self._panel:text({
		text = managers.experience:cash_string(managers.money:total()),
		font = FONT,
		font_size = 18,
		color = COLORS.friend,
		x = self._next_page_button:right() + 30,
		y = height - 38
	})
	fit_text(cash)

	local stats_top = weapon_name:bottom() + 14
	local stats_height = math.max(0, tabs_top - stats_top - 12)

	self:_draw_weapon_stats(margin, stats_top, math.min(500, grid_width), stats_height)
	self:_draw_part_details(width - details_width - margin, 18, details_width, height - 108)
end

function Component:_draw_part_details(x, y, width, height)
	local panel = self._panel:panel({ x = x, y = y, w = width, h = height })
	local part = self:_selected_part()

	panel:rect({ color = Color.black, alpha = 0.45 })

	if not part then
		return
	end

	panel:text({
		text = upper(part.name),
		font = LARGE_FONT,
		font_size = 28,
		color = COLORS.text,
		x = 16,
		y = 14,
		w = width - 32,
		h = 70,
		wrap = true,
		word_wrap = true
	})

	local status_id, status_color = self:_get_part_status(part)

	panel:text({
		text = managers.localization:text(status_id),
		font = FONT,
		font_size = 22,
		color = status_color,
		x = 16,
		y = 92,
		w = width - 32,
		h = 28
	})

	local part_tweak = tweak_data.blackmarket.weapon_mods[part.id] or {}
	local description = part_tweak.desc_id and managers.localization:text(part_tweak.desc_id) or ""

	panel:text({
		text = description,
		font = FONT,
		font_size = 18,
		color = COLORS.text,
		x = 16,
		y = 124,
		w = width - 32,
		h = 90,
		wrap = true,
		word_wrap = true
	})
	panel:text({
		text = managers.localization:text("bbm_part_owned", { AMOUNT = part.amount }),
		font = FONT,
		font_size = 20,
		color = COLORS.text,
		x = 16,
		y = 224,
		w = width - 32,
		h = 25
	})
	panel:text({
		text = managers.localization:text("bbm_part_price", {
			PRICE = managers.experience:cash_string(part.price)
		}),
		font = FONT,
		font_size = 20,
		color = COLORS.text,
		x = 16,
		y = 252,
		w = width - 32,
		h = 25
	})

	local suspicion = managers.blackmarket:get_suspicion_offset_of_local(
		tweak_data.player.SUSPICION_OFFSET_LERP or 0.75
	)
	local detection_risk = math.round((suspicion or 0) * 100)

	panel:rect({
		x = 0,
		y = height - 112,
		w = width,
		h = 1,
		color = COLORS.button_stage_3,
		alpha = 0.8
	})
	panel:text({
		text = managers.localization:text("bbm_detection_risk", { RISK = detection_risk }),
		font = FONT,
		font_size = 21,
		color = COLORS.friend,
		x = 16,
		y = height - 100,
		w = width - 32,
		h = 28
	})

	local action = self:_get_part_action(part)
	local action_id = action == "remove" and "bbm_part_remove"
		or (action == "install" and "bbm_part_install" or "bbm_part_no_action")

	self._action_button = panel:text({
		text = managers.localization:text(action_id),
		font = FONT,
		font_size = 21,
		color = action and COLORS.button_stage_2 or COLORS.important_1,
		x = 16,
		y = height - 45,
		w = width - 32,
		h = 30,
		align = "right"
	})
end

function Component:_draw_weapon_stats(x, y, width, height)
	if height < 80 then
		return
	end

	local panel = self._panel:panel({ x = x, y = y, w = width, h = height })
	panel:rect({ color = Color.black, alpha = 0.45 })
	local title = panel:text({
		text = managers.localization:text("bbm_weapon_stats"),
		font = FONT,
		font_size = 20,
		color = COLORS.friend,
		x = 10,
		y = 4,
		w = width - 20,
		h = 24
	})

	local stats = BE.PresenterWeaponStatistics:get_data(self._data.weapon, self:_selected_part())

	if not stats then
		panel:text({
			text = managers.localization:text("bbm_weapon_stats_calculation_unavailable"),
			font = FONT,
			font_size = 16,
			color = COLORS.text,
			x = 10,
			y = title:bottom() + 2,
			w = width - 20,
			h = 44,
			wrap = true,
			word_wrap = true
		})
		return
	end

	local inner_width = width - 20
	local label_width = math.floor(inner_width * 0.42)
	local value_width = math.floor((inner_width - label_width) / 4)
	local header_y = title:bottom() + 1
	local row_y = header_y + 16
	local row_height = 15
	local max_rows = math.max(0, math.floor((height - row_y - 4) / row_height))
	local headers = {
		{ text = managers.localization:text("bm_menu_stats_total"), color = COLORS.text },
		{ text = managers.localization:text("bm_menu_stats_base"), color = COLORS.text },
		{ text = managers.localization:text("bm_menu_stats_mod"), color = COLORS.stats_mods },
		{ text = managers.localization:text("bm_menu_stats_skill"), color = COLORS.resource }
	}

	for index, header in ipairs(headers) do
		panel:text({
			text = upper(header.text),
			font = FONT,
			font_size = 12,
			color = header.color,
			x = 10 + label_width + (index - 1) * value_width,
			y = header_y,
			w = value_width,
			h = 15,
			align = "right"
		})
	end

	local rows = {}

	for _, stat in ipairs(stats.vanilla) do
		table.insert(rows, stat)
	end

	for _, stat in ipairs(stats.extended) do
		table.insert(rows, stat)
	end

	if #stats.extended == 0 and #rows < max_rows then
		table.insert(rows, {
			name = managers.localization:text(
				stats.more_weapon_stats_active
					and "bbm_weapon_stats_calculation_unavailable"
					or "bbm_more_weapon_stats_unavailable"
			),
			total = ""
		})
	end

	local total_colors = {
		text = COLORS.text,
		positive = COLORS.stats_positive,
		negative = COLORS.stats_negative,
		maxed = COLORS.stat_maxed
	}

	for index = 1, math.min(#rows, max_rows) do
		local stat = rows[index]
		local row_position_y = row_y + (index - 1) * row_height

		if index % 2 == 0 then
			panel:rect({
				x = 12,
				y = row_position_y,
				w = panel:w() - 24,
				h = row_height,
				color = Color.black,
				alpha = 0.25
			})
		end

		panel:text({
			text = upper(stat.name),
			font = FONT,
			font_size = 12,
			color = COLORS.text,
			x = 10,
			y = row_position_y,
			w = label_width,
			h = row_height,
			ellipsis = true
		})
		panel:text({
			text = stat.total or "",
			font = FONT,
			font_size = 12,
			color = stat.changed and COLORS.button_stage_2 or total_colors[stat.total_color] or COLORS.text,
			x = 10 + label_width,
			y = row_position_y,
			w = value_width,
			h = row_height,
			align = "right"
		})
		panel:text({
			text = stat.base or "",
			font = FONT,
			font_size = 12,
			color = COLORS.text,
			x = 10 + label_width + value_width,
			y = row_position_y,
			w = value_width,
			h = row_height,
			align = "right"
		})
		panel:text({
			text = stat.mods or "",
			font = FONT,
			font_size = 12,
			color = COLORS.stats_mods,
			x = 10 + label_width + value_width * 2,
			y = row_position_y,
			w = value_width,
			h = row_height,
			align = "right"
		})
		panel:text({
			text = stat.skill or "",
			font = FONT,
			font_size = 12,
			color = COLORS.resource,
			x = 10 + label_width + value_width * 3,
			y = row_position_y,
			w = value_width,
			h = row_height,
			align = "right"
		})
	end
end
