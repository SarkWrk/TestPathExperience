local rig = script.Parent.Parent -- The rig containing the script



-- Sets up the main table
local main = {}

-- General predefined variables used
main.RunService = game:GetService("RunService")
main.LastCheckedEnemyPositions = 0 -- Used for main.Configurations.VisualCheckDelay
main.LastUpdatedEnemyTable = 0 -- Used for main.Configurations.EnemyTableUpdateDelay
main.CanSeeEnemy = false -- If the rig can see an enemy
main.StopViewChecking = false -- Whether the programme should stop checking if the rig can see an enemy. THIS SHOULD ONLY BE USED IN EMERGENCIES.
main.RandomNumberGenerator = Random.new()
main.LastShot = 0 -- Used to store the time that the rig last shot a bullet
main.Died = false
main.OutOfAmmo = false -- Used to indicate to the script whether it's out of ammo or not
main.NulledAdjustableSettings = true -- Used to indicate whether the adjustable settings attributes have been nilled out
main.CreatedAdjustableSettings = false -- Used to indicate whether the adjustable settings were created
main.ShootingRaycastIgnoredParts = {} -- Table of instances that get ignored when shooting via raycasts
main.ViewCheckingIgnoredParts = {} -- Table of instances that get ignored when viewchecking
main.TargetPosition = Vector3.new(0,0,0) -- Keeps track of the target position, and if the target's magnitude changes enough, makes the rig look at the target



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
main.Configurations.EnemyTags = { --[[
Table to store enemies that are tagged.
Can be added and removed from via script.ChangeEnemyTable if main.Configurations.AllowAdjustableSettings is set to true.
Information on how to add/remove folders will be in the listener event function.
]]
	"Goal",
}
main.Configurations.LookDirectionFidelity = 5 -- If the .magnitude of the target's position compared to it's previous position has changed >=x, makes the rig look at the target



-- Table used to store configuations for CombatInformation
main.Configurations.WeaponsConfigurations = {}

-- Predefined variables used for weapons
main.Configurations.WeaponsConfigurations.MeleeAvailable = false -- Whether the script will allow meleeing
main.Configurations.WeaponsConfigurations.GunAvailable = true -- Whether the script will allow shooting
main.Configurations.WeaponsConfigurations.NewTargetChance = 5 -- Chance to target a new target if the previous target is still visible
main.Configurations.WeaponsConfigurations.ShootFromLocation = rig.Head -- The part which shooting functions use to shoot from



-- Table to store all the score multipliers for targetting with a gun
main.Configurations.WeaponsConfigurations.GunScoreMultipliers = {}

-- The score multipliers
main.Configurations.WeaponsConfigurations.GunScoreMultipliers.DistanceScoreMultiplier = 1 -- How much to multiply the distance the target is by x
main.Configurations.WeaponsConfigurations.GunScoreMultipliers.HealthScoreMultiplier = 2 -- How much to multiply the health of the target by x
main.Configurations.WeaponsConfigurations.GunScoreMultipliers.ThreatLevelScoreMultiplier = 3  -- How much to multiply the threat level of the target by x
main.Configurations.WeaponsConfigurations.GunScoreMultipliers.DefenseScoreMultiplier = 10  -- How much to multiply the defense of the target by x



-- Sets up a table that stores the parameters for a RaycastParams.new() used in the "Raycast" bullet type
main.Configurations.WeaponsConfigurations.ShootingRaycastParams = {}

-- Defines the variables
main.Configurations.WeaponsConfigurations.ShootingRaycastParams.FilterType = "Exclude"
main.Configurations.WeaponsConfigurations.ShootingRaycastParams.FilterDecendents = { -- Table of tags to get filtered in/out by the raycast
	"NPC",
	"Bullet",
}

-- Table to store configurations for the RaycastParams for the viewcheck raycast
main.Configurations.RaycastParams = {}

