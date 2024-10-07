export type weaponInformationConfigurations = {
	Gun : {
		TypeOfBullet : number,
		Damage : number,
		ShotDelay : number,
		AmountOfShots : number,
		ShotsPerBurst : number?,
		DelayBetweenBurst : number?,
		Range : number,
		BulletDrop : number,
		XSpread : number,
		YSpread : number,
		BulletSpeed : number,
		ReloadSpeed : number,
		MagazineSize : number,
		ReserveSize : number,
		PierceAmount : number,
		PierceFallOffDamage : number
	},

	Utility : {
		CanUseGrenade : boolean,
		GrenadeUseDelay : number,

		GrenadeStatistics : {
			Damage : number,
			Range : number,
			FallOffDueToDistance : number,
			FallOffDueToObjects : number,
			Timer : number,
			Instances : {string}
		}?
	},
}

export type CombatAIConfigurations = {
	Configurations : {
		AllowAdjustableSettings : boolean,
		VisualCheckDelay : number,
		RaycastStart : string,
		EnemyTableUpdateDelay : number,
		ViewDistance : number,
		ViewRadius : number,
		EnemyTags : {string},

		WeaponConfigurations : {
			MeleeAvailable : boolean,
			GunAvailable : boolean,
			NewTargetChance : number,

			GunScoreMultipliers : {
				DistanceScoreMultiplier : number,
				HealthScoreMultiplier : number,
				ThreatLevelScoreMultiplier : number,
				DefenseScoreMultiplier : number
			},

			ShootingRaycastParams : {
				FilterType : string,
				FilterDecendents : {string}
			},
		},

		["RaycastParams"] : {
			FilterType : string,
			RespectCanCollide : boolean,
			IgnoreInViewChecking : {string}
		},

		Attributes : {string},
	},
}

export type PathfindingAIConfigurations = {
	PathfindingInformation : {
		AgentRadius : number,
		AgentHeight : number,
		WaypointSpacing : number,
		LabelCosts : {[string] : number},
		JumpHeight : number,
		MoveSpeed : number,
		BannedFolders : {Instance},
		SkipClosestChance : number,
		RecheckPossibleTargets : number,

		Goals : {string},

		FailureInformation : {
			ExhaustTime : number,
			RecalculatePath : boolean,
			ForcePathfinding : boolean
		}
	},

	VisualisationInformation : {
		VisualisePath : boolean,
		VisualisationSpacing : number,
		NormalNodeSize : number,
		JumpNodeSizeMultiplier : number,
		CustomNodeSizeMultiplier : number,
		VisualiseChoosing : boolean,
		ShowChoosingCircle : boolean,
		ChoosingCircleExpansionDelay : number,
		HeightAppearenceWaitTime : number
	}?,

	ShootingFunctions : {
		ShouldHaltOnSeenenemy : boolean,
		WalkspeedReduction : number,
		GrenadeAvoidanceRange : number
	},
}

export type AIConfigurations = {
	owner : Script,
	rig : Model,
	diedEvent : BindableEvent,
	locationToShootFrom : string,
	firedEvent : BindableEvent,
	difficulty : number,
	combatScript : Script,
	stateManagerScript : Script,
	pathfindingScript : Script,
	
	weaponInformation : weaponInformationConfigurations,
	
	combatInformation : CombatAIConfigurations,
	
	pathfindingInformation : PathfindingAIConfigurations,
}

return nil
