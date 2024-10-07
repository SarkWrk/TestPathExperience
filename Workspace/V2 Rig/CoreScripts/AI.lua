local moduleScript = require(game:GetService("ServerStorage"):WaitForChild("Components"):WaitForChild("AIComponents"):WaitForChild("AI"))

local setupInformation = {
	owner = script,
	rig = script.Parent.Parent,
	diedEvent = script.Parent.RigDied,
	stateManagerScript = script.Parent.StateManager,
	firedEvent = script.Shot,
	locationToShootFrom = script.Parent.Parent.Head,
	difficulty = 500,
	shootingScript = script,
	pathfindScript = script,
}

setupInformation.weaponInformation = {
	Gun = {
		TypeOfBullet = 2, -- 1 : Raycast, 2 : Part
		Damage = 10, -- In HP
		ShotDelay = 10000000, -- In bullets per minute
		AmountOfShots = 1, -- In bullets
		ShotsPerBurst = 3, -- In amount of bullets per shot
		DelayBetweenBurst = nil, -- Leave nil if not in burst
		Range = 25000, -- In studs
		BulletDrop = 0, -- In studs per second, only used when TypeOfBullet type is NOT 1
		XSpread = 3, -- In degrees, +/-x
		YSpread = 3, -- In degrees, +/-y
		BulletSpeed = 10000, -- In studs per second, only used if TypeOfBullet is NOT 1
		ReloadSpeed = 1, -- In seconds
		MagazineSize = 1500, -- Bullets per magazine
		ReserveSize = math.huge, -- Total bullets that can be shot
		PierceAmount = 0, -- In amount of parts to pierce, how many parts can be pierced by the bullet, only used if TypeOfBullet is NOT 1
		PierceFallOffDamage = 1, -- In %, how much damage to take off when piercing a part
	},
	
	Utility = {
		CanUseGrenade = true, -- bool
		GrenadeUseDelay = 2, -- In seconds
		
		GrenadeStatistics = {
			Damage = 50, -- In HP
			Range = 15, -- In studs
			FallOffDueToDistance = 10, -- %damage to take off per 10 studs
			FallOffDueToObjects = 10, -- %damage to take off
			Timer = 5, -- In seconds
			Instances = {"Goal", "AI"}, -- A table
		}
	},
}

setupInformation.combatInformation = {
	Configurations = {
		AllowAdjustableSettings = true, -- Whether to allow other scripts to change configuration settings in the script via attribute changes
		VisualCheckDelay = 0.1, -- Used to delay times between raycasting, in seconds
		RaycastStart = "Head", -- A string identifier for the part used to check from. Must be a child of the rig
		EnemyTableUpdateDelay = 0.1, -- Used to decide how often to update Base.EnemyTable, in seconds
		ViewDistance = 100, -- How far the rig can see, in studs
		ViewRadius = 30, -- FOV of the rig, in +/-x, therefore: FOV is double what is set
		
		EnemyTags = { --[[
						Table to store enemies that are tagged.
						Can be added and removed from via script.ChangeEnemyTable if Base.Configurations.AllowAdjustableSettings is set to true.
						Information on how to add/remove folders will be in the listener event function.
						]]
			"Goal",
		},
		
		WeaponConfigurations = {
			MeleeAvailable = false, -- Whether the script will allow meleeing
			GunAvailable = true, -- Whether the script will allow shooting
			NewTargetChance = 0, -- Chance to target a new target if the previous target is still visible
			
			GunScoreMultipliers = {
				DistanceScoreMultiplier = 1, -- How much to multiply the distance the target is by x
				HealthScoreMultiplier = 2, -- How much to multiply the health of the target by x
				ThreatLevelScoreMultiplier = 3, -- How much to multiply the threat level of the target by x
				DefenseScoreMultiplier = 10, -- How much to multiply the defense of the target by x
			},
			
			ShootingRaycastParams = {
				FilterType = "Exclude",
				
				FilterDecendents = { -- Table of tags to get filtered in/out by the raycast
					"AI",
					"Bullet",
					"Enemy Utilities",
				}
			}
		},
		
		["RaycastParams"] = {
			FilterType = "Exclude", -- Case specific
			RespectCanCollide = false,
			
			IgnoreInViewChecking = { --[[
									Table used to store tagged parts that the rig should ignore when checking if it can see an enemy.
									Can be added and removed from via script.ChangeIgnoreViewTable if Base.Configurations.AllowAdjustableSettings is set to true.
									Information on how to add/remove parts will be in the listener event function.
									]]
				"AI",
				"Bullet",
				"Enemy Utilities",
			}
		}
	},
}