-- Predefined variables inside main.Configurations.RaycastParams
main.Configurations.RaycastParams.FilterType = "Exclude" -- Case specific
main.Configurations.RaycastParams.RespectCanCollide = false
main.Configurations.RaycastParams.IgnoreInViewChecking = { --[[
Table used to store tagged parts that the rig should ignore when checking if it can see an enemy.
Can be added and removed from via script.ChangeIgnoreViewTable if main.Configurations.AllowAdjustableSettings is set to true.
Information on how to add/remove parts will be in the listener event function.
]]
	"NPC",
	"Bullet",
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
	"WeaponsConfigurations/GunAvailable",
	"AllowAdjustableSettings",
}



-- Sets up a table used for information cloned from CombatInformation.GunStatistics
main.GunStatistics = {}	



-- Sets up the CombatInformation table to store information used for combat
CombatInformation = {}

-- Sets up some general housekeeping of variables for the script
CombatInformation.Target = {Favoured = nil, Total = {}} --[[ The favoured value is the previous target shot at, and is much more likely to be chosen.
The total value is filled with nested tables with information about enemies that can be seen.]]
CombatInformation.GunStatistics = { -- Table referenced when shooting
	Damage = 10, -- In HP
	ShotDelay = 0.05, -- In seconds
	AmountOfShots = 10, -- In bullets
	ShotsPerBurst = 3, -- In amount of bullets per shot
	DelayBetweenBurst = nil, -- Leave nil if not in burst
	Range = 250, -- In studs
	BulletDrop = 0.1, -- In studs per second, only used when TypeOfBullet type is NOT 1
	TypeOfBullet = 1, -- 1 : Raycast, 2 : Part
	XSpread = 3, -- In degrees, +/-x
	YSpread = 3, -- In degrees, +/-y
	BulletSpeed = 100, -- In studs per second, only used if TypeOfBullet is NOT 1
	ReloadSpeed = 1, -- In seconds
	MagazineSize = 150, -- Bullets per magazine
	ReserveSize = 10000, -- Total bullets that can be shot
}



-- Sets up a table to store information that is used in visualisations
VisualisationInformation = {}

-- Pre-defined variables used for visualising certain information
VisualisationInformation.VisualiseShooting = true -- Whether to show the raycast when shooting if the raycast hits anything
VisualisationInformation.VisualisationFolderName = "ShootingVisualiser" .. main.RandomNumberGenerator:NextNumber(1, 10000000000)
VisualisationInformation.VisualisationFolder = nil



