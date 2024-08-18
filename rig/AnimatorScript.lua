-- Gets the rig, pathfinding script, and folder container
local rig = script.Parent.Parent
local coreScriptsFolder = script.Parent
local pathfindingScript = coreScriptsFolder.PathfindingScript



-- Sets up the main table
local main = {}



-- Sets up various general variables
main.Humanoid = rig.Humanoid
main.Animator = main.Humanoid.Animator
main.IsRunning = false -- Tells the programme whether the rig is running or walking
main.IsIdled = false -- Tells the programme whether the rig is idled or not
main.Jumping = false



-- Sets up the animation holder table
main.CreatedAnimations = {}

-- Pre-defines some tables to store animations in
main.CreatedAnimations.WalkAnimation = {}
main.CreatedAnimations.RunAnimation = {}
main.CreatedAnimations.JumpAnimation = {}
main.CreatedAnimations.IdleAnimation = {}
main.CreatedAnimations.ClimbAnimation = {}



-- Sets up the animation setting table
main.AnimationSettings = {}

-- Variables used for animation settings
main.AnimationSettings.IDPrefix = "rbxassetid://"
main.AnimationSettings.RunThreshold = 20 -- Use main.CreatedAnimations.RunAnimation if main.Humanoid.WalkSpeed >= x



-- Sets up the AnimationID table used to create the animations
main.AnimationSettings.AnimationIDs = {}

--[[
Defines the various AnimationIDs used for animations (index is the same index in main.CreatedAnimations),
VALUES MUST BE THE INTEGER OF THE WEB URL.
YOU MUST BE THE OWNER/GIVEN PERMISSION TO USE THE ANIMATION
ID : number = AnimationID
looped : boolean = Whether to loop the track
]]
main.AnimationSettings.AnimationIDs.WalkAnimation = {ID = 13806742705, looped = true}
main.AnimationSettings.AnimationIDs.RunAnimation = {ID = 13264795500, looped = true}
main.AnimationSettings.AnimationIDs.JumpAnimation = {ID = 658832070, looped = false}
main.AnimationSettings.AnimationIDs.IdleAnimation = {ID = 658832408, looped = true}
main.AnimationSettings.AnimationIDs.ClimbAnimation = {ID = 658833139, looped = true}



-- Sets up a table used for holding event listeners
listeners = {}




-- Sets up a table used for listening to rig events
listeners.RigEvents = {}



-- Sets up a table used for listening to PathfindingScript events
listeners.PathfindingScript = {}



-- Litens for PathfindingScript:GetAttributeChangedSignal("InCycle"), and changes the main.IsIdled value to it
function listeners.PathfindingScript:InCycle()
	main.IsIdled = pathfindingScript:GetAttribute("InCycle")
end

-- Litens for PathfindingScript:GetAttributeChangedSignal("Moving"), and changes the main.IsIdled value to it
function listeners.PathfindingScript:Moving()
	main.IsIdled = pathfindingScript:GetAttribute("Moving")
end

--[[
Listens for the main.Humanoid.Jumped event. 
Plays the main.CreatedAnimations.JumpAnimation and sets main.Jumping to true.
When the main.Humanoid.State is "Landed", sets main.jumping to false
]]
function listeners.RigEvents:Jumped()
	main.Jumping = true
	
	-- Sets main.Jumping to false when main.Humanoid has registered as landed
	main.Humanoid.StateChanged:Connect(function(oldStatus, newStatus)
		if newStatus == Enum.HumanoidStateType.Landed then
			main.Jumping = false
		end
	end)
	
	-- Stops the walk and run animations and plays the jump animation
	main:StopAnimation("WalkAnimation")
	main:StopAnimation("RunAnimation")
	main:PlayAnimation("JumpAnimation")
end

--[[
Function used for playing animations. Not loaded animations are skipped. All code is ran inside of a pcall.
Accepts overloads of:
animationIndex : string → The index of the animation in main.CreatedAnimations (cast specific)
logDebugging : boolean? → Whether to print extra debugging information
showErrorInformation : string? {"No", "Normal", "Warning", "Error"} → Whether to log if the pcall errors. "No" doesn't log. "Normal" prints the error. "Warn" warns the eorr. "Error" errors the error.
haltProgramme : boolean? → Whether to wait for the animation to finish playing or not
repeatPlaying : bolean? → Whether to play the animation even if the animation is currently plaing
]]
function main:PlayAnimation(animationIndex : string, logDebugging : boolean? , showErrorInformation : string?, haltProgramme : boolean?, repeatPlaying : boolean?) : nil
	local success, no = pcall(function()
		if logDebugging == true then
			print("Attempting to find the AnimationTrack for: " .. animationIndex .. ".")
		end
		
		local animationTrack : AnimationTrack? = main.CreatedAnimations[animationIndex].Track
		
		local playAnimation = true
		
		-- Checks whether an AnimationTrack was found at the animationIndex provided
		if animationTrack ~= nil then
			-- Checks whether the animation is already playing, and if so whether to play it again based on repeatPlaying
			if animationTrack.IsPlaying == true then
				if logDebugging == true then
					print("Animation is already playing.")
				end
				
				-- If repeatPlaying is false, don't play the animation again
				if repeatPlaying ~= true then
					playAnimation = false
					
					if logDebugging == true then
						print("Animation will not be played again.")
					end
				end
			end
		else
			if logDebugging == true then
				print("No AnimationTrack found!")
			end
			
			playAnimation = false
		end
		
		if playAnimation == true then
			-- Logging
			if logDebugging == true then
				print("Attempting to play the animation.")
			end

			animationTrack:Play() -- Plays the animation

			-- Logs if the animation played successfully
			if logDebugging == true then
				print("Played animation successfully!")
			end

			-- Whether to halt the programme while the animation is playing, and whether to log the fact it's happening
			if haltProgramme == true then
				if logDebugging == true then
					print("Will wait for the animation to end.")
				end

				animationTrack.Ended:Wait()

				if logDebugging == true then
					print("Animation ended.")
				end
			end
		end
	end)
	
	-- Checks if there was an error, and whether to log the error
	if not success then
		if no then
			-- Normal log:
			if string.lower(showErrorInformation) == "normal" then
				print(script:GetFullName() .. " had an error in main:PlayAnimation() | Error: " .. no)
			-- Warn log:
			elseif string.lower(showErrorInformation) == "warn" then
				warn("main:PlayAnimation() had an error! | Error: " .. no)
			-- Error log:
			elseif string.lower(showErrorInformation) == "error" then
				error("main:PlayAnimation() had an error! | Error: " .. no)
			-- No/nil log:
			else
				-- pass
			end
		end
	end
