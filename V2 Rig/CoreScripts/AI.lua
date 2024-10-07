local moduleScript = require(game:GetService("ServerStorage"):WaitForChild("Components"):WaitForChild("AIComponents"):WaitForChild("AI"))

local weaponInformation = {}

weaponInformation.Gun = {
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
}

weaponInformation.Utility = {
	CanUseGrenade = true, -- bool
	GrenadeUseDelay = 2, -- In seconds
}

weaponInformation.Utility.GrenadeStatistics = {
	Damage = 50, -- In HP
	Range = 15, -- In studs
	FallOffDueToDistance = 10, -- %damage to take off per 10 studs
	FallOffDueToObjects = 10, -- %damage to take off
	Timer = 5, -- In seconds
	Instances = {"Goal", "AI"}, -- A table
}


local rig = script.Parent.Parent
local diedEvent = script.Parent.RigDied
local stateManager = script.Parent.StateManager
local firedEvent = script.Shot
local shootFromLocation = script.Parent.Parent.Head

local setUpInformation = {
	["owner"] = script,
	["rig"] = script.Parent.Parent,
	["diedEvent"] = script.Parent.RigDied,
	["stateManagerScript"] = script.Parent.StateManager,
	["firedEvent"] = script.Shot,
	["locationToShootFrom"] = script.Parent.Parent.Head,
	["difficulty"] = 500, -- 500 = normal
	["shootingScript"] = script,
	["pathfindingScript"] = script,
	["weaponInformation"] = weaponInformation
}

local AI = moduleScript.interface.New(setUpInformation)

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

while task.wait() do
	if combatAI.Shutoff == true and pathfindingAI.Shutoff == true then
		break
	end
end

script:SetAttribute("Shutoff", true)
