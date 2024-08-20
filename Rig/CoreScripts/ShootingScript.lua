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
	"ViewRadius",
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
			
			-- Creates a new CFrame that looks in the direction of the enemy and sets the view distance using main.Configurations.ViewDistance
			local newView = CFrame.lookAt(startPart.Position, endPart.Position)
			local viewDirection = newView.LookVector * main.Configurations.ViewDistance
			
			-- Compared the viewDirection Y orientation and start part Y orientation so check whether the rig can see the enemy using main.Configurations.ViewRadius, if not: returns
			local _, startYOrientation, _ = startPart.CFrame:ToEulerAnglesXYZ()
			local _, endYOrientation, _ = newView:ToOrientation()
			
			if math.abs(math.deg(startYOrientation) - math.deg(endYOrientation)) <= main.Configurations.ViewRadius then
				return
			end

			-- Sets up the RaycastParams for the raycast
			local rayCastParams = RaycastParams.new()
			rayCastParams.FilterType = Enum.RaycastFilterType[main.Configurations.RaycastParams.FilterType]
			rayCastParams.RespectCanCollide = main.Configurations.RaycastParams.RespectCanCollide
			rayCastParams.FilterDescendantsInstances = main.Configurations.RaycastParams.IgnoreInViewChecking
			
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
This if statement contains code that is only ran IF main.Configurations.AllowAdjustableSettings is set to true
]]
if main.Configurations.AllowAdjustableSettings == true then
	--[[
	This function creates attributes based on main.Configurations.Attributes.
	The attributes will have the type that the main.Configurations<index> has, otherwise it defaults to the default.
	The code will listen in a coroutine if the attribute gets changed and will update the main.Configurations<index><value> accordingly.
	]]
	function main:SetUpAttributeConfigurations() : nil
		for _, attribute : string in pairs(main.Configurations.Attributes) do
			local parsedValue : tabe = string.split(attribute, "/")
			local storedValue : any = nil
			local attributeType : string = nil
			local maxIterations : number = table.maxn(parsedValue)
			local fixedNamingScheme : string = ""
			
			-- Gets the main.Configurations config from the parsed value
			for i = 1, maxIterations do
				if i == 1 then
					storedValue = main.Configurations[parsedValue[i]]
					fixedNamingScheme = parsedValue[i]
				else
					storedValue = storedValue[parsedValue[i]]
					fixedNamingScheme = fixedNamingScheme .. "_" .. parsedValue[i]
				end
			end
			
			attributeType = type(storedValue) -- Gets the lua type of the value
			script:SetAttribute(fixedNamingScheme, storedValue) -- Creates the attribute
			
			-- Creates a coroutine to listen for if the attribute changes, and then sets the main.Configuration<index> to the value
			local function listenToAttribute() : nil
				storedValue = script:GetAttribute(fixedNamingScheme)
				
				-- Adds type checking to make sure that the new value will be the same type as the old value
				if attributeType ~= nil then
					if type(storedValue) ~= attributeType then
						return
					end
				end
				
				-- Changes the value in main.Configurations<index(es)>. This is a hard-coded code block.
				if maxIterations == 1 then
					main.Configurations[parsedValue[1]] = storedValue
				elseif maxIterations == 2 then
					main.Configurations[parsedValue[1]][parsedValue[2]] = storedValue
				elseif maxIterations == 3 then
					main.Configurations[parsedValue[1]][parsedValue[2]][parsedValue[3]] = storedValue
				elseif maxIterations == 4 then
					main.Configurations[parsedValue[1]][parsedValue[2]][parsedValue[3]][parsedValue[4]] = storedValue
				else
					warn(script:GetFullName() .. ".main:SetUpAttributeConfigurations():listenToAttribute() could not change main.Configuration<indexes> because the nested configuration is too deep. Please add availability to nest: " .. maxIterations .. " deep.")
				end
			end
			script:GetAttributeChangedSignal(fixedNamingScheme):Connect(listenToAttribute)
		end
	end
	
	--[[
	Adds functionality to change main.Configurations.EnemyFolders
	Accepts overloads:
	option : boolean → true: add a value to main.Configurations.EnemyFolders, false: remove a value from main.Configurations.EnemyFolders
	value : Instance | table → Instance: Adds the instance directly to the folder, table will attempt to find the instance through the workspace hierarchy
	using strings for names. If not every value is a string, the entire search will be thrown out. Any issues with this proccess will throw a warning.
	]]
	script.ChangeEnemyTable.Event:Connect(function(option : boolean, value : Folder | table)
		local toBeChangedFolder : Folder
		if typeof(value) == "Instance" then
			toBeChangedFolder = value
		elseif typeof(value) == "table" then
			local tempFolder : Instance = nil
			for i, v in pairs(value) do
				if type(v) ~= "string" then
					warn(script:GetFullName() .. ".script.ChangeEnemyTable.Event recieved overload 'value' with a non-string value inside the table.")
					tempFolder = nil
					break
				end
				
				if i == 1 then
					tempFolder = workspace:FindFirstChild(v)
				else
					tempFolder = tempFolder:FindFirstChild(v)
				end
				if tempFolder == nil then
					warn(script:GetFullName() .. ".script.ChangeEnemyTable.Event tried to find a Folder with name: " .. v .. ". However, it could not be found.")
					break
				end
			end
			
			toBeChangedFolder = tempFolder
		else
			warn(script:GetFullName() .. ".script.ChangeEnemyTable.Event recieved an unusable 'value' overload. Recieved value: ", value, " (with type: " .. typeof(value) .. ").")
		end
		
		-- Do nothing if toBeAddedFolder is nil
		if toBeChangedFolder == nil then
			return
		end
		
		-- If 'option' is true, add the folder to main.Configurations.EnemyFolders, otherwise try to remove the value. Will throw a warning if the value cannot be found inside the table.
		if option == true then
			table.insert(main.Configurations.EnemyFolders, toBeChangedFolder)
		elseif option == false then
			local index = table.find(main.Configurations.EnemyFolders, toBeChangedFolder) -- Tries to find the index the folder is at
			
			if index then -- Remove the folder at the index
				table.remove(main.Configurations.EnemyFolders, index)
			else -- If the flolder was not found, throw an warning
				warn(script:GetFullName() .. ".script.ChangeEnemyTable.Event could not find folder '" .. toBeChangedFolder:GetFullName() .. "' inside main.Configurations.EnemyFolders.")
			end
		end
	end)
	
	--[[
	Adds functionality to change main.Configurations.RaycastParams.IgnoreInViewChecking
	Accepts overloads:
	option : boolean → true: add a value to main.Configurations.RaycastParams.IgnoreInViewChecking, false: remove a value from main.Configurations.RaycastParams.IgnoreInViewChecking
	value : Instance | table → Instance: Adds the instance directly to the folder, table will attempt to find the instance through the workspace hierarchy
	using strings for names. If not every value is a string, the entire search will be thrown out. Any issues with this proccess will throw a warning.
	]]
	script.ChangeIgnoreViewTable.Event:Connect(function(option : boolean, value : Folder | table)
		local toBeChangedFolder : Folder
		if typeof(value) == "Instance" then
			toBeChangedFolder = value
		elseif typeof(value) == "table" then
			local tempFolder : Instance = nil
			for i, v in pairs(value) do
				if type(v) ~= "string" then
					warn(script:GetFullName() .. ".script.ChangeIgnoreViewTable.Event recieved overload 'value' with a non-string value inside the table.")
					tempFolder = nil
					break
				end

				if i == 1 then
					tempFolder = workspace:FindFirstChild(v)
				else
					tempFolder = tempFolder:FindFirstChild(v)
				end
				if tempFolder == nil then
					warn(script:GetFullName() .. ".script.ChangeIgnoreViewTable.Event tried to find a Folder with name: " .. v .. ". However, it could not be found.")
					break
				end
			end

			toBeChangedFolder = tempFolder
		else
			warn(script:GetFullName() .. ".script.ChangeIgnoreViewTable.Event recieved an unusable 'value' overload. Recieved value: ", value, " (with type: " .. typeof(value) .. ").")
		end

		-- Do nothing if toBeAddedFolder is nil
		if toBeChangedFolder == nil then
			return
		end

		--[[
		If 'option' is true, add the folder to main.Configurations.RaycastParams.IgnoreInViewChecking
		, otherwise try to remove the value. Will throw a warning if the value cannot be found inside the table.
		]]
		if option == true then
			table.insert(main.Configurations.RaycastParams.IgnoreInViewChecking, toBeChangedFolder)
		elseif option == false then
			local index = table.find(main.Configurations.RaycastParams.IgnoreInViewChecking, toBeChangedFolder) -- Tries to find the index the folder is at

			if index then -- Remove the folder at the index
				table.remove(main.Configurations.RaycastParams.IgnoreInViewChecking, index)
			else -- If the flolder was not found, throw an warning
				warn(script:GetFullName() .. ".script.ChangeIgnoreViewTable.Event could not find folder '" .. toBeChangedFolder:GetFullName() .. "' inside main.Configurations.RaycastParams.IgnoreInViewChecking.")
			end
		end
	end)
end

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

-- Tries to run the code for main.Configuratons.AllowAdjustableSettings. We don't care if it fails.
local ignore, ignored = pcall(function()
	main:SetUpAttributeConfigurations()
end)

while task.wait() do
	main:UpdateEnemyTable()
end
