local AIModule = require(game:GetService("ServerStorage"):WaitForChild("Components"):WaitForChild("AIComponents"):WaitForChild("AI"))
local types = require(game:GetService("ServerStorage"):WaitForChild("Types"))

local setupInformation : types.AIConfigurations = {
	weaponInformation = {
		Gun = {},
		Utility = {
			GrenadeStatistics = {},	
		},
	},
	
	combatInformation = {
		Configurations = {
			WeaponConfigurations = {
				ShootingRaycastParams = {},	
			},
			
			["RaycastParams"] = {},
		},	
	},
	
	pathfindingInformation = {
		PathfindingInformation = {
			FailureInformation = {},	
		},
		
		VisualisationInformation = {},
		ShootingFunctions = {},
	},
}

setupInformation.owner = script
setupInformation.rig = script.Parent.Parent
setupInformation.diedEvent = script.Parent.RigDied
setupInformation.stateManagerScript = script.Parent.StateManager
setupInformation.firedEvent = script.Shot
setupInformation.locationToShootFrom = script.Parent.Parent.Head
setupInformation.difficulty = 500
setupInformation.combatScript = script
setupInformation.pathfindingScript = script

setupInformation.weaponInformation.Gun.TypeOfBullet = 2 -- 1 : Raycast, 2 : Part
setupInformation.weaponInformation.Gun.Damage = 10 -- In HP
setupInformation.weaponInformation.Gun.ShotDelay = 10000 -- In bullets per minute
setupInformation.weaponInformation.Gun.AmountOfShots = 1 -- In bullets
setupInformation.weaponInformation.Gun.ShotsPerBurst = 3 -- In amount of bullets per shot
setupInformation.weaponInformation.Gun.DelayBetweenBurst = nil -- Leave nil if not in burst
setupInformation.weaponInformation.Gun.Range = 25000 -- In studs
setupInformation.weaponInformation.Gun.BulletDrop = 1.5 -- In studs per second, only used when TypeOfBullet type is NOT 1
setupInformation.weaponInformation.Gun.XSpread = 3 -- In degrees, +/-x
setupInformation.weaponInformation.Gun.YSpread = 3 -- In degrees, +/-y
setupInformation.weaponInformation.Gun.BulletSpeed = 100 -- In studs per second, only used if TypeOfBullet is NOT 1
setupInformation.weaponInformation.Gun.ReloadSpeed = 1 -- In seconds
setupInformation.weaponInformation.Gun.MagazineSize = 1500 -- Bullets per magazine
setupInformation.weaponInformation.Gun.ReserveSize = math.huge -- Total bullets that can be shot
setupInformation.weaponInformation.Gun.PierceAmount = 0 -- In amount of parts to pierce, how many parts can be pierced by the bullet, only used if TypeOfBullet is NOT 1
setupInformation.weaponInformation.Gun.PierceFallOffDamage = 1 -- In %, how much damage to take off when piercing a part

setupInformation.weaponInformation.Utility.CanUseGrenade = true -- bool
setupInformation.weaponInformation.Utility.GrenadeUseDelay = 2 -- In seconds

setupInformation.weaponInformation.Utility.GrenadeStatistics.Damage = 50 -- In HP
setupInformation.weaponInformation.Utility.GrenadeStatistics.Range = 15 -- In studs
setupInformation.weaponInformation.Utility.GrenadeStatistics.FallOffDueToDistance = 10 -- %damage to take off per 10 studs
setupInformation.weaponInformation.Utility.GrenadeStatistics.FallOffDueToObjects = 10 -- %damage to take off
setupInformation.weaponInformation.Utility.GrenadeStatistics.Timer = 5 -- In seconds
setupInformation.weaponInformation.Utility.GrenadeStatistics.Instances = {"Goal", "AI"} -- A table

setupInformation.combatInformation.Configurations.AllowAdjustableSettings = true -- Whether to allow other scripts to change configuration settings in the script via attribute changes
setupInformation.combatInformation.Configurations.VisualCheckDelay = 0.1 -- Used to delay times between raycasting, in seconds
setupInformation.combatInformation.Configurations.RaycastStart = "Head" -- A string identifier for the part used to check from. Must be a child of the rig
setupInformation.combatInformation.Configurations.EnemyTableUpdateDelay = 0.1 -- Used to decide how often to update Base.EnemyTable, in seconds
setupInformation.combatInformation.Configurations.ViewDistance = 100 -- How far the rig can see, in studs
setupInformation.combatInformation.Configurations.ViewRadius = 30 -- FOV of the rig, in +/-x, therefore: FOV is double what is set

setupInformation.combatInformation.Configurations.EnemyTags = { --[[
						Table to store enemies that are tagged.
						Can be added and removed from via script.ChangeEnemyTable if Base.Configurations.AllowAdjustableSettings is set to true.
						Information on how to add/remove folders will be in the listener event function.
						]]
	"Goal",
}

setupInformation.combatInformation.Configurations.WeaponConfigurations.MeleeAvailable = false -- Whether the script will allow meleeing
setupInformation.combatInformation.Configurations.WeaponConfigurations.GunAvailable = true -- Whether the script will allow shooting
setupInformation.combatInformation.Configurations.WeaponConfigurations.NewTargetChance = 0 -- Chance to target a new target if the previous target is still visible

setupInformation.combatInformation.Configurations.WeaponConfigurations.GunScoreMultipliers = {
	DistanceScoreMultiplier = 1, -- How much to multiply the distance the target is by x
	HealthScoreMultiplier = 2, -- How much to multiply the health of the target by x
	ThreatLevelScoreMultiplier = 3, -- How much to multiply the threat level of the target by x
	DefenseScoreMultiplier = 10, -- How much to multiply the defense of the target by x
}