setupInformation.pathfindingInformation = {
	PathfindingInformation = {

		-- Variables used for the AgentParameters argument when creating a path via PathfindingService:ComputeAsync()
		AgentRadius = 3,
		AgentHeight = 5,
		WaypointSpacing = 0.5,
		JumpHeight = 50, -- Uses Humanoid.JumpPower
		MoveSpeed = 16, -- In studs/sec

		-- Variable used for the chance that the rig will skip pathing the nearest goal
		SkipClosestChance = 50, -- Calculated value is (this)/100 (required to be positive and <= 100)
		RecheckPossibleTargets = 2, -- In seconds, if the rig runs out of targets it will halt pathfinding for this long and then try again
		
		-- Table used for the tags that the rig will pathfind to
		Goals = {
			"Goal",
		},
		
		LabelCosts = { --[[Material names and pathfinding modifier/pathfinding link labels
						can be put here to adjust their respective costs to travel on]]
			Danger = math.huge,
		},
		
		-- Table used for controlling if the rig should recalculate the path due to it being blocked by a ancestor of an object in the table
		BannedFolders = {
			workspace.Obstacles,
		},
		
		FailureInformation = {
			ExhaustTime = 5, -- Time is adjusted by distance in studs, at 1 stud away it's x, 2 it's 2x, 0.5 is 0.5x, etc
			RecalculatePath = true, -- If the programme should calculate a new path on exhaust timeout
			ForcePathfinding = true, -- Whether to force the programme to pathfind to a part
		}
	},

	VisualisationInformation = {
		-- Variables used for the VisualisationInformation:PathVisualiser() function
		VisualisePath = true, -- Whether to enable this visualisation
		VisualisationSpacing = 4, -- How far to space each visualised point (must be >= main.PathfindingInformation.WaypointSpacing)
		NormalNodeSize = 0.5, -- The size of the visualised node (given as a Vector3.new(x,x,x))
		JumpNodeSizeMultiplier = 4, -- The size given of the visualised node with each value being the normal node size multiplied by x
		CustomNodeSizeMultiplier = 8, -- The size given of the visualised node with each value being the normal node size multiplied by x

		-- Variables used for the main.PathfindingInformation:ChosenVisualiser() function
		VisualiseChoosing = false, -- Whether to enable this visualisation
		ShowChoosingCircle = true, -- Whether to show the distance circle, WILL NOT RUN IF VisualiseChoosing IS FALSE
		ChoosingCircleExpansionDelay = 0.00005, -- How long the programme waits between expanding the circle
		HeightAppearenceWaitTime = 1, -- How long the programme waits after reaching the chosen goal
	},
	
	ShootingFunctions = {
		ShouldHaltOnSeenenemy = false, -- Whether the programme should halt when seeing an enemy
		WalkspeedReduction = 5, -- How much to reduce walkspeed by if an enemy can be seen
		GrenadeAvoidanceRange = 15, -- How close a grenade needs to be to the AI for the AI to avoid the grenade
	},
}


local rig = script.Parent.Parent
local diedEvent = script.Parent.RigDied
local stateManager = script.Parent.StateManager
local firedEvent = script.Shot
local shootFromLocation = script.Parent.Parent.Head

local AI = moduleScript.interface.New(setupInformation)

local combatAI = AI.Combat
local pathfindingAI = AI.Pathfinding

local pathfindingCoroutine = coroutine.create(function()
	while task.wait() do
		if pathfindingAI.Information.Died == true then
			break
		end

		if pathfindingAI.ShootingFunctions.ShouldHaltOnSeenEnemy == false then
			if pathfindingAI.ShootingFunctions.ReducedWalkspeed == true then
				pathfindingAI.ShootingFunctions.ReducedWalkspeed = false
				script.Parent.StateManager:SetAttribute("Walkspeed", script.Parent.StateManager:GetAttribute("Walkspeed") + pathfindingAI.ShootingFunctions.WalkspeedReduction)
			end
		end

		pathfindingAI.MoveThroughWaypoints(pathfindingAI)
	end
end)

local shootingCoroutine = coroutine.create(function()
	while task.wait() do
		if combatAI.Information.Died == true or combatAI.Information.OutOfAmmo == true then
			break
		end

		combatAI.CombatDecider(combatAI)

		if combatAI.UpdateTables(combatAI) == false then
			warn("Failed to update at least one table with main:UpdateTables().")
		end

		if combatAI.Information.NulledAdjustableSettings == true and combatAI.Information.Configurations.AllowAdjustableSettings == true then
			combatAI.SetUpAttributeConfigurations(combatAI)
			combatAI.Information.CreatedAdjustableSettings = true
			combatAI.Information.NulledAdjustableSettings = false
		elseif combatAI.Information.CreatedAdjustableSettings == true and combatAI.Information.Configurations.AllowAdjustableSettings == false then
			combatAI.RemoveAttributeConfigurations(combatAI)
			combatAI.Information.CreatedAdjustableSettings = false
			combatAI.Information.NulledAdjustableSettings = true
		end
	end

	script:SetAttribute("CanSeeEnemy", false) -- Sets the script's CanSeeEnemy attribute to false so that the pathfinding script won't be effected
	
	combatAI.CleanUp(combatAI)
end)

coroutine.resume(pathfindingCoroutine)
coroutine.resume(shootingCoroutine)

while task.wait() do
	if combatAI.Information.Died == true or pathfindingAI.Information.Died == true then
		break
	end
end

AI.CleanUp()