-- Listens for main.RunService.Heartbeat() before checking if the rig can see an enemy. If the rig can see an enemy then the CanSeeEnemy attribute is set to true, otherwise false.
main.EnemySightCheck = main.RunService.Heartbeat:Connect(function() : nil
	-- Checks if the rig is out of ammo, and if so will not stop the rig from pathfinding anymore because the rig can't shoot
	if main.OutOfAmmo == true then
		main.StopViewChecking = true
	end
	
	-- Checks if main.StopViewChecking is set to true. If it is, it returns
	if main.StopViewChecking == true then
		main.EnemySightCheck:Disconnect() -- Disconnects the RBXScriptConnection
		return
	end
	
	-- Checks if main.EnemyTable is empty or not. If it is, it returns
	if main.EnemyTable == {} then
		return
	end
	
	if tick()-main.LastCheckedEnemyPositions >= main.Configurations.VisualCheckDelay then
		local hasSeenEnemy = false -- Tracks to see if the rig has seen an enemy
		CombatInformation.Target.Total = {} -- Reset the CombatInformation.Target.Total table
		
		for _, enemy : Part | Model in pairs(main.EnemyTable) do
			local endPart : Part
			
			-- Gets the part to raycast to via Model.PrimaryPart, or the part itself. If there is no part, then returns
			if enemy.ClassName == "Model" then
				endPart = enemy.PrimaryPart
			elseif enemy.ClassName == "Part" then
				endPart = enemy
			else
				continue
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
			
			-- Continue if the endPart no longer exists
			if not endPart then
				continue
			end
			
			-- Creates a new CFrame that looks in the direction of the enemy and sets the view distance using main.Configurations.ViewDistance
			local newView = CFrame.lookAt(startPart.Position, endPart.Position)
			local viewDirection = newView.LookVector * main.Configurations.ViewDistance
			
			-- Compared the viewDirection Y orientation and start part Y orientation so check whether the rig can see the enemy using main.Configurations.ViewRadius, if not: returns
			local _, startYOrientation, _ = startPart.CFrame:ToEulerAnglesXYZ()
			local _, endYOrientation, _ = newView:ToOrientation()
			
			if math.abs(math.deg(startYOrientation) - math.deg(endYOrientation)) <= main.Configurations.ViewRadius then
				continue
			end

			-- Sets up the RaycastParams for the raycast
			local rayCastParams = RaycastParams.new()
			rayCastParams.FilterType = Enum.RaycastFilterType[main.Configurations.RaycastParams.FilterType]
			rayCastParams.RespectCanCollide = main.Configurations.RaycastParams.RespectCanCollide
			rayCastParams.FilterDescendantsInstances = {main.ViewCheckingIgnoredParts, VisualisationInformation.VisualisationFolder}
			
			-- At this point, the programme has identified the end part and the start part to raycast to
			local raycast = game.Workspace:Raycast(startPart.Position, viewDirection, rayCastParams)
			
			if raycast then
				if raycast.Instance then
					if raycast.Instance:IsDescendantOf(enemy) or raycast.Instance == enemy then
						-- Code to store information about the enemy if it has a humanoid, if there's no humanoid it is not considered an enemy
						local enemyHumanoid : Humanoid = enemy:FindFirstChild("Humanoid")
						
						if enemyHumanoid then
							local storedInformation = {
								Distance = math.huge, -- The distance the enemy is from the rig
								Enemy = endPart, -- Part used for targetting
								ThreatLevel = enemy:GetAttribute("ThreatLevel") or 1, -- The TreatLevel of the enemy
								Health = 100, -- The health of the enemy, defaults to 100
								Defense = enemy:GetAttribute("Defense") or 0, -- The enemy's defense, if nil defaults to 0
							}

							storedInformation.Distance = (startPart.Position-endPart.Position).Magnitude
							
							storedInformation.Health = enemyHumanoid.Health
							
							-- Checks if the enemy is alive, and if not the programme does not count the enemy as "alive"
							if storedInformation.Health <= 0 then
								continue
							end

							table.insert(CombatInformation.Target.Total, storedInformation) -- Adds the endPart to the target list for shooting

							hasSeenEnemy = true
						end
					end
				end
			end
		end
		
		-- Sets the CanSeeEnemy attribute and main.CanSeeEnemy to whatever hasSeenEnemy is
		script:SetAttribute("CanSeeEnemy", hasSeenEnemy)
		main.CanSeeEnemy = hasSeenEnemy
	end
end)

-- Listens for when RigDied fires, and then proceeds to safely halt the programme
script.Parent.RigDied.Event:Connect(function()
	main.Died = true
	main.StopViewChecking = true
end)