setupInformation.combatInformation.Configurations.WeaponConfigurations.ShootingRaycastParams.FilterType = "Exclude"

setupInformation.combatInformation.Configurations.WeaponConfigurations.ShootingRaycastParams.FilterDecendents = { -- Table of tags to get filtered in/out by the raycast
	"AI",
	"Bullet",
	"Enemy Utilities",
}

setupInformation.combatInformation.Configurations.RaycastParams.FilterType = "Exclude" -- Case specific
setupInformation.combatInformation.Configurations.RaycastParams.RespectCanCollide = false

setupInformation.combatInformation.Configurations.RaycastParams.IgnoreInViewChecking = { --[[
									Table used to store tagged parts that the rig should ignore when checking if it can see an enemy.
									Can be added and removed from via script.ChangeIgnoreViewTable if Base.Configurations.AllowAdjustableSettings is set to true.
									Information on how to add/remove parts will be in the listener event function.
									]]
	"AI",
	"Bullet",
	"Enemy Utilities",
}

-- Variables used for the AgentParameters argument when creating a path via PathfindingService:ComputeAsync()
setupInformation.pathfindingInformation.PathfindingInformation.AgentRadius = 3
setupInformation.pathfindingInformation.PathfindingInformation.AgentHeight = 5
setupInformation.pathfindingInformation.PathfindingInformation.WaypointSpacing = 0.5
setupInformation.pathfindingInformation.PathfindingInformation.JumpHeight = 50 -- Uses Humanoid.JumpPower
setupInformation.pathfindingInformation.PathfindingInformation.MoveSpeed = 16 -- In studs/sec

-- Variable used for the chance that the rig will skip pathing the nearest goal
setupInformation.pathfindingInformation.PathfindingInformation.SkipClosestChance = 50 -- Calculated value is (this)/100 (required to be positive and <= 100)
setupInformation.pathfindingInformation.PathfindingInformation.RecheckPossibleTargets = 2 -- In seconds, if the rig runs out of targets it will halt pathfinding for this long and then try again

-- Table used for the tags that the rig will pathfind to
setupInformation.pathfindingInformation.PathfindingInformation.Goals = {
	"Goal",
}

setupInformation.pathfindingInformation.PathfindingInformation.LabelCosts = { --[[Material names and pathfinding modifier/pathfinding link labels
						can be put here to adjust their respective costs to travel on]]
	Danger = math.huge,
}

-- Table used for controlling if the rig should recalculate the path due to it being blocked by a ancestor of an object in the table
setupInformation.pathfindingInformation.PathfindingInformation.BannedFolders = {
	workspace.Obstacles,
}

setupInformation.pathfindingInformation.PathfindingInformation.FailureInformation.ExhaustTime = 5 -- Time is adjusted by distance in studs, at 1 stud away it's x, 2 it's 2x, 0.5 is 0.5x, etc
setupInformation.pathfindingInformation.PathfindingInformation.FailureInformation.RecalculatePath = true -- If the programme should calculate a new path on exhaust timeout
setupInformation.pathfindingInformation.PathfindingInformation.FailureInformation.ForcePathfinding = true -- Whether to force the programme to pathfind to a part

-- Variables used for the VisualisationInformation:PathVisualiser() function
setupInformation.pathfindingInformation.VisualisationInformation.VisualisePath = true -- Whether to enable this visualisation
setupInformation.pathfindingInformation.VisualisationInformation.VisualisationSpacing = 4 -- How far to space each visualised point (must be >= main.PathfindingInformation.WaypointSpacing)
setupInformation.pathfindingInformation.VisualisationInformation.NormalNodeSize = 0.5 -- The size of the visualised node (given as a Vector3.new(x,x,x))
setupInformation.pathfindingInformation.VisualisationInformation.JumpNodeSizeMultiplier = 4 -- The size given of the visualised node with each value being the normal node size multiplied by x
setupInformation.pathfindingInformation.VisualisationInformation.CustomNodeSizeMultiplier = 8 -- The size given of the visualised node with each value being the normal node size multiplied by x

-- Variables used for the main.PathfindingInformation:ChosenVisualiser() function
setupInformation.pathfindingInformation.VisualisationInformation.VisualiseChoosing = false -- Whether to enable this visualisation
setupInformation.pathfindingInformation.VisualisationInformation.ShowChoosingCircle = true -- Whether to show the distance circle, WILL NOT RUN IF VisualiseChoosing IS FALSE
setupInformation.pathfindingInformation.VisualisationInformation.ChoosingCircleExpansionDelay = 0.00005 -- How long the programme waits between expanding the circle
setupInformation.pathfindingInformation.VisualisationInformation.HeightAppearenceWaitTime = 1 -- How long the programme waits after reaching the chosen goal


setupInformation.pathfindingInformation.ShootingFunctions.ShouldHaltOnSeenenemy = false -- Whether the programme should halt when seeing an enemy
setupInformation.pathfindingInformation.ShootingFunctions.WalkspeedReduction = 5 -- How much to reduce walkspeed by if an enemy can be seen
setupInformation.pathfindingInformation.ShootingFunctions.GrenadeAvoidanceRange = 15 -- How close a grenade needs to be to the AI for the AI to avoid the grenade

local rig = script.Parent.Parent
local diedEvent = script.Parent.RigDied
local stateManager = script.Parent.StateManager
local firedEvent = script.Shot
local shootFromLocation = script.Parent.Parent.Head

local AI = AIModule.interface.New(setupInformation)

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
