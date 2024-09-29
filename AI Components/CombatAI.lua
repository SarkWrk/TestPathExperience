local class = {}
class.interface = {}
class.schema = {}
class.metatable = {__index = class.schema}
class.schema.Setup = {}

function class.interface.New(owner : script, rig : Model, diedEvent : BindableEvent, locationToShootFrom : Part, weaponInformation : table, firedBindableEvent : BindableEvent)
	local self = setmetatable({}, class.metatable)

	self.Information = class.schema.Setup.NewBase(locationToShootFrom, firedBindableEvent)
	self.WeaponInformation = class.schema.Setup.CreateWeaponInformation(weaponInformation)
	self.VisualisationInformation = class.schema.Setup.CreateVisualisationInformation(self.Information.RandomNumberGenerator)
	self.RBXScriptConnections = {}
	self.ImportantInformation = {
		["rig"] = rig,
		["bulletFolder"] = workspace.Bullets,
		["script"] = owner,
	}

	diedEvent.Event:Connect(function()
		self.Information.Died = true
		self.Information.StopViewChecking = true
		
		self.CleanUp(self)
	end)

	-- Increments the frame counter
	self.RBXScriptConnections.FrameCounter = self.Information.RunService.Stepped:Connect(function()
		self.Information.Frames += 1
	end)

	-- Listens for self.Information.RunService.Heartbeat() before checking if the rig can see an enemy. If the rig can see an enemy then the CanSeeEnemy attribute is set to true, otherwise false.
	self.RBXScriptConnections.EnemySightCheck = self.Information.RunService.Heartbeat:Connect(function() : nil
		-- Checks if the rig is out of ammo, and if so will not stop the rig from pathfinding anymore because the rig can't shoot
		if self.Information.OutOfAmmo == true then
			self.Information.StopViewChecking = true
		end

		-- Checks if self.Information.StopViewChecking is set to true. If it is, it returns
		if self.Information.StopViewChecking == true then
			self.Information.EnemySightCheck:Disconnect() -- Disconnects the RBXScriptConnection
			return
		end

		-- Checks if self.Information.EnemyTable is empty or not. If it is, it returns
		if table.maxn(self.Information.EnemyTable) == 0 then
			print(self.ImportantInformation.script:GetFullName() .. ".Information.EnemyTable is empty.")
			return
		end

		if tick()-self.Information.LastCheckedEnemyPositions >= self.Information.Configurations.VisualCheckDelay then
			local hasSeenEnemy = false -- Tracks to see if the rig has seen an enemy

			self.WeaponInformation.Target.Total = {} -- Reset the self.WeaponInformation.Target.Total table

			for _, enemy : Part | Model in pairs(self.Information.EnemyTable) do
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
				local startPart : Part = rig:FindFirstChild(self.Information.Configurations.RaycastStart)

				if startPart == nil then
					if self.Information.Configurations.AllowAdjustableSettings == true and table.find(self.Information.Configurations.Attributes, "RaycastStart") then
						warn(self.ImportantInformation.script:GetFullName() .. ".Information.RunService.Heartbeat could not identify a part to start the raycast at. The start part can be changed.")
					else
						self.Information.StopViewChecking = true
						error(self.ImportantInformation.script:GetFullName() .. ".Information.RunService.Heartbeat could not identify a part to start the raycast at. The start part can not be changed.")
					end
					return
				end			

				-- Continue if the endPart no longer exists
				if not endPart then
					continue
				end

				-- Creates a new CFrame that looks in the direction of the enemy and sets the view distance using self.Information.Configurations.ViewDistance
				local newView = CFrame.lookAt(startPart.Position, endPart.Position)
				local viewDirection = newView.LookVector * self.Information.Configurations.ViewDistance

				-- Compared the viewDirection Y orientation and start part Y orientation so check whether the rig can see the enemy using self.Information.Configurations.ViewRadius, if not: returns
				local _, startYOrientation, _ = startPart.CFrame:ToEulerAnglesXYZ()
				local _, endYOrientation, _ = newView:ToOrientation()

				if math.abs(math.deg(startYOrientation) - math.deg(endYOrientation)) <= self.Information.Configurations.ViewRadius then
					continue
				end

				-- Sets up the RaycastParams for the raycast
				local rayCastParams = RaycastParams.new()
				rayCastParams.FilterType = Enum.RaycastFilterType[self.Information.Configurations.RaycastParams.FilterType]
				rayCastParams.RespectCanCollide = self.Information.Configurations.RaycastParams.RespectCanCollide
				rayCastParams.FilterDescendantsInstances = {self.Information.ViewCheckingIgnoredParts, self.VisualisationInformation.VisualisationFolder}

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

								table.insert(self.WeaponInformation.Target.Total, storedInformation) -- Adds the endPart to the target list for shooting

								hasSeenEnemy = true
							end
						end
					end
				end
			end

			-- Sets the CanSeeEnemy attribute and self.Information.CanSeeEnemy to whatever hasSeenEnemy is
			self.ImportantInformation.script:SetAttribute("CanSeeEnemy", hasSeenEnemy)
			self.Information.CanSeeEnemy = hasSeenEnemy
		end
	end)

	-- Makes the rig look at the current self.WeaponInformation.Target.Favoured
	self.RBXScriptConnections.SetLookAtCFrame = self.Information.RunService.Heartbeat:Connect(function()
		if self.Information.Frames % 60 == 0 then
			local success, e = pcall(function()
				-- Do nothing if the favoured target is nil
				if self.WeaponInformation.Target.Favoured == nil then
					return
				end

				-- If no AlignOrientation has been created, create one
				if self.Information.ViewAlignment == nil then
					local view = Instance.new("AlignOrientation")
					local attach = Instance.new("Attachment")
					attach.Name = "ViewAlignmentAttachment"
					attach.Parent = rig.PrimaryPart

					view.Mode = Enum.OrientationAlignmentMode.OneAttachment
					view.Attachment0 = attach
					view.RigidityEnabled = true
					view.Parent = owner

					self.Information.ViewAlignment = view
				end

				local target : Part = self.WeaponInformation.Target.Favoured

				self.Information.TargetPosition = target.Position

				local look = CFrame.lookAt(rig.PrimaryPart.CFrame.Position, Vector3.new(target.Position.X, rig.PrimaryPart.CFrame.Y, target.Position.Z)) --[[
				^^ Creates a CFrame which looks at the target's x and z position, IGNORING IT'S Y POSITION]]

				self.Information.ViewAlignment.CFrame = look
			end)

			-- If the above errors, warn the error
			if not success then
				warn(e)
			end
		end
	end)

	-- Update the enemy table
	self.RBXScriptConnections.UpdateEnemyTableListener = self.Information.RunService.Heartbeat:Connect(function()
		self.UpdateEnemyTable(self)
	end)

	self.CloneGunStatistics(self)
	self.AdjustableSettings(self)

	return self