--[[
Function used to visualise the shot of a gun if the bullet type is set to "Raycast"
Accepts overloads:
distance : number → The distance of the raycast
startPosition : Vector3 → Where to start the beam from
endPosition : Vector3 → Where the raycast hit
]]
function VisualisationInformation:VisualiseShootingRaycast(distance : number, startPosition : Vector3, endPosition : Vector3) : nil
	-- Tries to find if a folder to store all the paths has already been made. If it hasn't, then it creates the folder
	local foundFolder = VisualisationInformation.VisualisationFolder
	if foundFolder then
	else
		-- Creates a new folder with the name "PathVisualiser" and parents it to the workspace
		foundFolder = Instance.new("Folder")
		foundFolder.Name = VisualisationInformation.VisualisationFolderName
		foundFolder.Parent = workspace
		VisualisationInformation.VisualisationFolder = foundFolder
	end
	
	local midPoint = Vector3.new((startPosition.X + endPosition.X)/2, (startPosition.Y + endPosition.Y)/2, (startPosition.Z + endPosition.Z)/2) -- Gets the midpoint to place the beam

	local trackingString = endPosition.X .. ", " .. endPosition.Y .. ", " .. endPosition.Z

	-- Creates the beam
	local beam = Instance.new("Part")
	beam.Size = Vector3.new(distance, 0.3, 0.3)
	beam.Shape = Enum.PartType.Cylinder
	beam.CanCollide = false
	beam.CastShadow = false
	beam.CFrame = CFrame.lookAt(midPoint, endPosition) * CFrame.Angles(0, math.rad(90), 0)
	beam.Anchored = true
	beam.Color = Color3.new(1, 1, 0.498039)
	beam.Material = "Neon"
	beam.Transparency = 0.5
	beam.Locked = true
	beam.Name = "Bullet Tracer"
	beam.Parent = foundFolder

	game:GetService("Debris"):AddItem(beam, CombatInformation.GunStatistics.ShotDelay) -- Destroys the tracer after CombatInformation.GunStatistics.ShotDelay amount of seconds
