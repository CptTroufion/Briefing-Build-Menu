BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.AdapterPd2Builder = BE.AdapterPd2Builder or {}

function BE.AdapterPd2Builder:get_path()
	if not (BLT and BLT.Mods and BLT.Mods.GetModByName) then
		return nil
	end

	local mod = BLT.Mods:GetModByName("PD2Builder loader")

	if not (mod and mod:IsEnabled() and BuilderLoader and BuilderLoader.load_build and BuilderLoader.upload_build) then
		return nil
	end

	return mod:GetPath()
end

function BE.AdapterPd2Builder:is_available()
	return self:get_path() ~= nil
end

function BE.AdapterPd2Builder:install_sync_hook()
	if self._sync_hooked or not (BuilderLoader and BuilderLoader.set_build) then
		return
	end

	self._sync_hooked = true

	Hooks:PostHook(BuilderLoader, "set_build", "BriefingBuildMenu_BuilderLoader_set_build", function()
		BE.ServiceOutfit:update()
	end)
end

function BE.AdapterPd2Builder:run(script_name)
	local builder_path = self:get_path()

	if not builder_path then
		return
	end

	self:install_sync_hook()

	local success, error_message = pcall(dofile, builder_path .. "lua/" .. script_name)

	if not success then
		BE.ServiceDialog:show_error("bbm_builder_error", error_message)
	end
end

function BE.AdapterPd2Builder:import_build()
	self:run("loadBuild.lua")
end

function BE.AdapterPd2Builder:export_build()
	self:run("uploadBuild.lua")
end

-- Compatibility facade for versions <= 1.6.1.
function BE:get_pd2builder_path()
	return self.AdapterPd2Builder:get_path()
end

function BE:import_build()
	return self.AdapterPd2Builder:import_build()
end

function BE:export_build()
	return self.AdapterPd2Builder:export_build()
end

function BE:install_pd2builder_sync_hook()
	return self.AdapterPd2Builder:install_sync_hook()
end

function BE:run_pd2builder_script(script_name)
	return self.AdapterPd2Builder:run(script_name)
end
