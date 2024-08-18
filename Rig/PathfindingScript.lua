-- Gets the rig, pathfinding script, and folder container
local rig = script.Parent.Parent
local coreScriptsFolder = script.Parent
local pathfindingScript = coreScriptsFolder.PathfindingScript

-- Sets up the main table
local main = {}

-- Sets up various general variables
main.Humanoid = rig.Humanoid
main.Animator = main.Humanoid.Animator

-- Sets up the animation holder table
main.CreatedAnimations = {}

-- Pre-defines some variables to store animations in
main.CreatedAnimations.WalkAnimation = nil
main.CreatedAnimations.RunAnimation = nil
main.CreatedAnimations.JumpAnimation = nil
main.CreatedAnimations.IdleAnimation = nil
main.CreatedAnimations.ClimbAnimation = nil

-- Sets up the animation setting table
main.AnimationSettings = {}

-- Variables used for animation settings
main.AnimationSettings.IDPrefix = "rbxassetid://"

-- Sets up the AnimationID table used to create the animations
main.AnimationSettings.AnimationIDs = {}

-- Defines the various AnimationIDs used for animations (index is the same index in main.CreatedAnimations), VALUES MUST BE THE INTEGER OF THE WEB URL
main.AnimationSettings.AnimationIDs.WalkAnimation = 658831143
main.AnimationSettings.AnimationIDs.RunAnimation = 658830056
main.AnimationSettings.AnimationIDs.JumpAnimation = 658832070
main.AnimationSettings.AnimationIDs.IdleAnimation = 658832408
main.AnimationSettings.AnimationIDs.ClimbAnimation = 658833139

