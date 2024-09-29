# 1.0.0 (beta)
- **Major Changes**:
  - AI:
    - When creating an AI the parameters will be put in a table. (Still the same parameters names.)
- AI:
  - New parameter "difficulty".
- CombatAI:
  - Changed `self.WeaponInformation.GunStatistics.ShotDelay` from seconds to shots/min.
  - Added difficulty scaling located under: `self.Information.Difficulty`.
    - Difficulty is clamped as (-inf, 200].
    - Spread scales with difficulty via the equation: spread/100 * (100 + (100 - difficulty)).
  - If `self.WeaponInformation.Target.Favoured` is nil, `self.Information.ViewAlignment` will be disabled. (Aka, the rig will not be staring at the last target.)
  - If the script doesn't see an enemy, then `self.WeaponInformation.Target.Favoured` is set to nil.
- PathfindingAI:
  - Fixed a bug where `self.ImportantInformation.stateManagerScript<Walkspeed>` would not get reset when the rig could no longer see an enemy.
# 0.0.0 (beta)
- Initial launch!