end

function class.schema.Setup.CreateConfigurations(location : Part)
	-- Sets up the configuration table
	local Configurations = {}



	-- Predefines some information in Base.Configuration
	Configurations.AllowAdjustableSettings = true -- Whether to allow other scripts to change configuration settings in the script via attribute changes
	Configurations.VisualCheckDelay = 0.1 -- Used to delay times between raycasting, in seconds
	Configurations.RaycastStart = "Head" -- A string identifier for the part used to check from. Must be a child of the rig
	Configurations.EnemyTableUpdateDelay = 0.1 -- Used to decide how often to update Base.EnemyTable, in seconds
	Configurations.ViewDistance = 100 -- How far the rig can see, in studs
	Configurations.ViewRadius = 30 -- FOV of the rig, in +/-x, therefore: FOV is double what is set
	Configurations.EnemyTags = { --[[
Table to store enemies that are tagged.
Can be added and removed from via script.ChangeEnemyTable if Base.Configurations.AllowAdjustableSettings is set to true.
Information on how to add/remove folders will be in the listener event function.
]]
		"Goal",
	}
	Configurations.LookDirectionFidelity = 5 -- If the .magnitude of the target's position compared to it's previous position has changed >=x, makes the rig look at the target



	-- Table used to store configuations for self.WeaponInformation
	Configurations.WeaponsConfigurations = {}

	-- Predefined variables used for weapons
	Configurations.WeaponsConfigurations.MeleeAvailable = false -- Whether the script will allow meleeing
	Configurations.WeaponsConfigurations.GunAvailable = true -- Whether the script will allow shooting
	Configurations.WeaponsConfigurations.NewTargetChance = 0 -- Chance to target a new target if the previous target is still visible
	Configurations.WeaponsConfigurations.ShootFromLocation = location -- The part which shooting functions use to shoot from
	Configurations.WeaponsConfigurations.MaxBulletCount = 1000 -- Maximum amount of bullets in the bulletFolder at a time



	-- Table to store all the score multipliers for targetting with a gun
	Configurations.WeaponsConfigurations.GunScoreMultipliers = {}

	-- The score multipliers
	Configurations.WeaponsConfigurations.GunScoreMultipliers.DistanceScoreMultiplier = 1 -- How much to multiply the distance the target is by x
	Configurations.WeaponsConfigurations.GunScoreMultipliers.HealthScoreMultiplier = 2 -- How much to multiply the health of the target by x
	Configurations.WeaponsConfigurations.GunScoreMultipliers.ThreatLevelScoreMultiplier = 3  -- How much to multiply the threat level of the target by x
	Configurations.WeaponsConfigurations.GunScoreMultipliers.DefenseScoreMultiplier = 10  -- How much to multiply the defense of the target by x



	-- Sets up a table that stores the parameters for a RaycastParams.new() used in the "Raycast" bullet type
	Configurations.WeaponsConfigurations.ShootingRaycastParams = {}

	-- Defines the variables
	Configurations.WeaponsConfigurations.ShootingRaycastParams.FilterType = "Exclude"
	Configurations.WeaponsConfigurations.ShootingRaycastParams.FilterDecendents = { -- Table of tags to get filtered in/out by the raycast
		"NPC",
		"Bullet",
	}

	-- Table to store configurations for the RaycastParams for the viewcheck raycast
	Configurations.RaycastParams = {}

	-- Predefined variables inside Base.Configurations.RaycastParams
	Configurations.RaycastParams.FilterType = "Exclude" -- Case specific
	Configurations.RaycastParams.RespectCanCollide = false
	Configurations.RaycastParams.IgnoreInViewChecking = { --[[
Table used to store tagged parts that the rig should ignore when checking if it can see an enemy.
Can be added and removed from via script.ChangeIgnoreViewTable if Base.Configurations.AllowAdjustableSettings is set to true.
Information on how to add/remove parts will be in the listener event function.
]]
		"NPC",
		"Bullet",
	}



