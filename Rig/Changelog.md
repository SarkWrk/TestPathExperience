# 0.5.0 (beta)
- ShootingScript:
  - Additions:
    - New "Shot" BindableEvent.
      - This event gets fired whenever a bullet gets removed from the magazine. (Subject to change.)
  - Changes:
    - Enemies without Humanoids are no longer considered "enemies", and therefore will no longer be targeted.

# 0.4.0 (Beta)
- General:
  - Instead of an increasing number, this changelog now follows Semantic Versioning. (Previous changes have also changed to follow Semantic Versioning.)
- PathfindingScript:
  - Added health checking to the code that adds potential goals to the goal list so that only alive goals and goals without health will be picked from.
  - Instead of erroring when running out of pathfinding goals, the script will now halt for `main.PathfindingInformation.RecheckPossibleTargets` amount of seconds, and then tries to pathfind to any goal again.
  - Now warns the full name of the goal it's trying to reach when unable to reach a goal.
- ShootingScript:
  - Visualisations:
    - After further review, it seems that the spread factor is not wildly out of proportions. ([#6](https://github.com/SarkWrk/TestPathExperience/issues/6#issue-2479747071) has been closed.)
    - In accordance with the above, fixed `main:FireGun()` passing `hitPart.Position` instead of `rayCast.Position`  to `VisualisationInformation:VisualiseShootingRaycast()`.
  - New Functionality:
    - Added functionality that removes bullets from magazines and reserves. ([#7](https://github.com/SarkWrk/TestPathExperience/issues/7#issue-2479749234))
    - Added functionality for shotguns (or more generally, being able to shoot multiple pellets in one shot). ([#7](https://github.com/SarkWrk/TestPathExperience/issues/7#issue-2479749234))
      - Due to this, `VisualisationInformation:VisualiseShootingRaycast()` has been changed to allow multiple shots to be visualised at once. Visualisations are destroyed after `CombatInformation.GunStatistics.ShotDelay` amount of seconds.
    - Added functionality for burst-type guns. ([#7](https://github.com/SarkWrk/TestPathExperience/issues/7#issue-2479749234))
    - The script will safely deactivate when running out of bullets.
    - Added attributes:
      - OutOfBullets - Publicises if the script is out of bullets.
      - Reloading - Publicises if the script is reloading.
  - Changes:
    - If `main.Configurations.AllowAdjustableSettings` is set to true and is a changeable value in `main.Configurations.Attributes`, when `main.Configurations.AllowAdjustableSettings` is set to false, all created adjustable attributes will be nilled out.
    - Fixed an oversight where `hitRaycastParams` wasn't added into the overloads for raycasting when `CombatInformation.GunStatistics.TypeOfBullet` is set to Raycast.

<hr>

# 0.3.0 (Beta)
- All scripts now include code that will safely turn off all their functions and delete any created parts that are within their control.
- PathfindingScript:
  - Can now path to models if the .PrimaryPart property is set.
    - This update is backwards compatible with previous versions, and therefore can still pathfind to individual parts.
  - Parts created in VisualisationInformaiton:ChoosenVisualiser() are now parented to VisualisationInformation.FolderToSavePathVisualiserName as opposed to being parented to workspace.
    - This function now also checks if a folder was created to store visualised parts, and if not creates one.
  - The created folder for visualisations is stored within a variable (still parented to the workspace), and now is only created if the variable storing the folder is nil.
- New script: StateManager:
  - Currently contains code for telling other scripts to shutdown when the rig has died.
- ShootingScript:
  - View checking:
    - Now has a saved RBXScriptSignal that can be disconnected (used for when the rig dies currently).
    - Fixed a bad piece code that would return, therefore skiping parts of the code, instead of continuing when the enemy is outside of the rig's view radius.
    - The code now stores information about enemies used later for when selecting a target.
    - Now includes a health check (with a nil check) to make sure the enemy is alive before storing the information.
      - If no Humanoid is found, the enemy is considered "alive". (May change in the future)
  - Shooting:
    - The programme now has functions for shooting using a raycast (actual bullets will be available as an option later).
    - On the side, a function for giving enemies a score based on certain factors (see the information stored during view checking) and a function for picking an enemy from those scores have been included.
      - The scoring system is fully customisable via main.Configurations.WeaponConfigurations<\[WeaponType]ScoreMultipliers>\<StoredInformationType>
    - Currently ammo, magazine sizes, pellets, and burst rounds are not factored into shooting and will be later.
    - The raycast has an aditional visualisation function that can be turned on. The created visualisation only lasts for as long as CombatInformation.GunStatistics.ShotDelay seconds.
  - Melee will be added at an indeterminable date.

  ## Known Issues:
  - The spread factor of shooting is wildly out of proportions.

<hr>

# 0.2.0 (Beta)
- StateViwer has new functionality, and changes to 1 part of it's code:
  - It will now show if the rig can see an enemy.
  - It will now differentiate between running and walking.
- ShootingScript now has code:
  - main:UpdateEnemyTable() will update the enemy table
  - main.RunService.Heartbeat will check if the rig can see the enemy
    - Includes a radius FOV and distance check via main.Configurations.ViewRadius and main.Configurations.ViewDistance respectively ([#2](https://github.com/SarkWrk/TestPathExperience/issues/2)) (Notice that it may not work perfectly currently.)
  - New function main:SetUpAttributeConfigurations() which adds writable attributes to ShootingScript ([#3](https://github.com/SarkWrk/TestPathExperience/issues/3))
    - Added subfunction :listenToAttribute() which listens for the writable attributes and adjusts the main.Configurations<index> accordingly
  - New script.ChangeEnemyTable event ([#3](https://github.com/SarkWrk/TestPathExperience/issues/3))
    - Adds a function that allows the changing of values inside main.Configurations.EnemyFolders
  - New script.ChangeIgnoreViewTable event ([#3](https://github.com/SarkWrk/TestPathExperience/issues/3))
    - Adds a function that allows the changing of values inside main.Configurations.RaycastParams.IgnoreInViewChecking

<hr>

# 0.1.0 (Beta)
- PathfindingScript has 3 new attributes:
  - InCycle - If the PathfindingScript is currently going to a goal.
  - Moving - If the PathfindingScript is currently making the rig move.
  - OnMovingPlatform - If the PathfindingScript is currently on a moving platform.
- ShootingScript has 1 attribute:
  - CanSeeEnemy - If the rig can currently see an enemy (currently ShootingScript is empty)
- StateViewer has no impact on the functionality of the core scripts. It is there to help visualise what is happening without looking at the attributes.
- Changed main.PathfindingInformation.BillboardTextLabel to VisualisationInformation.BillboardTextLabel.
