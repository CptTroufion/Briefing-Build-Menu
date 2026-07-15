BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ConstantsBriefingEnhanced = BE.ConstantsBriefingEnhanced or {
	BUILD_BUTTON = "briefing_build_menu_button",
	LEGACY_SKILL_TREE_BUTTON = "briefing_skilltree_button",
	WEAPON_COMPONENT = "bbm_weapon_modifications",
	WEAPON_MODIFICATION_COLUMNS = 7,
	WEAPON_MODIFICATION_ROWS = 1,
	NODE_NAMES = {
		skill_tree = "briefing_build_menu_skilltree_node",
		perk_deck = "briefing_build_menu_specialization_node",
		weapon_modification = "briefing_build_menu_weapon_modifications_node"
	}
}

-- Legacy constants kept for compatibility with versions <= 1.6.1.
BE.BUTTON_NAME = BE.ConstantsBriefingEnhanced.BUILD_BUTTON
BE.OLD_BUTTON_NAME = BE.ConstantsBriefingEnhanced.LEGACY_SKILL_TREE_BUTTON
BE.NODE_NAMES = BE.NODE_NAMES or {
	skilltree = BE.ConstantsBriefingEnhanced.NODE_NAMES.skill_tree,
	specialization = BE.ConstantsBriefingEnhanced.NODE_NAMES.perk_deck,
	weapon_modifications = BE.ConstantsBriefingEnhanced.NODE_NAMES.weapon_modification
}
