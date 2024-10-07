local class = {}
class.interface = {}
class.schema = {}
class.metatable = {__index = class.schema}

function class.interface.New(info : {
	owner : Script, rig : Model, diedEvent : BindableEvent, locationToShootFrom : string, firedEvent : BindableEvent, difficulty : number, shootingScript : Script, stateManagerScript : Script,
	weaponInformation : {
		Gun : {
			TypeOfBullet : number, Damage : number, ShotDelay : number, AmountOfShots : number, ShotsPerBurst : number?, DelayBetweenBurst : number?, Range : number, BulletDrop : number, XSpread : number, YSpread : number, BulletSpeed : number, ReloadSpeed : number, MagazineSize : number, ReserveSize : number, PierceAmount : number, PierceFallOffDamage : number},
		Utility : {
			CanUseGrenade : boolean, GrenadeUseDelay : number,
			GrenadeStatistics : {
				Damage : number, Range : number, FallOffDueToDistance : number, FallOffDueToObjects : number, Timer : number, Instances : {}}?},},
	combatInformation : {
		Configurations : {
			AllowAdjustableSettings : boolean, VisualCheckDelay : number, RaycastStart : string, EnemyTableUpdateDelay : number, ViewDistance : number, ViewRadius : number, EnemyTags : {},
			WeaponConfigurations : {
				MeleeAvailable : boolean, GunAvailable : boolean, NewTargetChance : number,
				GunScoreMultipliers : {
					DistanceScoreMultiplier : number, HealthScoreMultiplier : number, ThreatLevelScoreMultiplier : number, DefenseScoreMultiplier : number},
				ShootingRaycastParams : {
					FilterType : string, FilterDecendents : {}},},
			["RaycastParams"] : {
				FilterType : string, RespectCanCollide : boolean, IgnoreInViewChecking : {}},
			Attributes : {},},},
	pathfindingInformation : {
		PathfindingInformation : {
			Goals : {}, AgentRadius : number, AgentHeight : number, WaypointSpacing : number, LabelCosts : {}, JumpHeight : number, MoveSpeed : number, BannedFolders : {Instances}, SkipClosestChance : number, RecheckPossibleTargets : number, Failureinformation : {
				ExhaustTime : number, RecalculatePath : boolean, ForcePathfinding : boolean}},
		VisualisationInformation : {
			VisualisePath : boolean, VisualisationSpacing : number, NormalNodeSize : number, JumpNodeSizeMultiplier : number, CustomNodeSizeMultiplier : number, VisualiseChoosing : boolean, ShowChoosingCircle : boolean, ChoosingCircleExpansionDelay : number, HeightAppearenceWaitTime : number}?,
		ShootingFunctions : {
			ShouldHaltOnSeenenemy : boolean, WalkspeedReduction : number, GrenadeAvoidanceRange : number},
	},})
	local self = setmetatable({}, class.metatable)
	self.Combat = require(script.Parent:WaitForChild("CombatAI")).interface.New(info.owner, info.rig, info.combatInformation, info.diedEvent, info.locationToShootFrom, info.weaponInformation, info.firedEvent, info.difficulty)
	self.Pathfinding = require(script.Parent:WaitForChild("PathfindingAI")).interface.New(info.owner, info.rig, info.pathfindingInformation, info.shootingScript, info.diedEvent, info.stateManagerScript)
	
	coroutine.resume(coroutine.create(function()
		self.Shutoff(self, info.owner)
	end))
	
	return self
end

function class.schema.Shutoff(self : BaseAI, owner : Script)
	while self.Combat.Shutoff == false and self.Pathfinding.Shutoff == false do
		task.wait()
	end
	
	owner:SetAttribute("Shutoff", true)
end

function class.schema.CleanUp(self : BaseAI)
	local _, _ = pcall(function()
		self.Combat:CleanUp()
	end)
	local _, _ = pcall(function()
		self.Pathfinding:CleanUp()
	end)
end

export type BaseAI = typeof(class.interface.New(table.unpack(...)))


return class
