local rig = script.Parent.Parent -- The rig
local humanoid = rig.Humanoid -- The humanoid

-- Fires the RigDied BindableEvent when Humanoid.Died fires
humanoid.Died:Connect(function()
	-- Tells all other CoreScripts to stop functioning
	script.Parent.RigDied:Fire()
	script:SetAttribute("Shutoff", true)
	
	-- Waits until all the scripts have added the "Shutoff" attribute with a "true" value
	while task.wait() do
		local allShutDown = true
		for i, v in pairs(script.Parent:GetChildren()) do
			if v.ClassName == "Script" then
				if v:GetAttribute("Shutoff") == true then
				else
					allShutDown = false
				end
			end
		end
		if allShutDown == true then
			break
		end
	end
	
	warn("All scripts have ended.")
	
	game:GetService("Debris"):AddItem(rig, 0)
end)