end

--[[
Function used for stopping playing animations. Ran in a pcall for safety.
Accepts overloads of:
animationIndex : string → The index of the animation in main.CreatedAnimations
logDebugging : bolean? → Whether to log debugging information
showErrorInformation : string? {"No", "Normal", "Warning", "Error"} → Whether to log if the pcall errors. "No" doesn't log. "Normal" prints the error. "Warn" warns the eorr. "Error" errors the error.
]]
function main:StopAnimation(animationIndex : string, logDebugging : boolean?, showErrorInformation : string?) : nil
	local success, no = pcall(function()
		if logDebugging == true then
			print("Attempting to stop the animation for: " .. animationIndex .. ".")
		end
		
		local animationTrack : AnimationTrack? = main.CreatedAnimations[animationIndex].Track

		if animationTrack ~= nil then
			if logDebugging == true then
				print("Found AnimaitonTrack.")
			end
			
			animationTrack:Stop()
			
			if logDebugging == true then
				print("Stopped animation.")
			end
		else
			if logDebugging == true then
				print("Could not find AnimationTrack.")
			end
		end
	end)
	
	-- Checks if there was an error, and whether to log the error
	if not success then
		if no then
			-- Normal log:
			if string.lower(showErrorInformation) == "normal" then
				print(script:GetFullName() .. " had an error in main:StopAnimation() | Error: " .. no)
				-- Warn log:
			elseif string.lower(showErrorInformation) == "warn" then
				warn("main:StopAnimation() had an error! | Error: " .. no)
				-- Error log:
			elseif string.lower(showErrorInformation) == "error" then
				error("main:StopAnimation() had an error! | Error: " .. no)
				-- No/nil log:
			else
				-- pass
			end
		end
	end
end

-- Function used for creating Animations and AnimationTracks based on main.AnimationSettings.AnimationIDs. Then puts them in their respective main.CreatedAnimations tables
function main:CreateAnimations() : nil
	for index, container : table in pairs(main.AnimationSettings.AnimationIDs) do
		-- Calls a pcall when loading and creating the animation
		local success, no = pcall(function()
			local animation = Instance.new("Animation")
			animation.AnimationId = main.AnimationSettings.IDPrefix .. container.ID -- The prefix is based on main.AnimationSettings.IDPrefix

			local animationTrack = main.Animator:LoadAnimation(animation)
			
			if container.looped == true then
				animationTrack.Looped = true
			end

			-- Puts the Animation and AnimationTrack into main.CreatedAnimations
			main.CreatedAnimations[index] = {Animation = animation, Track = animationTrack}
		end)
		
		if no and not success then
			warn(no)
		end
	end
end

-- Function used for when to decide when to use the WalkAnimation and RunAnimation animations.
function main:BasicMovementAnimation() : string
	if main.Jumping == true then
		return "None"
	end
	
	-- If main.Humanoid.WalkSpeed is >= to main.AnimationSettings.RunThreshold, then play RunAnimation. Otherwise, play WalkAnimation.
	if main.Humanoid.WalkSpeed >= main.AnimationSettings.RunThreshold then
		main:PlayAnimation("RunAnimation", nil, "Warn")
		return "Run"
	else
		main:PlayAnimation("WalkAnimation", nil, "Warn")
		return "Walk"		
	end
end

-- Connects the GetAttributeChangedSignal event of PathfindingScripts's "InCycle" to listeners.PathfindingScript:InCycle()
pathfindingScript:GetAttributeChangedSignal("InCycle"):Connect(listeners.PathfindingScript.InCycle)

-- Connects the GetAttributeChangedSignal event of PathfindingScripts's "Moving" to listeners.PathfindingScript:Moving()
pathfindingScript:GetAttributeChangedSignal("Moving"):Connect(listeners.PathfindingScript.Moving)

-- Connects the Jumping event of main.Humanoid to listener.RigEvents:Jumped()
main.Humanoid.Jumping:Connect(listeners.RigEvents.Jumped)

-- Sets up the Animations and AnimationTracks by calling main:CreateAnimations()
main:CreateAnimations()

-- Sets the running/walking animations when called.
while task.wait() do
	main:BasicMovementAnimation()
end
