BriefingBuildMenu = BriefingBuildMenu or {}

Hooks:PostHook(SpecializationGuiNew, "close", "BriefingBuildMenu_SpecializationGuiNew_close", function(self)
	BriefingBuildMenu:finish_open("specialization")
end)