end

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
				if main.Configurations.AllowAdjustableSettings == false then
					return
				end
				
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
	
	-- Removes the created attributes from the function above
	function main:RemoveAttributeConfigurations()
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

			script:SetAttribute(fixedNamingScheme, nil) -- Removes the created attribute
		end
	end
	
	--[[
	Adds functionality to change main.Configurations.EnemyTags
	Accepts overloads:
	option : boolean → true: add a value to main.Configurations.EnemyFolders, false: remove a value from main.Configurations.EnemyFolders
	value : string: Adds the string directly to the folder
	]]
	script.ChangeEnemyTable.Event:Connect(function(option : boolean, value : Folder | table)
		if main.Configurations.AllowAdjustableSettings == false then
			return
		end
		if typeof(value) == "string" then
		else
			warn(script:GetFullName() .. ".script.ChangeEnemyTable.Event recieved an unusable 'value' overload. Recieved value: ", value, " (with type: " .. typeof(value) .. ").")
		end
		
		-- If 'option' is true, add the folder to main.Configurations.EnemyFolders, otherwise try to remove the value. Will throw a warning if the value cannot be found inside the table.
		if option == true then
			table.insert(main.Configurations.EnemyTags, value)
		elseif option == false then
			local index = table.find(main.Configurations.EnemyTags, value) -- Tries to find the index the folder is at
			
			if index then -- Remove the folder at the index
				table.remove(main.Configurations.EnemyTags, index)
			else -- If the flolder was not found, throw an warning
				warn(script:GetFullName() .. ".script.ChangeEnemyTable.Event could not find folder '" .. value .. "' inside main.Configurations.EnemyFolders.")
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
		if main.Configurations.AllowAdjustableSettings == false then
			return
		end
		
		if typeof(value) == "string" then
		else
			warn(script:GetFullName() .. ".script.ChangeIgnoreViewTable.Event recieved an unusable 'value' overload. Recieved value: ", value, " (with type: " .. typeof(value) .. ").")
		end

		--[[
		If 'option' is true, add the folder to main.Configurations.RaycastParams.IgnoreInViewChecking
		, otherwise try to remove the value. Will throw a warning if the value cannot be found inside the table.
		]]
		if option == true then
			table.insert(main.Configurations.RaycastParams.IgnoreInViewChecking, value)
		elseif option == false then
			local index = table.find(main.Configurations.RaycastParams.IgnoreInViewChecking, value) -- Tries to find the index the folder is at

			if index then -- Remove the folder at the index
				table.remove(main.Configurations.RaycastParams.IgnoreInViewChecking, index)
			else -- If the flolder was not found, throw an warning
				warn(script:GetFullName() .. ".script.ChangeIgnoreViewTable.Event could not find folder '" .. value .. "' inside main.Configurations.RaycastParams.IgnoreInViewChecking.")
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
			for _, tag : string in pairs(main.Configurations.EnemyTags) do
				local folder = game:GetService("CollectionService"):GetTagged(tag)
				local success2, no2 = pcall(function()
					for _, enemy : Part | Model in pairs(folder) do
						-- If the enemy's attribute "Invisible" is true, ignore the enemy
						if enemy:GetAttribute("Invisible") == true then
							continue
						end
						
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

--[[
Function used to update main.ViewCheckingIgnoredParts and main.ShootingRaycastIgnoredParts
]]
function main:UpdateTables() : boolean
	local notFailed = true
	
	local success, cant = pcall(function()
		table.clear(main.ShootingRaycastIgnoredParts)
		
		for _, tag in pairs(main.Configurations.WeaponsConfigurations.ShootingRaycastParams.FilterDecendents) do
			table.insert(main.ShootingRaycastIgnoredParts, game:GetService("CollectionService"):GetTagged(tag))
		end
	end)
	
	if not success then
		if cant then
			notFailed = false
			warn(script:GetFullName() .. ".main:UpdateTables() could not update the main.ShootingRaycastIgnoredParts table. Error: ", cant)
		end
	end
	
	local success, cant = pcall(function()
		table.clear(main.ViewCheckingIgnoredParts)

		for _, tag in pairs(main.Configurations.RaycastParams.IgnoreInViewChecking) do
			table.insert(main.ViewCheckingIgnoredParts, game:GetService("CollectionService"):GetTagged(tag))
		end
	end)

	if not success then
		if cant then
			notFailed = false
			warn(script:GetFullName() .. ".main:UpdateTables() could not update the main.ViewCheckingIgnoredParts table. Error: ", cant)
		end
	end
	
	return notFailed
end

--[[
Gets the score of an enemy, used to decide on a target.
Accepts overloads:
information : table → The table in CombatInformation.Target.Total<index>
weaponType : number → 1 = gun, 2 = melee
]]
function main:GetTargetScore(information : table, weaponType : number) : number
	local toBeAddedScores = {}
	local score = 0
	
	-- If the weapon is a gun
	if weaponType == 1 then
		-- List of all the scores
		toBeAddedScores.HealthScore = main.Configurations.WeaponsConfigurations.GunScoreMultipliers.HealthScoreMultiplier -
			(main.Configurations.WeaponsConfigurations.GunScoreMultipliers.HealthScoreMultiplier/information.Health)
		toBeAddedScores.ThreatLevelScore = information.ThreatLevel /main.Configurations.WeaponsConfigurations.GunScoreMultipliers.ThreatLevelScoreMultiplier
		toBeAddedScores.DefenseScore = information.Defense/main.Configurations.WeaponsConfigurations.GunScoreMultipliers.DefenseScoreMultiplier
		
		-- Checks if the enemy is within targetting distance, and if not sets the distance multiplier to math.huge
		if information.Distance > CombatInformation.GunStatistics.Range then
			toBeAddedScores.DistanceScore = math.huge
		else
			toBeAddedScores.DistanceScore = information.Distance * main.Configurations.WeaponsConfigurations.GunScoreMultipliers.DistanceScoreMultiplier
		end
	-- If the weapon is a melee
	elseif weaponType == 2 then
		-- pass
	end
	
	-- Adds up all the scores
	for i, v in pairs(toBeAddedScores) do
		score += v
	end
	
	return score
end

--[[
Identifies a target and returns a part to target
Accepts overloads:
weaponType : number → 1 = gun, 2 = melee
]]
function main:IdentifyTarget(weaponType : number) : Part
	--[[ Checks if there's already a target, and if there is then has a chance to return it instead of identifying a new target 
												     if it's in CombatInformation.Target.Total and within targetting distance]]
	if CombatInformation.Target.Favoured ~= nil then
		local foundTarget = false
		-- Tries to find the target in CombatInformation.Target.Total
		for i, v in pairs(CombatInformation.Target.Total) do
			if v.Enemy == CombatInformation.Target.Favoured then
				if weaponType == 1 then
					if v.Distance > CombatInformation.GunStatistics.Range then
						break
					end
				end
				
				foundTarget = true
				break
			end
		end
		
		-- Randomly chooses if the target will be the favoured target if the target was found
		if foundTarget == true then
			local selected = main.RandomNumberGenerator:NextInteger(1, main.Configurations.WeaponsConfigurations.NewTargetChance)
			
			if selected < main.Configurations.WeaponsConfigurations.NewTargetChance then
				-- Will select a new target
			else -- Selects the old target
				return CombatInformation.Target.Favoured
			end
		end
	end
	
	local targetScores = {}
	
	-- Collects all the scores of all the enemies in CombatInformation.Target.Total
	for i, v in pairs(CombatInformation.Target.Total) do
		table.insert(targetScores, {Target = v.Enemy, Score = main:GetTargetScore(v, weaponType)})
	end
	
	-- Randomizes the table, just in case there are enemies that have the same score
	main.RandomNumberGenerator:Shuffle(targetScores)
	
	local placesTable = {
		[1] = {enemy = nil, score = math.huge},
		[2] = {enemy = nil, score = math.huge},
		[3] = {enemy = nil, score = math.huge}
	}
	
	-- Fills out the places table based on the scores
	for i, v in pairs(targetScores) do
		if v.Score < placesTable[1].score then
			placesTable[3].enemy = placesTable[2].enemy
			placesTable[3].score = placesTable[2].score
			placesTable[2].enemy = placesTable[1].enemy
			placesTable[2].score = placesTable[1].score
			placesTable[1].enemy = v.Target
			placesTable[1].score = v.Score
		elseif v.Score < placesTable[2].score then
			placesTable[3].enemy = placesTable[2].enemy
			placesTable[3].score = placesTable[2].score
			placesTable[2].enemy = v.Target
			placesTable[2].score = v.Score
		elseif v.Score < placesTable[3].score then
			placesTable[3].enemy = v.Target
			placesTable[3].score = v.Score
		end
	end
	
	local totalSlots = 0
	
	-- Gets the total number of places filled out
	for i, v in pairs(placesTable) do
		if v.enemy ~= nil then
			totalSlots += 1
		end
	end
	
	-- Returns if there's no filled out places
	if totalSlots == 0 then
		return nil
	end
	
	-- Selects a random target from the the total amount of places filled out
	local randomlySelected = placesTable[main.RandomNumberGenerator:NextInteger(1, totalSlots)].enemy
	
	-- Sets the favoured target to the selected target
	CombatInformation.Target.Favoured = randomlySelected
	
	return randomlySelected
end

-- This function is used to reload the weapon and removes bullets from the reserves
function main:Reload() : nil
	local bulletsToRemove = math.abs(CombatInformation.GunStatistics.MagazineSize-main.GunStatistics.Magazine) --[[ Calculates the total number of bullets to remove from reserves,
																													uses math.abs so that bullets are always removed, never added ]]
	main.GunStatistics.Reserve -= bulletsToRemove
	main.GunStatistics.Magazine = CombatInformation.GunStatistics.MagazineSize
	
	if main.GunStatistics.Reserve > 0 then
		script:SetAttribute("Reloading", true)
		task.wait(CombatInformation.GunStatistics.ReloadSpeed)
		script:SetAttribute("Reloading", false)
	else
		main.OutOfAmmo = true
		script:SetAttribute("OutOfBullets", true)
	end
end

-- This function is used to remove a bullet from the magazine
function main:DepleteBullet() : nil
	main.GunStatistics.Magazine -= 1
	script.Shot:Fire()
	
	if main.GunStatistics.Magazine <= 0 then
		main:Reload()
	end
end

-- Creates a shot that is fired
function main:FireGun() : nil
	-- Checks if the time between shots is >= CombatInformation.GunStatistics.ShotDelay, and if not returns
	if tick()-main.LastShot < CombatInformation.GunStatistics.ShotDelay then
		return
	end
	main.LastShot = tick() -- Updates main.LastShot
	
	local target = main:IdentifyTarget(1) -- Gets a target

	-- Nil checks the target to make sure there's a target selected
	if target == nil then
		return
	end
	
	-- Makes the rig look at the target if the target is far enough away from it's previously tracked position
	if (target.Position-main.TargetPosition).Magnitude >= main.Configurations.LookDirectionFidelity then
		main.TargetPosition = target.Position
		local lookAt = CFrame.lookAt(rig.Head.Position, main.TargetPosition)
		
		local _, y, _ = lookAt:ToEulerAnglesXYZ()
		
		rig.Head.CFrame = CFrame.new(rig.Head.Position) * CFrame.Angles(0, math.deg(y), 0)
	end
	
	-- Identifies if the gun is a burst gun or not
	local burstWeapon = false
	if CombatInformation.GunStatistics.DelayBetweenBurst ~= nil then
		burstWeapon = true
	end
	
	-- Saves the headPosition of where the shooting happens
	local startingPosition = main.Configurations.WeaponsConfigurations.ShootFromLocation.Position
	
	-- Creates a CFrame that looks at the target
	local lookAtCFrame = CFrame.lookAt(startingPosition, target.Position)
	
	-- Adds in a spread factor to the CFrame.LookAt for where to shoot
	local function CalculateSpread() : CFrame
		local spreadX = main.RandomNumberGenerator:NextNumber(-CombatInformation.GunStatistics.XSpread, CombatInformation.GunStatistics.XSpread)
		local spraedY = main.RandomNumberGenerator:NextNumber(-CombatInformation.GunStatistics.YSpread, CombatInformation.GunStatistics.YSpread)

		-- Factors spread into the lookAtCFrame
		local adjustedCFrame = lookAtCFrame * CFrame.Angles(math.rad(spreadX), math.rad(spraedY), 0)

		-- Gets the adjustedCFrame.LookVector and multiplies it by CombatInformation.GunStatistics.Range to get the full distance of the shot
		local maxDistance = adjustedCFrame
		
		return maxDistance
	end
	
	-- Creates a raycast and if it hits anything, will attempt to find the humanoid of the hit object and damage it dealing CombatInformation.GunStatistics.Damage HP
	if CombatInformation.GunStatistics.TypeOfBullet == 1 then
		local hitRaycastParams = RaycastParams.new()
		hitRaycastParams.FilterType = Enum.RaycastFilterType[main.Configurations.WeaponsConfigurations.ShootingRaycastParams.FilterType]
		hitRaycastParams.FilterDescendantsInstances = {main.ShootingRaycastIgnoredParts, rig, VisualisationInformation.VisualisationFolder}
		hitRaycastParams.RespectCanCollide = false

		-- If the gun is a burst, shoot CombatInformation.GunStatistics.ShotsPerBurst times
		for i = 1, (burstWeapon == true) and CombatInformation.GunStatistics.ShotsPerBurst or 1 do
			main:DepleteBullet() -- Remove a bullet due to shooting
			
			-- If the gun is a shotgun, shoot CombatInformation.GunStatistics.AmountOfShots times
			for i = 1, CombatInformation.GunStatistics.AmountOfShots, 1 do
				local rayCast = game.Workspace:Raycast(startingPosition, CalculateSpread().LookVector * CombatInformation.GunStatistics.Range, hitRaycastParams)

				if rayCast then
					local hitPart = rayCast.Instance
					if hitPart then
						
						-- Visualises the bullet path if VisualisationInformation.VisualiseShooting is set to true
						if VisualisationInformation.VisualiseShooting == true then
							VisualisationInformation:VisualiseShootingRaycast(rayCast.Distance, startingPosition, rayCast.Position)
						end

						if hitPart:IsDescendantOf(rig) then
							print("Hit self")
							continue
						end

						local hitHumanoid : Humanoid = nil

						-- Attempts to find the Humanoid of the hit part
						hitHumanoid = hitPart:FindFirstChildOfClass("Humanoid")
						if hitHumanoid == nil then
							local partParent = hitPart.Parent
							
							if partParent == nil then
							else
								hitHumanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid")
							end
						end

						-- If no Humanoid is found, return
						if hitHumanoid == nil then
							continue
						end
						
						-- Calculates the damage that should be dealt to what was hit
						local damage = CombatInformation.GunStatistics.Damage
						local defense = hitPart:GetAttribute("Defense")
						if defense == nil then
							if hitPart.Parent:IsA("Model") then
								defense = hitPart.Parent:GetAttribute("Defense")
							end
						end
						
						if defense ~= nil then
							damage = damage - (damage/100*defense)
							
							-- Makes sure the bullet doesn't heal the target
							if damage < 0 then
								damage = 0
							end
						end

						-- Deals damage to the hit part
						hitHumanoid:TakeDamage(damage)
					end
				end
			end
			
			-- If the gun is a burst, halt for CombatInformation.GunStatistics.DelayBetweenBurst seconds
			if burstWeapon == true then
				task.wait(CombatInformation.GunStatistics.DelayBetweenBurst)
			end
		end
		-- Part bullets
	elseif CombatInformation.GunStatistics.TypeOfBullet == 2 then
		local bulletInformation = {
			Damage = CombatInformation.GunStatistics.Damage,
			Enemy = main.Configurations.EnemyTags,
			IgnoreTagged = main.Configurations.RaycastParams.IgnoreInViewChecking,
			MoveTowards = CalculateSpread(),
			BulletDrop = CombatInformation.GunStatistics.BulletDrop,
			DistanceTimeOut = CombatInformation.GunStatistics.Range,
			Speed = CombatInformation.GunStatistics.BulletSpeed,
		}
		
	end
	
	main.LastShot = tick() -- Updates main.LastShot
end

-- Function used to determine what method of fighting to use
function main:CombatDecider() : nil
	-- Melee will be added later, probably
	main:FireGun()
end

-- Function used to clone certain variables from CombatInformation.GunStatistics
function main:CloneGunStatistics()
	main.GunStatistics.Magazine = CombatInformation.GunStatistics.MagazineSize
	main.GunStatistics.Reserve = CombatInformation.GunStatistics.ReserveSize
end
main:CloneGunStatistics()

-- Update the enemy table
main.UpdateEnemyTableListener = main.RunService.Heartbeat:Connect(main.UpdateEnemyTable)

while task.wait() do
	if main.Died == true or main.OutOfAmmo == true then
		break
	end
	main:CombatDecider()
	if main:UpdateTables() == false then
		warn("Failed to update at least one table with main:UpdateTables().")
	end
	
	if main.NulledAdjustableSettings == true and main.Configurations.AllowAdjustableSettings == true then
		main:SetUpAttributeConfigurations()
		main.CreatedAdjustableSettings = true
		main.NulledAdjustableSettings = false
	elseif main.CreatedAdjustableSettings == true and main.Configurations.AllowAdjustableSettings == false then
		main:RemoveAttributeConfigurations()
		main.CreatedAdjustableSettings = false
		main.NulledAdjustableSettings = true
	end
end

script:SetAttribute("CanSeeEnemy", false) -- Sets the script's CanSeeEnemy attribute to false so that the pathfinding script won't be halted

-- Destroys the visualisation folder
if VisualisationInformation.VisualisationFolder ~= nil then
	VisualisationInformation.VisualisationFolder:Destroy()
end

main.UpdateEnemyTableListener:Disconnect()
main.EnemySightCheck:Disconnect()

script:SetAttribute("Shutoff", true) -- Publicises that the script is fully shut off and won't continue
