BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ControllerPerkDeck = BE.ControllerPerkDeck or {}

function BE.ControllerPerkDeck:open()
	if BE.FactoryBriefingNode:ensure_all() then
		BE.ControllerMenuNavigation:open(
			"specialization",
			BE.ConstantsBriefingEnhanced.NODE_NAMES.perk_deck
		)
	end
end

-- Compatibility facade for versions <= 1.6.1.
function BE:open_specialization()
	return self.ControllerPerkDeck:open()
end
