# 3
- PathfindingScript:
  - Can now path to models if the .PrimaryPart property is set.
    - This update is backwards compatible with previous versions, and therefore can still pathfind to individual parts.
  - Parts created in VisualisationInformaiton:ChoosenVisualiser() are now parented to VisualisationInformation.FolderToSavePathVisualiserName as opposed to being parented to workspace.
    - This function now also checks if a folder was created to store visualised parts, and if not creates one.
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
    - Currently ammo and magazine sizes are not factored into shooting and will be later.
  - Melee will be added at an indeterminable date.

  ## Known Issues:
  - The spread factor of shooting is wildly out of proportions.

<hr>

# 2
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

# 1
- PathfindingScript has 3 new attributes:
  - InCycle - If the PathfindingScript is currently going to a goal.
  - Moving - If the PathfindingScript is currently making the rig move.
  - OnMovingPlatform - If the PathfindingScript is currently on a moving platform.
- ShootingScript has 1 attribute:
  - CanSeeEnemy - If the rig can currently see an enemy (currently ShootingScript is empty)
- StateViewer has no impact on the functionality of the core scripts. It is there to help visualise what is happening without looking at the attributes.
- Changed main.PathfindingInformation.BillboardTextLabel to VisualisationInformation.BillboardTextLabel.
