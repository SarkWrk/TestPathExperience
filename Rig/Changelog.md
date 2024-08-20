# 2
- StateViwer has new functionality, and changes to 1 part of it's code:
  - It will now show if the rig can see an enemy.
  - It will now differentiate between running and walking.
- ShootingScript now has code:
  - main:UpdateEnemyTable() will update the enemy table
  - main.RunService.Heartbeat will check if the rig can see the enemy
    - Includes a radius FOV and distance check via main.Configurations.ViewRadius and main.Configurations.ViewDistance respectively
- New function main:SetUpAttributeConfigurations() which adds writable attributes to ShootingScript
  - Added subfunction :listenToAttribute() which listens for the writable attributes and adjusts the main.Configurations<index> accordingly

# 1
- PathfindingScript has 3 new attributes:
  - InCycle - If the PathfindingScript is currently going to a goal.
  - Moving - If the PathfindingScript is currently making the rig move.
  - OnMovingPlatform - If the PathfindingScript is currently on a moving platform.
- ShootingScript has 1 attribute:
  - CanSeeEnemy - If the rig can currently see an enemy (currently ShootingScript is empty)
- StateViewer has no impact on the functionality of the core scripts. It is there to help visualise what is happening without looking at the attributes.
- Changed main.PathfindingInformation.BillboardTextLabel to VisualisationInformation.BillboardTextLabel.