--[[
Table used if Base.Configurations.AllowAdjustableSettings is set to true.
Indexes inside must align with their Base.Configurations indexes.
Values inside will be automatically be type checked using typeof().
If the typeof() returns nil, the attribute will be set to the default type.
Use "/" to denote a subfolder.
]]
	Configurations.Attributes = {
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
	
	return Configurations
end

function class.schema.Setup.NewBase(shootFromLocation : Part, firedBindableEvent : BindableEvent)
	local Base = {}
	
	Base.RunService = game:GetService("RunService")
	Base.LastCheckedEnemyPositions = 0 -- Used for Base.Configurations.VisualCheckDelay
	Base.LastUpdatedEnemyTable = 0 -- Used for Base.Configurations.EnemyTableUpdateDelay
	Base.CanSeeEnemy = false -- If the rig can see an enemy
	Base.StopViewChecking = false -- Whether the programme should stop checking if the rig can see an enemy. THIS SHOULD ONLY BE USED IN EMERGENCIES.
	Base.RandomNumberGenerator = Random.new() -- A random generator that is used instead of calling math.random()
	Base.LastShot = 0 -- Used to store the time that the rig last shot a bullet
	Base.Died = false
	Base.OutOfAmmo = false -- Used to indicate to the script whether it's out of ammo or not
	Base.NulledAdjustableSettings = true -- Used to indicate whether the adjustable settings attributes have been nilled out
	Base.CreatedAdjustableSettings = false -- Used to indicate whether the adjustable settings were created
	Base.ShootingRaycastIgnoredParts = {} -- Table of instances that get ignored when shooting via raycasts
	Base.ViewCheckingIgnoredParts = {} -- Table of instances that get ignored when viewchecking
	Base.TargetPosition = Vector3.new(0,0,0) -- Keeps track of the target position, and if the target's magnitude changes enough, makes the rig look at the target
	Base.ViewAlignment = nil -- The constrBasent modified to make the rig look at a target, LEAVE BLANK
	Base.ViewAlignmentAttachment = nil -- The attachment used with Base.ViewAlignment, LEAVE BLANK
	Base.Frames = 0 -- Total frames elapsed since spawned
	Base.FiredBindableEvent = firedBindableEvent -- The BindablEvent that gets fired when shooting 
	
	
	
	-- Sets up a table to store enemies in
	Base.EnemyTable = {}

	

	-- Setup configuration table
	Base.Configurations = class.schema.Setup.CreateConfigurations(shootFromLocation)
	
	return Base
end

function class.schema.Setup.CreateGunStatistics(informaton)
	local statistics = {}
	
	statistics.Damage = informaton.Damage -- In HP
	statistics.ShotDelay = informaton.ShotDelay -- In seconds
	statistics.AmountOfShots = informaton.AmountOfShots -- In bullets
	statistics.ShotsPerBurst = informaton.ShotsPerBurst -- In amount of bullets per shot
	statistics.DelayBetweenBurst = informaton.DelayBetweenBurst -- Leave nil if not in burst
	statistics.Range = informaton.Range -- In studs
	statistics.BulletDrop = informaton.BulletDrop -- In studs per second, only used when TypeOfBullet type is NOT 1
	statistics.TypeOfBullet = informaton.TypeOfBullet -- 1 : Raycast, 2 : Part
	statistics.XSpread = informaton.XSpread -- In degrees, +/-x
	statistics.YSpread = informaton.YSpread -- In degrees, +/-y
	statistics.BulletSpeed = informaton.BulletSpeed -- In studs per second, only used if TypeOfBullet is NOT 1
	statistics.ReloadSpeed = informaton.ReloadSpeed -- In seconds
	statistics.MagazineSize = informaton.MagazineSize -- Bullets per magazine
	statistics.ReserveSize = informaton.ReserveSize -- Total bullets that can be shot
	statistics.PierceAmount = informaton.PierceAmount -- In amount of parts to pierce, how many parts can be pierced by the bullet, only used if TypeOfBullet is NOT 1
	statistics.PierceFallOffDamage = informaton.PierceFallOffDamage -- In %, how much damage to take off when piercing a part
	
	return statistics
end

function class.schema.Setup.CreateWeaponInformation(information)
	local weaponInformation = {}
	
	weaponInformation.Target = {Favoured = nil, Total = {}} --[[ The favoured value is the previous target shot at, and is much more likely to be chosen.
	The total value is filled with nested tables with information about enemies that can be seen.]]
	weaponInformation.GunStatistics = class.schema.Setup.CreateGunStatistics(information.Gun)
	
	
	return weaponInformation
end

function class.schema.Setup.CreateVisualisationInformation(randomNumberGenerator : Random)
	local visualisationInformation = {}
	
	visualisationInformation.VisualiseShooting = true -- Whether to show the raycast when shooting if the raycast hits anything
	visualisationInformation.VisualisationFolderName = "ShootingVisualiser" .. randomNumberGenerator:NextNumber(1, 10000000000)
	visualisationInformation.VisualisationFolder = nil
	
	return visualisationInformation
end

--[[
This if statement contains code that is only ran IF main.Configurations.AllowAdjustableSettings is set to true
]]
function class.schema.AdjustableSettings(self : BaseCombatAI) : nil
	if self.Information.Configurations.AllowAdjustableSettings == true then
		--[[
		This function creates attributes based on main.Configurations.Attributes.
		The attributes will have the type that the main.Configurations<index> has, otherwise it defaults to the default.
		The code will listen in a coroutine if the attribute gets changed and will update the main.Configurations<index><value> accordingly.
		]]
		function class.schema.SetUpAttributeConfigurations(self : BaseCombatAI) : nil
			for _, attribute : string in pairs(self.Information.Configurations.Attributes) do
				local parsedValue : tabe = string.split(attribute, "/")
				local storedValue : any = nil
				local attributeType : string = nil
				local maxIterations : number = table.maxn(parsedValue)
				local fixedNamingScheme : string = ""

				-- Gets the main.Configurations config from the parsed value
				for i = 1, maxIterations do
					if i == 1 then
						storedValue = self.Information.Configurations[parsedValue[i]]
						fixedNamingScheme = parsedValue[i]
					else
						storedValue = storedValue[parsedValue[i]]
						fixedNamingScheme = fixedNamingScheme .. "_" .. parsedValue[i]
					end
				end

				attributeType = type(storedValue) -- Gets the lua type of the value
				self.ImportantInformation.script:SetAttribute(fixedNamingScheme, storedValue) -- Creates the attribute

				-- Creates a coroutine to listen for if the attribute changes, and then sets the main.Configuration<index> to the value
				local function listenToAttribute() : nil
					if self.Information.Configurations.AllowAdjustableSettings == false then
						return
					end

					storedValue = self.ImportantInformation.script:GetAttribute(fixedNamingScheme)

					-- Adds type checking to make sure that the new value will be the same type as the old value
					if attributeType ~= nil then
						if type(storedValue) ~= attributeType then
							return
						end
					end

					-- Changes the value in main.Configurations<index(es)>. This is a hard-coded code block.
					if maxIterations == 1 then
						self.Information.Configurations[parsedValue[1]] = storedValue
					elseif maxIterations == 2 then
						self.Information.Configurations[parsedValue[1]][parsedValue[2]] = storedValue
					elseif maxIterations == 3 then
						self.Information.Configurations[parsedValue[1]][parsedValue[2]][parsedValue[3]] = storedValue
					elseif maxIterations == 4 then
						self.Information.Configurations[parsedValue[1]][parsedValue[2]][parsedValue[3]][parsedValue[4]] = storedValue
					else
						warn(self.ImportantInformation.script:GetFullName() .. ".SetUpAttributeConfigurations():listenToAttribute() could not change AI.Information.Configuration<indexes> because the nested configuration is too deep. Please add availability to nest: " .. maxIterations .. " deep.")
					end
				end
				self.ImportantInformation.script:GetAttributeChangedSignal(fixedNamingScheme):Connect(listenToAttribute)
			end
		end

		-- Removes the created attributes from the function above
		function class.schema.RemoveAttributeConfigurations(self : BaseCombatAI) : nil
			for _, attribute : string in pairs(self.Information.Configurations.Attributes) do
				local parsedValue : tabe = string.split(attribute, "/")
				local storedValue : any = nil
				local attributeType : string = nil
				local maxIterations : number = table.maxn(parsedValue)
				local fixedNamingScheme : string = ""

				-- Gets the main.Configurations config from the parsed value
				for i = 1, maxIterations do
					if i == 1 then
						storedValue = self.Information.Configurations[parsedValue[i]]
						fixedNamingScheme = parsedValue[i]
					else
						storedValue = storedValue[parsedValue[i]]
						fixedNamingScheme = fixedNamingScheme .. "_" .. parsedValue[i]
					end
				end

				self.ImportantInformation.script:SetAttribute(fixedNamingScheme, nil) -- Removes the created attribute
			end
		end

		--[[
		Adds functionality to change main.Configurations.EnemyTags
		Accepts overloads:
		option : boolean → true: add a value to main.Configurations.EnemyFolders, false: remove a value from main.Configurations.EnemyFolders
		value : string: Adds the string directly to the folder
		]]
		self.ImportantInformation.script.ChangeEnemyTable.Event:Connect(function(option : boolean, value : Folder | table)
			if self.Information.Configurations.AllowAdjustableSettings == false then
				return
			end
			if typeof(value) == "string" then
			else
				warn(self.ImportantInformation.script:GetFullName() .. ".ChangeEnemyTable.Event recieved an unusable 'value' overload. Recieved value: ", value, " (with type: " .. typeof(value) .. ").")
				return
			end

			-- If 'option' is true, add the folder to main.Configurations.EnemyFolders, otherwise try to remove the value. Will throw a warning if the value cannot be found inside the table.
			if option == true then
				table.insert(self.Information.Configurations.EnemyTags, value)
			elseif option == false then
				local index = table.find(self.Information.Configurations.EnemyTags, value) -- Tries to find the index the folder is at

				if index then -- Remove the folder at the index
					table.remove(self.Information.Configurations.EnemyTags, index)
				else -- If the flolder was not found, throw an warning
					warn(self.ImportantInformation.script:GetFullName() .. ".ChangeEnemyTable.Event could not find folder '" .. value .. "' inside AI.Information.Configurations.EnemyFolders.")
				end
			end
		end)

		--[[
		Adds functionality to change main.Configurations.RaycastParams.IgnoreInViewChecking
		Accepts overloads:
		option : boolean → true: add a value to main.Configurations.RaycastParams.IgnoreInViewChecking, false: remove a value from main.Configurations.RaycastParams.IgnoreInViewChecking
		value : string: Adds the string directly to the folder
		]]
		self.ImportantInformation.script.ChangeIgnoreViewTable.Event:Connect(function(option : boolean, value : string)
			if self.Information.Configurations.AllowAdjustableSettings == false then
				return
			end

			if typeof(value) == "string" then
			else
				warn(self.ImportantInformation.script:GetFullName() .. ".ChangeIgnoreViewTable.Event recieved an unusable 'value' overload. Recieved value: ", value, " (with type: " .. typeof(value) .. ").")
				return
			end

			--[[
			If 'option' is true, add the folder to main.Configurations.RaycastParams.IgnoreInViewChecking
			, otherwise try to remove the value. Will throw a warning if the value cannot be found inside the table.
			]]
			if option == true then
				table.insert(self.Information.Configurations.RaycastParams.IgnoreInViewChecking, value)
			elseif option == false then
				local index = table.find(self.Information.Configurations.RaycastParams.IgnoreInViewChecking, value) -- Tries to find the index the folder is at

				if index then -- Remove the folder at the index
					table.remove(self.Information.Configurations.RaycastParams.IgnoreInViewChecking, index)
				else -- If the flolder was not found, throw an warning
					warn(self.ImportantInformation.script:GetFullName() .. ".ChangeIgnoreViewTable.Event could not find folder '" .. value .. "' inside main.Configurations.RaycastParams.IgnoreInViewChecking.")
				end
			end
		end)
	end
end

--[[
	Function used to visualise the shot of a gun if the bullet type is set to "Raycast"
	Accepts overloads:
	distance : number → The distance of the raycast
	startPosition : Vector3 → Where to start the beam from
	endPosition : Vector3 → Where the raycast hit
	]]
function class.schema.VisualiseShootingRaycast(self : BaseCombatAI, distance : number, startPosition : Vector3, endPosition : Vector3) : nil
	-- Tries to find if a folder to store all the paths has already been made. If it hasn't, then it creates the folder
	local foundFolder = self.VisualisationInformation.VisualisationFolder
	if foundFolder then
	else
		-- Creates a new folder with the name "PathVisualiser" and parents it to the workspace
		foundFolder = Instance.new("Folder")
		foundFolder.Name = self.VisualisationInformation.VisualisationFolderName
		foundFolder.Parent = workspace
		self.VisualisationInformation.VisualisationFolder = foundFolder
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
	beam:AddTag("Visualiser")
	beam.Parent = foundFolder

	game:GetService("Debris"):AddItem(beam, self.WeaponInformation.GunStatistics.ShotDelay) -- Destroys the tracer after self.WeaponInformation.GunStatistics.ShotDelay amount of seconds
end

--[[
Function used to update self.Information.EnemyTable via self.Information.Configurations.EnemyFolders if self.Information.Configurations.EnemyTableUpdateDelay seconds has passed since it was lasted updated.
It lops through the folders in pcalls for safety.
Returns true if self.Information.EnemyTable was updated, false if it wasn't.
]]
function class.schema.UpdateEnemyTable(self : BaseCombatAI) : boolean
	if tick() - self.Information.LastUpdatedEnemyTable >= self.Information.Configurations.EnemyTableUpdateDelay then
		self.Information.EnemyTable = {}

		local success1, no1 = pcall(function()
			for _, tag : string in pairs(self.Information.Configurations.EnemyTags) do
				local folder = game:GetService("CollectionService"):GetTagged(tag)
				local success2, no2 = pcall(function()
					for _, enemy : Part | Model in pairs(folder) do
						-- If the enemy's attribute "Invisible" is true, ignore the enemy
						if enemy:GetAttribute("Invisible") == true then
							continue
						end

						table.insert(self.Information.EnemyTable, enemy)
					end
				end)

				if not success2 then
					warn(self.ImportantInformation.script:GetFullName() .. ".UpdateEnemyTable() had an issue updating the table for a specific folder. Error message: " .. no2)
				end
			end
		end)

		if not success1 then
			warn(self.ImportantInformation.script:GetFullName() .. ".UpdateEnemyTable() had an error in a for loop. Error message: " .. no1)
		end

		self.Information.LastUpdatedEnemyTable = tick()

		return true
	end

	return false
end

--[[
Function used to update self.Information.ViewCheckingIgnoredParts and self.Information.ShootingRaycastIgnoredParts
]]
function class.schema.UpdateTables(self : BaseCombatAI) : boolean
	local notFailed = true

	local success, cant = pcall(function()
		table.clear(self.Information.ShootingRaycastIgnoredParts)

		for _, tag in pairs(self.Information.Configurations.WeaponsConfigurations.ShootingRaycastParams.FilterDecendents) do
			table.insert(self.Information.ShootingRaycastIgnoredParts, game:GetService("CollectionService"):GetTagged(tag))
		end
	end)

	if not success then
		if cant then
			notFailed = false
			warn(self.ImportantInformation.script:GetFullName() .. ".UpdateTables() could not update the AI.Information.ShootingRaycastIgnoredParts table. Error: ", cant)
		end
	end

	local success, cant = pcall(function()
		table.clear(self.Information.ViewCheckingIgnoredParts)

		for _, tag in pairs(self.Information.Configurations.RaycastParams.IgnoreInViewChecking) do
			table.insert(self.Information.ViewCheckingIgnoredParts, game:GetService("CollectionService"):GetTagged(tag))
		end
	end)

	if not success then
		if cant then
			notFailed = false
			warn(self.ImportantInformation.script:GetFullName() .. ".UpdateTables() could not update the AI.Information.ViewCheckingIgnoredParts table. Error: ", cant)
		end
	end

	return notFailed
end

--[[
Gets the score of an enemy, used to decide on a target.
Accepts overloads:
information : table → The table in self.WeaponInformation.Target.Total<index>
weaponType : number → 1 = gun, 2 = melee
]]
function class.schema.GetTargetScore(self : BaseCombatAI, information : table, weaponType : number) : number
	local toBeAddedScores = {}
	local score = 0

	-- If the weapon is a gun
	if weaponType == 1 then
		-- List of all the scores
		toBeAddedScores.HealthScore = self.Information.Configurations.WeaponsConfigurations.GunScoreMultipliers.HealthScoreMultiplier -
			(self.Information.Configurations.WeaponsConfigurations.GunScoreMultipliers.HealthScoreMultiplier/information.Health)
		toBeAddedScores.ThreatLevelScore = information.ThreatLevel /self.Information.Configurations.WeaponsConfigurations.GunScoreMultipliers.ThreatLevelScoreMultiplier
		toBeAddedScores.DefenseScore = information.Defense/self.Information.Configurations.WeaponsConfigurations.GunScoreMultipliers.DefenseScoreMultiplier

		-- Checks if the enemy is within targetting distance, and if not sets the distance multiplier to math.huge
		if information.Distance > self.WeaponInformation.GunStatistics.Range then
			toBeAddedScores.DistanceScore = math.huge
		else
			toBeAddedScores.DistanceScore = information.Distance * self.Information.Configurations.WeaponsConfigurations.GunScoreMultipliers.DistanceScoreMultiplier
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
function class.schema.IdentifyTarget(self : BaseCombatAI, weaponType : number) : Part
	--[[ Checks if there's already a target, and if there is then has a chance to return it instead of identifying a new target 
	if it's in self.WeaponInformation.Target.Total and within targetting distance]]
	if self.WeaponInformation.Target.Favoured ~= nil then
		local foundTarget = false
		-- Tries to find the target in self.WeaponInformation.Target.Total
		for i, v in pairs(self.WeaponInformation.Target.Total) do
			if v.Enemy == self.WeaponInformation.Target.Favoured then
				if weaponType == 1 then
					if v.Distance > self.WeaponInformation.GunStatistics.Range then
						print(v.Enemy:GetFullName() .. " is too far: " .. v.Distance)
						break
					end
				end

				foundTarget = true
				break
			end
		end

		-- Randomly chooses if the target will be the favoured target if the target was found
		if foundTarget == true then
			local selected = self.Information.RandomNumberGenerator:NextInteger(1, self.Information.Configurations.WeaponsConfigurations.NewTargetChance)

			if selected < self.Information.Configurations.WeaponsConfigurations.NewTargetChance then
				-- Will select a new target
			else -- Selects the old target
				return self.WeaponInformation.Target.Favoured
			end
		end
	end
	
	local targetScores = {}

	-- Collects all the scores of all the enemies in self.WeaponInformation.Target.Total
	for i, v in pairs(self.WeaponInformation.Target.Total) do
		table.insert(targetScores, {Target = v.Enemy, Score = self.GetTargetScore(self, v, weaponType)})
	end

	-- Randomizes the table, just in case there are enemies that have the same score
	self.Information.RandomNumberGenerator:Shuffle(targetScores)

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
	local randomlySelected = placesTable[self.Information.RandomNumberGenerator:NextInteger(1, totalSlots)].enemy

	-- Sets the favoured target to the selected target
	self.WeaponInformation.Target.Favoured = randomlySelected

	return randomlySelected
end

-- This function is used to reload the weapon and removes bullets from the reserves
function class.schema.Reload(self : BaseCombatAI) : nil
	local bulletsToRemove = math.abs(self.WeaponInformation.GunStatistics.MagazineSize-self.WeaponInformation.GunStatistics.Magazine) --[[ Calculates the total number of bullets to remove from reserves,
																													uses math.abs so that bullets are always removed, never added ]]
	self.WeaponInformation.GunStatistics.Reserve -= bulletsToRemove
	self.WeaponInformation.GunStatistics.Magazine = self.WeaponInformation.GunStatistics.MagazineSize

	if self.WeaponInformation.GunStatistics.Reserve > 0 then
		self.ImportantInformation.script:SetAttribute("Reloading", true)
		task.wait(self.WeaponInformation.GunStatistics.ReloadSpeed)
		self.ImportantInformation.script:SetAttribute("Reloading", false)
	else
		self.Information.OutOfAmmo = true
		self.ImportantInformation.script:SetAttribute("OutOfBullets", true)
	end
end

-- This function is used to remove a bullet from the magazine
function class.schema.DepleteBullet(self : BaseCombatAI) : nil
	self.WeaponInformation.GunStatistics.Magazine -= 1
	self.Information.FiredBindableEvent:Fire()

	if self.WeaponInformation.GunStatistics.Magazine <= 0 then
		self.Reload(self)
	end
end

-- Creates a shot that is fired
function class.schema.FireGun(self : BaseCombatAI) : nil
	-- Checks if the time between shots is >= self.WeaponInformation.GunStatistics.ShotDelay, and if not returns
	if tick()-self.Information.LastShot < self.WeaponInformation.GunStatistics.ShotDelay then
		return
	end
	self.Information.LastShot = tick() -- Updates self.Information.LastShot

	local target = self.IdentifyTarget(self, 1) -- Gets a target

	-- Nil checks the target to make sure there's a target selected
	if target == nil then
		return
	end

	-- Identifies if the gun is a burst gun or not
	local burstWeapon = false
	if self.WeaponInformation.GunStatistics.DelayBetweenBurst ~= nil then
		burstWeapon = true
	end

	-- Saves the headPosition of where the shooting happens
	local startingPosition = self.Information.Configurations.WeaponsConfigurations.ShootFromLocation.Position

	-- Creates a CFrame that looks at the target
	local lookAtCFrame = CFrame.lookAt(startingPosition, target.Position)

	-- Adds in a spread factor to the CFrame.LookAt for where to shoot
	local function CalculateSpread() : CFrame
		local spreadX = self.Information.RandomNumberGenerator:NextNumber(-self.WeaponInformation.GunStatistics.XSpread, self.WeaponInformation.GunStatistics.XSpread)
		local spraedY = self.Information.RandomNumberGenerator:NextNumber(-self.WeaponInformation.GunStatistics.YSpread, self.WeaponInformation.GunStatistics.YSpread)

		-- Factors spread into the lookAtCFrame
		local adjustedCFrame = lookAtCFrame * CFrame.Angles(math.rad(spreadX), math.rad(spraedY), 0)

		-- Gets the adjustedCFrame.LookVector and multiplies it by self.WeaponInformation.GunStatistics.Range to get the full distance of the shot
		local maxDistance = adjustedCFrame

		return maxDistance
	end

	-- Creates a raycast and if it hits anything, will attempt to find the humanoid of the hit object and damage it dealing self.WeaponInformation.GunStatistics.Damage HP
	if self.WeaponInformation.GunStatistics.TypeOfBullet == 1 then
		local hitRaycastParams = RaycastParams.new()
		hitRaycastParams.FilterType = Enum.RaycastFilterType[self.Information.Configurations.WeaponsConfigurations.ShootingRaycastParams.FilterType]
		hitRaycastParams.FilterDescendantsInstances = {self.Information.ShootingRaycastIgnoredParts, self.ImportantInformation.rig, self.VisualisationInformation.VisualisationFolder}
		hitRaycastParams.RespectCanCollide = false

		-- If the gun is a burst, shoot self.WeaponInformation.GunStatistics.ShotsPerBurst times
		for i = 1, (burstWeapon == true) and self.WeaponInformation.GunStatistics.ShotsPerBurst or 1 do
			self.DepleteBullet(self) -- Remove a bullet due to shooting

			-- If the gun is a shotgun, shoot self.WeaponInformation.GunStatistics.AmountOfShots times
			for i = 1, self.WeaponInformation.GunStatistics.AmountOfShots, 1 do
				local rayCast = game.Workspace:Raycast(startingPosition, CalculateSpread().LookVector * self.WeaponInformation.GunStatistics.Range, hitRaycastParams)

				if rayCast then
					local hitPart = rayCast.Instance
					if hitPart then

						-- Visualises the bullet path if self.VisualisationInformation.VisualiseShooting is set to true
						if self.VisualisationInformation.VisualiseShooting == true then
							self.VisualiseShootingRaycast(self, rayCast.Distance, startingPosition, rayCast.Position)
						end

						if hitPart:IsDescendantOf(self.ImportantInformation.rig) then
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
						local damage = self.WeaponInformation.GunStatistics.Damage
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

			-- If the gun is a burst, halt for self.WeaponInformation.GunStatistics.DelayBetweenBurst seconds
			if burstWeapon == true then
				task.wait(self.WeaponInformation.GunStatistics.DelayBetweenBurst)
			end
		end
		-- Part bullets
	elseif self.WeaponInformation.GunStatistics.TypeOfBullet == 2 then
		-- Make sure the game doesn't crash due to total amounts of bullets
		if #self.ImportantInformation.bulletFolder:GetChildren() >= self.Information.Configurations.WeaponsConfigurations.MaxBulletCount then
			return
		end

		local bulletInformation = {}

		-- If the gun is a burst, shoot self.WeaponInformation.GunStatistics.ShotsPerBurst times
		for i = 1, (burstWeapon == true) and self.WeaponInformation.GunStatistics.ShotsPerBurst or 1 do
			self.DepleteBullet(self) -- Remove a bullet due to shooting

			-- If the gun is a shotgun, shoot self.WeaponInformation.GunStatistics.AmountOfShots times
			for i = 1, self.WeaponInformation.GunStatistics.AmountOfShots, 1 do
				bulletInformation = {
					Damage = self.WeaponInformation.GunStatistics.Damage,
					Enemy = self.Information.Configurations.EnemyTags,
					IgnoreTagged = self.Information.Configurations.RaycastParams.IgnoreInViewChecking,
					MoveTowards = CalculateSpread(),
					BulletDrop = self.WeaponInformation.GunStatistics.BulletDrop,
					DistanceTimeOut = self.WeaponInformation.GunStatistics.Range,
					Speed = self.WeaponInformation.GunStatistics.BulletSpeed,
					Pierce = self.WeaponInformation.GunStatistics.PierceAmount,
					PierceDamageLoss = self.WeaponInformation.GunStatistics.PierceFallOffDamage,
				}

				-- Create a clone of the bullet, and give it information
				coroutine.resume(coroutine.create(function()
					local actor = game:GetService("ServerStorage").Bullet:Clone()
					actor.Bullet.Position = self.ImportantInformation.rig.Head.CFrame.Position
					actor.Parent = self.ImportantInformation.bulletFolder
					task.wait()
					actor:SendMessage("Inform", bulletInformation)
				end))
			end
		end
	end

	self.Information.LastShot = tick() -- Updates self.Information.LastShot
end

-- Function used to determine what method of fighting to use
function class.schema.CombatDecider(self : BaseCombatAI) : nil
	-- Melee will be added later, probably
	self.FireGun(self)
end

-- Function used to clone certain variables from CombatInformation.GunStatistics
function class.schema.CloneGunStatistics(self : BaseCombatAI) : nil
	self.WeaponInformation.GunStatistics.Magazine = self.WeaponInformation.GunStatistics.MagazineSize
	self.WeaponInformation.GunStatistics.Reserve = self.WeaponInformation.GunStatistics.ReserveSize
end

function class.schema.RemoveRBXScriptConnections(self : BaseCombatAI) : nil
	for _, signal : RBXScriptConnection in pairs(self.RBXScriptConnections) do
		signal:Disconnect()
	end
end

function class.schema.CleanUp(self : BaseCombatAI) : nil
	self.RemoveRBXScriptConnections(self)

	-- Destroys the visualisation folder
	if self.VisualisationInformation.VisualisationFolder ~= nil then
		self.VisualisationInformation.VisualisationFolder:Destroy()
	end

	self.ImportantInformation.script:SetAttribute("Shutoff", true)
end

-- Creates a new type called "BaseCombatAI"
type BaseCombatAI = typeof(class.interface.New(table.unpack(...)))

return class
