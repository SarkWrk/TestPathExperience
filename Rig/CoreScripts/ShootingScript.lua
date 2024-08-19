local rig = script.Parent.Parent -- The rig containing the script



-- Sets up the main table
local main = {}

-- General predefined variables used
main.RunService = game:GetService("RunService")
main.LastCheckedEnemyPositions = 0 -- Used for main.Configurations.VisualCheckDelay
main.LastUpdatedEnemyTable = 0 -- Used for main.Configurations.EnemyTableUpdateDelay
main.CanSeeEnemy = false -- If the rig can see an enemy
main.StopViewChecking = false -- Whether the programme should stop checking if the rig can see an enemy. THIS SHOULD ONLY BE USED IN EMERGENCIES.



-- Sets up a table to store enemies in
main.EnemyTable = {}



-- Sets up the configuration table
main.Configurations = {}



-- Predefines some information in main.Configuration
main.Configurations.AllowAdjustableSettings = true -- Whether to allow other scripts to change configuration settings in the script via attribute changes
main.Configurations.VisualCheckDelay = 0.1 -- Used to delay times between raycasting, in seconds
main.Configurations.RaycastStart = "Head" -- A string identifier for the part used to check from. Must be a child of the rig
main.Configurations.EnemyTableUpdateDelay = 0.1 -- Used to decide how often to update main.EnemyTable, in seconds
main.Configurations.ViewDistance = 100 -- How far the rig can see, in studs
main.Configurations.ViewRadius = 30 -- FOV of the rig, in +/-x, therefore: FOV is double what is set
main.Configurations.EnemyFolders = { --[[
Table to store folders that enemies can be in.
Can be added and removed from via script.ChangeEnemyTable if main.Configurations.AllowAdjustableSettings is set to true.
Information on how to add/remove folders will be in the listener event function.
]]
	game.Workspace.Goals	
}



-- Table to stoer configurations for the RaycastParams for the viewcheck raycast
main.Configurations.RaycastParams = {}

-- Predefined variables inside main.Configurations.RaycastParams
main.Configurations.RaycastParams.FilterType = "Exclude" -- Case specific
main.Configurations.RaycastParams.RespectCanCollide = false
main.Configurations.RaycastParams.IgnoreInViewChecking = { --[[
Table used to store folders or parts that the rig should ignore when checking if it can see an enemy.
Can be added and removed from via script.ChangeIgnoreViewTable if main.Configurations.AllowAdjustableSettings is set to true.
Information on how to add/remove parts will be in the listener event function.
]]
	game.Workspace.Rig,	
}



--[[
Table used if main.Configurations.AllowAdjustableSettings is set to true.
Indexes inside must align with their main.Configurations indexes.
Values inside will be automatically be type checked using typeof().
If the typeof() returns nil, the attribute will be set to the default type.
Use "/" to denote a subfolder.
]]
main.Configurations.Attributes = {
	-- EnemyFolders is its own event
	-- RaycastParams/IgnoreInViewChecking is its own event
	"VisualCheckDelay",
	"EnemyTableUpdateDelay",
	"ViewDistance",
	"RaycastParams/FilterType",
}



-- Sets up a table to store information that is used in visualisations
VisualisationInformation = {}



-- Listens for main.RunService.Heartbeat() before checking if the rig can see an enemy. If the rig can see an enemy then the CanSeeEnemy attribute is set to true, otherwise false.
main.RunService.Heartbeat:Connect(function() : nil
	-- Checks if main.StopViewChecking is set to true. If it is, it returns
	if main.StopViewChecking == true then
		return
	end
	
	-- Checks if main.EnemyTable is empty or not. If it is, it returns
	if main.EnemyTable == {} then
		return
	end
	
	if tick()-main.LastCheckedEnemyPositions >= main.Configurations.VisualCheckDelay then
		local hasSeenEnemy = false -- Tracks to see if the rig has seen an enemy
		
		for _, enemy : Part | Model in pairs(main.EnemyTable) do
			-- If the rig has seen an enemy, don't continue the for loop.
			if hasSeenEnemy == true then
				break
			end
			
			local endPart : Part
			
			-- Gets the part to raycast to via Model.PrimaryPart, or the part itself. If there is no part, then returns
			if enemy.ClassName == "Model" then
				endPart = enemy.PrimaryPart
			elseif enemy.ClassName == "Part" then
				endPart = enemy
			else
				return
			end
			
			-- Gets the part on the rig to raycast from
			local startPart : Part = rig:FindFirstChild(main.Configurations.RaycastStart)
			
			if startPart == nil then
				if main.Configurations.AllowAdjustableSettings == true and table.find(main.Configurations.Attributes, "RaycastStart") then
					warn(script:GetFullName() .. ".main.RunService.Heartbeat could not identify a part to start the raycast at. The start part can be changed.")
				else
					main.StopViewChecking = true
					error(script:GetFullName() .. ".main.RunService.Heartbeat could not identify a part to start the raycast at. The start part can not be changed.")
				end
				return
			end
			
			
			-- Sets up the RaycastParams for the raycast
			local rayCastParams = RaycastParams.new()
			rayCastParams.FilterType = Enum.RaycastFilterType[main.Configurations.RaycastParams.FilterType]
			rayCastParams.RespectCanCollide = main.Configurations.RaycastParams.RespectCanCollide
			rayCastParams.FilterDescendantsInstances = main.Configurations.RaycastParams.IgnoreInViewChecking
			
			local viewDirection = CFrame.lookAt(startPart.Position, endPart.Position).LookVector * main.Configurations.ViewDistance --[[
			^^ Sets the view distance ]]
			
			-- At this point, the programme has identified the end part and the start part to raycast to
			local raycast = game.Workspace:Raycast(startPart.Position, viewDirection, rayCastParams)
			
			-- TODO: Add radius checking to see if the rig can physically be able to see the enemy using main.Configurations.ViewRadius
			
			if raycast then
				if raycast.Instance then
					if raycast.Instance:IsDescendantOf(enemy) or raycast.Instance == enemy then
						hasSeenEnemy = true
					end
				end
			end
		end
		
		-- Sets the CanSeeEnemy attribute and main.CanSeeEnemy to whatever hasSeenEnemy is
		script:SetAttribute("CanSeeEnemy", hasSeenEnemy)
		main.CanSeeEnemy = hasSeenEnemy
	end
end)

--[[
Function used to update main.EnemyTable via main.Configurations.EnemyFolders if main.Configurations.EnemyTableUpdateDelay seconds has passed since it was lasted updated.
It lops through the folders in pcalls for safety.
Returns true if main.EnemyTable was updated, false if it wasn't.
]]
function main:UpdateEnemyTable() : boolean
	if tick() - main.LastUpdatedEnemyTable >= main.Configurations.EnemyTableUpdateDelay then
		main.EnemyTable = {}

		local success1, no1 = pcall(function()
			for _, folder : Folder in pairs(main.Configurations.EnemyFolders) do
				local success2, no2 = pcall(function()
					for _, enemy : Part | Model in pairs(folder:GetChildren()) do
						table.insert(main.EnemyTable, enemy)
					end
				end)
				
				if not success2 then
					warn(script:GetFullName() .. ".main:UpdateEnemyTable() had an issue updating the table for a specific folder. Error message: " .. no2)
				end
			end
		end)
		
		if not success1 then
			warn(script:GetFullName() .. ".main:UpdateEnemyTable() had an error in the main for loop. Error message: " .. no1)
		end
		
		main.LastUpdatedEnemyTable = tick()
		
		return true
	end
	
	return false
end

while task.wait() do
	main:UpdateEnemyTable()
end
