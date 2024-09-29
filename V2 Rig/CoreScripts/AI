local moduleScript = require(game:GetService("ServerStorage"):WaitForChild("AIComponents"):WaitForChild("AI"))

local weaponInformation = {}

weaponInformation.Gun = {
	TypeOfBullet = 2, -- 1 : Raycast, 2 : Part
	Damage = 10, -- In HP
	ShotDelay = 0.06, -- In seconds
	AmountOfShots = 1, -- In bullets
	ShotsPerBurst = 3, -- In amount of bullets per shot
	DelayBetweenBurst = nil, -- Leave nil if not in burst
	Range = 25000, -- In studs
	BulletDrop = 0.5, -- In studs per second, only used when TypeOfBullet type is NOT 1
	XSpread = 3, -- In degrees, +/-x
	YSpread = 3, -- In degrees, +/-y
	BulletSpeed = 1000, -- In studs per second, only used if TypeOfBullet is NOT 1
	ReloadSpeed = 1, -- In seconds
	MagazineSize = 150, -- Bullets per magazine
	ReserveSize = 10000, -- Total bullets that can be shot
	PierceAmount = 0, -- In amount of parts to pierce, how many parts can be pierced by the bullet, only used if TypeOfBullet is NOT 1
	PierceFallOffDamage = 1, -- In %, how much damage to take off when piercing a part
}

local rig = script.Parent.Parent
local diedEvent = script.Parent.RigDied
local stateManager = script.Parent.StateManager
local firedEvent = script.Shot
local shootFromLocation = script.Parent.Parent.Head

local AI = moduleScript.interface.New(script, rig, diedEvent, script, script, stateManager, firedEvent, shootFromLocation, weaponInformation)

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
end)

coroutine.resume(pathfindingCoroutine)
coroutine.resume(shootingCoroutine)

while task.wait() do
	if combatAI.Information.Died == true or pathfindingAI.Information.Died == true then
		break
	end
end

AI.CleanUp()
