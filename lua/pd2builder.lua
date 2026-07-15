BriefingBuildMenu = BriefingBuildMenu or {}

local BBM = BriefingBuildMenu

function BBM:get_pd2builder_path()
	if not (BLT and BLT.Mods and BLT.Mods.GetModByName) then
		return nil
	end

	local mod = BLT.Mods:GetModByName("PD2Builder loader")

	if not (mod and mod:IsEnabled() and BuilderLoader and BuilderLoader.load_build and BuilderLoader.upload_build) then
		return nil
	end

	return mod:GetPath()
end

function BBM:install_pd2builder_sync_hook()
	if self._pd2builder_sync_hooked or not (BuilderLoader and BuilderLoader.set_build) then
		return
	end

	self._pd2builder_sync_hooked = true

	Hooks:PostHook(BuilderLoader, "set_build", "BriefingBuildMenu_BuilderLoader_set_build", function()
		BBM:update_player_outfit()
	end)
end

function BBM:run_pd2builder_script(script_name)
	local builder_path = self:get_pd2builder_path()

	if not builder_path then
		return
	end

	self:install_pd2builder_sync_hook()

	local success, error_message = pcall(dofile, builder_path .. "lua/" .. script_name)

	if not success then
		self:show_error("bbm_builder_error", error_message)
	end
end

function BBM:import_build()
	self:run_pd2builder_script("loadBuild.lua")
end

function BBM:export_build()
	self:run_pd2builder_script("uploadBuild.lua")
end
