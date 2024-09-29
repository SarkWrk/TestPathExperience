local rig = script.Parent.Parent -- The parent of the script
local shootingScript = script.Parent.ShootingScript -- The script used for shooting
local stateManagerScript = script.Parent.StateManager -- The script used for managing states



-- The general container containing the functions for core functions and values
local main = {}



-- General variables
main.PreviousPoints = {} -- Tracks unreachable goals
main.Goals = {} -- Tracks all the potential goals
main.InCycle = false -- Tracks if the rig is currently moving towards a goal
main.Moving = false -- Tracks wehther the rig is currently moving
main.Goal = nil -- Publicises the current goal trying to be reached
main.Humanoid = rig.Humanoid -- The Humanoid located inside the model
main.TrueGoal = nil -- Publicses the true goal, and not the pathing to part
main.Died = false



-- Used to generate random numbers
main.RandomNumberGenerator = Random.new()



-- Table to store all variables used for pathfinding
main.PathfindingInformation = {}

-- Table used for the tags that the rig will pathfind to
main.PathfindingInformation.Goals = {
	"Goal"
}

-- Variables used for the AgentParameters argument when creating a path via PathfindingService:ComputeAsync()
main.PathfindingInformation.AgentRadius = 3
main.PathfindingInformation.AgentHeight = 5
main.PathfindingInformation.WaypointSpacing = 0.5
main.PathfindingInformation.LabelCosts = {Danger = math.huge} --[[Material names and pathfinding modifier/pathfinding link labels
																  can be put here to adjust their respective costs to travel on]]

-- Variables used for controlling the rig's movement
main.PathfindingInformation.JumpHeight = 50 -- Uses Humanoid.JumpPower
main.PathfindingInformation.MoveSpeed = 16 -- In studs/sec

-- Table used for controlling if the rig should recalculate the path due to it being blocked by a ancestor of an object in the table
main.PathfindingInformation.BannedFolders = {workspace.Obstacles}

-- Variable used for the chance that the rig will skip pathing the nearest goal
main.PathfindingInformation.SkipClosestChance = 50 -- Calculated value is (this)/100 (required to be positive and <= 100)

main.PathfindingInformation.ForcedPart = nil -- A variable to store a part to force the programme to pathfind to
main.PathfindingInformation.RecheckPossibleTargets = 2 -- In seconds, if the rig runs out of targets it will halt pathfinding for this long and then try again



-- Table used to store variables for if the rig fails to reach the next checkpoint
main.PathfindingInformation.FailureInformation = {}

-- Variables used for what to do if the rig never reaches the next Waypoint
main.PathfindingInformation.FailureInformation.ExhaustTime = 5 -- Time is adjusted by distance in studs, at 1 stud away it's x, 2 it's 2x, 0.5 is 0.5x, etc
main.PathfindingInformation.FailureInformation.RecalculatePath = true -- If the programme should calculate a new path on exhaust timeout
main.PathfindingInformation.FailureInformation.ForcePathfinding = true -- Whether to force the programme to pathfind to a part



-- Table to contain all the functions used for PathfindingLinks
main.CustomActionHelpers = {}



-- A table to contain extra variables and functions related to visualising the main programme
VisualisationInformation = {}

-- Variable used to help show what goal the rig is currently pathing to
VisualisationInformation.BillboardTextLabel = rig.BillboardGui.TextLabel or nil -- Attemps to find a BillboardGUI parented to rig to display info on

-- Variables used for the VisualisationInformation:PathVisualiser() function
VisualisationInformation.VisualisePath = true -- Whether to enable this visualisation
VisualisationInformation.VisualisationSpacing = 4 -- How far to space each visualised point (must be >= main.PathfindingInformation.WaypointSpacing)
VisualisationInformation.FolderToSavePathVisualiserName = "Visualiser" .. main.RandomNumberGenerator:NextNumber(1, 1000) -- Creates a name for the visualisation folder
VisualisationInformation.PathVisualiserFolder = nil -- Stores the folder when created
VisualisationInformation.NormalNodeSize = 0.5 -- The size of the visualised node (given as a Vector3.new(x,x,x))
VisualisationInformation.JumpNodeSizeMultiplier = 4 -- The size given of the visualised node with each value being the normal node size multiplied by x
VisualisationInformation.CustomNodeSizeMultipler = 8 -- The size given of the visualised node with each value being the normal node size multiplied by x

-- Variables used for the main.PathfindingInformation:ChosenVisualiser() function
VisualisationInformation.VisualiseChoosing = false -- Whether to enable this visualisation
VisualisationInformation.ShowChoosingCircle = true -- Whether to show the distance circle
VisualisationInformation.ChoosingCircleExpansionDelay = 0.0005 -- How long the programme waits between expanding the circle
VisualisationInformation.HighlightAppearenceWaitTime = 1 -- How long the programme waits after reaching the chosen goal



-- Sets up a table to store shootingScript functionality
ShootingFunctions = {}



-- Sets up some variables used for the functions in the table
ShootingFunctions.CanSeeEnemy = false -- Used in ShootingFunctions:Halt()
ShootingFunctions.ShouldHaltOnSeenEnemy = false -- Whether the programme should halt when seeing an enemy
ShootingFunctions.WalkspeedReduction = 5 -- How much to reduce walkspeed by if an enemy can be seen
ShootingFunctions.ReducedWalkspeed = false -- A check to see whether the walkspeed has been reduced due to seeing an enemy



-- Function used to visualise the path the rig takes to get to a goal
function VisualisationInformation:PathVisualiser(waypoints : table) : nil -- Returns nothing, requires the waypoints that are going to be plotted (as a table)
	-- Tries to find if a folder to store all the paths has already been made. If it hasn't, then it creates the folder
	local foundFolder = VisualisationInformation.PathVisualiserFolder
	if foundFolder then
		foundFolder:ClearAllChildren() -- Clears all previous nodes in the folder
	else
		-- Creates a new folder with the name "PathVisualiser" and parents it to the workspace
		foundFolder = Instance.new("Folder")
		foundFolder.Name = VisualisationInformation.FolderToSavePathVisualiserName
		foundFolder.Parent = workspace
		VisualisationInformation.PathVisualiserFolder = foundFolder
	end
	
	-- Checks if the visualisation node spacing is less than the agent waypoint spacing, and if so sets the visualisation node spacing to the agent's
	if VisualisationInformation.VisualisationSpacing < main.PathfindingInformation.WaypointSpacing then
		print("Setting VisualisationInformation.VisualisationSpacing to " .. main.PathfindingInformation.WaypointSpacing 
			.. " (Previously: " .. VisualisationInformation.VisualisationSpacing ..")")
		VisualisationInformation.VisualisationSpacing = main.PathfindingInformation.WaypointSpacing
	end
	
	local spacer = VisualisationInformation.VisualisationSpacing/main.PathfindingInformation.WaypointSpacing --[[ Calculates
	how often to create a visualised node]]
	local counter = 0 -- Keeps track of when to place a node
	
	-- Loops through each waypoint and creates a node based off the spacer value
	for i, v : PathWaypoint in pairs(waypoints) do
		-- Creates the node part, determines its colour based off the action, and determines if the node should be shown (otherwise it's skipped)
		local waypoint = Instance.new("Part")
		counter += 1 -- Increments the counter
		
		-- Jump actions are never skipped, have VisualisationInformation.JumpNodeSizeMultiplier the size of a normal node, and are given a GREEN colour
		if v.Action == Enum.PathWaypointAction.Jump then
			counter = 0 -- Resets the counter
			waypoint.Color = Color3.new(0.333333, 1, 0) -- Sets the colour
			waypoint.Size = Vector3.new(VisualisationInformation.NormalNodeSize*VisualisationInformation.JumpNodeSizeMultiplier,
				VisualisationInformation.NormalNodeSize*VisualisationInformation.JumpNodeSizeMultiplier,
				VisualisationInformation.NormalNodeSize*VisualisationInformation.JumpNodeSizeMultiplier)
			
		-- Custom actions are never skipped, have VisualisationInformation.CustomNodeSizeMultipler the size of a normal node, and are given a PINK-ISH-WHITE colour
		elseif v.Action == Enum.PathWaypointAction.Custom then
			counter = 0 -- Resets the counter
			waypoint.Color = Color3.new(1, 0.666667, 1) -- Sets the colour
			waypoint.Size = Vector3.new(VisualisationInformation.NormalNodeSize*VisualisationInformation.CustomNodeSizeMultipler, 
				VisualisationInformation.NormalNodeSize*VisualisationInformation.CustomNodeSizeMultipler,
				VisualisationInformation.NormalNodeSize*VisualisationInformation.CustomNodeSizeMultipler)
			
		-- Walk actions can be skipped, and are given an ORANGE colour
		else
			if counter % spacer ~= 0 then -- Checks whether to skip the node
				continue
			end
			
			waypoint.Color = Color3.new(1, 0.666667, 0) -- Sets the colour
			waypoint.Size = Vector3.new(0.5, 0.5, 0.5) -- Sets the size of the node to be 0.5 studes X 0.5 studs X 0.5 studs
		end
		
		-- General management for making the node more distinct
		waypoint.Name = "Point"..i -- Gives the node its node value (1, 2, 3 ... n where each value a waypoint (i.e. waypoint 1, waypoint 2, waypoint 3 ... waypoint n))
		waypoint.Shape = "Ball" -- Sets the shape of the node to be a sphere
		waypoint.Material = Enum.Material.Neon -- Sets the material of the node to glow
		waypoint.Position = v.Position -- Sets the position of the node to the waypoint position
		waypoint.CanCollide = false -- Sets the ability to collide with the node to false
		waypoint.Anchored = true -- Sets the anchored property of the node to true
		waypoint.Locked = true -- Sets the locked property of the node to true
		waypoint:AddTag("Visualiser")
		waypoint.Parent = foundFolder -- Parents the node to the folder
	end
end

-- Function used to visualise the choosing process of the programme
function VisualisationInformation:ChoosenVisualiser(chosenPart : Part) : void
	-- Tries to find if a folder to store all the paths has already been made. If it hasn't, then it creates the folder
	local foundFolder = VisualisationInformation.PathVisualiserFolder
	if foundFolder then
		foundFolder:ClearAllChildren() -- Clears all previous nodes in the folder
	else
		-- Creates a new folder with the name "PathVisualiser" and parents it to the workspace
		foundFolder = Instance.new("Folder")
		foundFolder.Name = VisualisationInformation.FolderToSavePathVisualiserName
		foundFolder.Parent = workspace
		VisualisationInformation.PathVisualiserFolder = foundFolder
	end
	
	local highlights = {} -- Table used to store the highlights generated by the programme
	
	--[[
	If VisualisationInformation.ShowChoosingCircle is true (skip if not):
	1) Create a circle that expands outwards
	2) Whenever a goal enters the circle, give it a highlight
	2.a) If the goal is the chosen goal, give it a green highlight
	2.b) If the goal is the previous goal, give it a cyan highlight
	2.c) Otherwise, give it a red highlight
	3) Once the goal has been reached, the circle changes colour
	4) Destroy the circle after 0.1s
	]]
	
	if VisualisationInformation.ShowChoosingCircle == true then
		-- Creates the first values of the circle
		local circle = Instance.new("Part") -- Creates a new part
		circle.Shape = Enum.PartType.Cylinder -- Makes it a cylinder shape
		circle.Size = Vector3.new(0.5, 10, 10) -- Sets the size to 0.5 studs X 10 studs X 10 studs (to make it a circle)
		circle.CFrame = CFrame.new(rig.UpperTorso.Position) * CFrame.Angles(0, 0, math.rad(90)) -- Positions and orients the circle
		circle.Material = "Neon" -- Sets the material to Neon to make it more visible
		circle.Color = Color3.new(1, 1, 0.498039) -- Changes the colour to a light yellow
		circle.Anchored = true -- Sets the anchored property to true
		circle.CanCollide = false -- Sets the CanCollide property to false
		circle.Locked = true -- Makes the circle unable to be selected in studio
		circle.Transparency = 0.5 -- Makes the circle half transparent
		circle:AddTag("Visualiser")
		circle.Parent = foundFolder -- Parents the circle to the workspace

		-- Variables used in the following while loop, read more:
		local incrementer = 0 -- Used to facilitate the expansion of the circle
		local reachedChosenPart = false -- Used to indicate if the circle has reached the chosen goal, and if so to stop expanding the circle

		-- Loops forever until the chosen goal has been reached, higlighting passed goals on the way
		while task.wait(VisualisationInformation.ChoosingCircleExpansionDelay) do
			incrementer += 2 -- Increases the radius of the circle by 2
			circle.Size = Vector3.new(0.5, 10 + incrementer, 10 + incrementer) -- Increases the size by the incrementer
			
			-- Loops through each goal to check whether it's in the circle, and if so then highlights it
			for i, v : Model | Part in pairs(workspace.Goals:GetChildren()) do
				local insidePart = nil
				
				-- Gets the part that should be focused on for the stuffs
				if v.ClassName == "Model" then
					insidePart = v.PrimaryPart
				elseif v.ClassName == "Part" then
					insidePart = v
				end
				
				local distance = (Vector3.new(rig.LowerTorso.Position.X, rig.LeftFoot.Position.Y, 
					rig.LowerTorso.Position.Z) - insidePart.Position).Magnitude -- Calculates the how far the goal is from the circle centre
				
				if distance <= circle.Size.Y/2 then -- Checks if the goal is inside the circle's covered area
					if highlights[v.Name] == nil then -- Checks if the goal has already been highlighted before
						-- Highlights the goal based on if the goal is the chosen goal
						local highlight = Instance.new("Highlight") -- Creates the highlight
						highlight.Parent = v -- Sets the parent of the highlight to the goal

						if v == main.TrueGoal then -- Checks whether the highlight is the goal
							highlight.FillColor = Color3.new(0, 1, 0) -- If so, sets the highlight colour to green
							reachedChosenPart = true -- Sets the reachedChosenPart flag to true
							circle.Color = Color3.new(0.333333, 0.333333, 1) -- Changes the circle's colour to purple
						elseif v == main.PreviousPoints[1] then -- Checks whether the highlight is the previous goal
							highlight.FillColor = Color3.new(0.333333, 1, 1) -- If so, sets the highlight colour to green
						end

						highlights[v.Name] = highlight -- Adds the highlight to the highlight table
					end
				end
			end

			-- If the chosen goal has been reached, exit the while loop
			if reachedChosenPart == true then
				break
			end
		end
		
		task.wait(0.1) -- Halts the programme for 0.1s
		
		circle:Destroy() -- Destroys the circle
	else
		-- If VisualisationInformation.ShowChoosingCircle is false, creates a highlight and colours it based on if the goal is the chosen goal
		
		-- Loops through each goal and creates a highlight for each one
		for i, v : Part in pairs(workspace.Goals:GetChildren()) do
			local highlight = Instance.new("Highlight") -- Creates a highlight
			highlight.Parent = v -- Parents it to the goal

			if v == main.TrueGoal then -- Checks if it's the chosen goal
				highlight.FillColor = Color3.new(0, 1, 0) -- If it is sets its colour to green
			elseif v == main.PreviousPoints[1] then -- Checks whether the highlight is the previous goal
				highlight.FillColor = Color3.new(0.333333, 1, 1) -- If so, sets the highlight colour to green
			end

			highlights[v.Name] = highlight -- Adds the highlight to the highlight table
		end		
	end
	
	-- Creates a cylinder that shows the obvious connection between the rig and chosen part, ignoring any obstacles
	
	local distance = (rig.UpperTorso.Position - chosenPart.Position).Magnitude -- Calculates the distance the goal is from the rig
	
	local connector = Instance.new("Part") -- Creates a new part
	connector.Shape = Enum.PartType.Cylinder -- Sets its shape to be a cylinder
	connector.Size = Vector3.new(distance, 2, 2) -- Sets its size to he distance studs X 2 studs X 2 studs (long with a radius of 1)
	connector.Material = "Neon" -- Sets its material to Neon to be more visible
	connector.Color = Color3.new(0, 0.333333, 0) -- Sets its colour to be a dark green
	local storedPosition = Vector3.new((chosenPart.Position.X + rig.UpperTorso.Position.X)/2, (chosenPart.Position.Y + rig.UpperTorso.Position.Y)/2,
		(chosenPart.Position.Z + rig.UpperTorso.Position.Z)/2) --[[
	^^ Calulcates the midpoint between the rig and goal using a 3D midpoint formula]]
	connector.CFrame = CFrame.lookAt(storedPosition, rig.UpperTorso.Position) * CFrame.Angles(0, math.rad(90), 0) --[[ Creates a CFrame with the midpoint, and an adjusting angle to align
	it correctly]]
	connector.CanCollide = false -- Sets the CanCollide property to false
	connector.Anchored = true -- Sets the Anchored property to true
	connector.Locked = true -- Sets the part to be unselectable
	connector.Transparency = 0.5 -- Sets the part's transparency to half
	connector:AddTag("Visualiser")
	connector.Parent = foundFolder -- Parents it to the workspace
	
	task.wait(VisualisationInformation.HighlightAppearenceWaitTime) -- Halts the programme for an amount of time
	
	-- Destroys the highlights and cylinder
	for i, v in pairs(highlights) do
		v:Destroy()
	end
	connector:Destroy()
end

-- Sets up a listener to set the ShootingFunctions.CanSeeEnemy variable
shootingScript:GetAttributeChangedSignal("CanSeeEnemy"):Connect(function()
	ShootingFunctions.CanSeeEnemy = shootingScript:GetAttribute("CanSeeEnemy")
end)

-- Sets up a listener for RigDied, and if it fires safely shuts down the programme
script.Parent.RigDied.Event:Connect(function()
	main.Died = true
end)


-- Function used to halt the programme due to the shootingScript
function ShootingFunctions:Halt() : nil
	if ShootingFunctions.CanSeeEnemy == true then
		if ShootingFunctions.ShouldHaltOnSeenEnemy == false then
			if ShootingFunctions.ReducedWalkspeed == false then
				ShootingFunctions.ReducedWalkspeed = true
				stateManagerScript:SetAttribute("Walkspeed", stateManagerScript:GetAttribute("Walkspeed") - ShootingFunctions.WalkspeedReduction)
			end
		else
			while ShootingFunctions.CanSeeEnemy == true do
				if main.Died == true then
					break
				end

				task.wait()
			end
		end
	end
end

-- Function used by the programme to calculate and return a chosen goal
function main:ChoosePoint() : Part
	table.clear(main.Goals) -- Resets main.Goals
	
	-- Puts all the goals into main.Goals
	for _, tag : string in pairs(main.PathfindingInformation.Goals) do
		local list = game:GetService("CollectionService"):GetTagged(tag)
		for _, goal : Model | Part in pairs(list) do
			local humanoid : Humanoid? = goal:FindFirstChildOfClass("Humanoid")

			-- Checks if the goal has a humanoid, and if its health is <= 0, doesn't add it to the goal list
			if humanoid then
				if humanoid.Health <= 0 then
					continue
				end
			end

			table.insert(main.Goals, goal)
		end
	end
	
	local goals = table.clone(main.Goals) -- Creates a clone of main.Goals
	
	main.RandomNumberGenerator:Shuffle(goals) -- Shuffles the goals table, for randomness
	
	-- Loops through main.PreviousPoints to remove the previous goal and any unreachable goals from the goals table
	for i, v in pairs(main.PreviousPoints) do
		table.remove(goals, table.find(goals, v))
	end
	
	-- Throws an error if there are no more goals after the previous operation
	if table.maxn(goals) == 0 then
		warn(script:GetFullName() .. " ran out of pathfinding options.")
		task.wait(main.PathfindingInformation.RecheckPossibleTargets)
		table.clear(main.PreviousPoints)
		return nil
	end
	
	--[[
		1) Loops through each goal
		2) Calculates the how far each goal is from the rig
		3) Checks if the distance is closer than the closest distance
		3.a) If there is no chosen goal, sets the goal to the goal associated with the distance
		3.b.a.i) If there is already a chosen goal, and the distance is farther than the closest goal, skip the rest of 3.b
		3.b.a.ii) If the chosen goal is farther than the current goal, sets the chosen goal to the current goal
		3.b.b.i) If there is already a chosen goal, and the distance is closer than the current goal, rolls a random number to see if the number is <= main.PathfindingInformation.SkipClosestchance
		3.b.b.ii) If the number is larger than the value, skip the rest of 3.b
		3.b.b.iii) If the number is <=, then set the closest goal to be the current goal
	]]
	
	local chosenGoal = nil -- Initialises the chosenGoal variable
	local closestDistance = math.huge -- Sets the closest goal to be math.huge (int.max) distance away
	local actualGoal = nil
	
	if main.PathfindingInformation.ForcedPart == nil then
		-- Loops through the goals table and follows the rules in the summary above
		for i, v : Model | Part in pairs(goals) do
			local goalPart = nil
			
			-- Makes sure that every Instance in goals is a part or model, and then derives the goalPart from there
			if v.ClassName == "Part" then
				goalPart = v
			elseif v.ClassName == "Model" then
				goalPart = v.PrimaryPart
			else
				return nil
			end
			
			local distance = (rig.Head.Position - goalPart.Position).Magnitude -- Calculates the distance
			if chosenGoal == nil then -- Checks whether there's a chosen goal
				closestDistance = distance -- If not, sets the closest distance to the distance
				chosenGoal = goalPart -- Sets the chosen goal to be the goal
				actualGoal = v
			else
				if distance < closestDistance then -- Checks whether the distance is closer than the closest distance
					closestDistance = distance -- Sets the closest distance to the distance
					chosenGoal = goalPart -- Sets the chosen goal to the goal
					actualGoal = v
				else
					if main.PathfindingInformation.SkipClosestChance == 0 then -- Checks if it's possible to have a closest distance farther than the closest goal
						-- If not, then skips the rest of the codeblock
					else
						local randomNumber = main.RandomNumberGenerator:NextNumber(1, 100) -- Rolls a random number between 1 and 100
						if randomNumber <= main.PathfindingInformation.SkipClosestChance then -- Checks whether the random number is <= the skip chance
							closestDistance = distance -- If it is, set the closest distance to the distance
							chosenGoal = goalPart -- Set the chosen goal to the current goal
							actualGoal = v
						end
					end
				end
			end
		end
		
		main.TrueGoal = actualGoal -- Sets main.TrueGoal to the actualGoal
		table.insert(main.PreviousPoints, main.TrueGoal) -- Inserts the main.TrueGoal into the main.PreviousPoints table
	else
		chosenGoal = main.PathfindingInformation.ForcedPart
		main.PathfindingInformation.ForcedPart = nil
	end
	
	-- If VisualisationInformation.VisualiseChoosing is true, visualises the choosing process
	if VisualisationInformation.VisualiseChoosing == true then
		VisualisationInformation:ChoosenVisualiser(chosenGoal)
	end
	
	-- Sets the main.Goal to be the chosen goal
	main.Goal = chosenGoal
	
	-- Returns the chosen goal
	return chosenGoal
end

--[[
Function used by the programme to create a path and try to calculate the waypoints to get to the goal
If the goal is reachable, returns to the waypoints in a table format
If the goal is unreachable, returns an empty table
]]
function main:GetPathfindingWaypoints() : table
	local goal = main:ChoosePoint() -- Gets the goal by calling on the main:ChoosePoint() function
	
	-- Null checking, so that the rig doesn't try to path to nil
	if goal == nil then
		return {}
	end
	
	local pathfindingService = game:GetService("PathfindingService") -- Gets the PathfindingService
	local path : Path = pathfindingService:CreatePath({AgentHeight = main.PathfindingInformation.AgentHeight, AgentRadius = main.PathfindingInformation.AgentRadius
		, WaypointSpacing = main.PathfindingInformation.WaypointSpacing, Costs = main.PathfindingInformation.LabelCosts}) --[[
		^^ Creates the path using the main.PathfindingInformation variables]]
	
	-- Calculates the path in a protected call
	local success, no = pcall(function()
		path:ComputeAsync(Vector3.new(rig.LowerTorso.Position.X, rig.LeftFoot.Position.Y, rig.LowerTorso.Position.Z), goal.Position)
	end)
	
	-- If the protected calculation fails, warns the error and returns an empty table
	if success == false then
		warn("Path could not be computed. Error: " .. no)
		return {}
	end
	
	-- If the path is created successfully, sets main.PreviousPoints to a table with only the goal in it and returns the waypoints in a table
	if path.Status == Enum.PathStatus.Success then
		main.PreviousPoints = {goal}
		
		return path:GetWaypoints()
	else
		-- If the path isn't sucessfully created, warns relevant information, halts the programme for 0.5s, and returns an empty table
		warn("Path status : " .. path.Status.Name .. " | Goal: " .. goal:GetFullName() .. " | Warning : ", no)
		task.wait(0.5)
		return {}
	end
end

-- Function used to check if a waypoint is still accessible. returns false if it's not and true if it is
function main:CheckWaypointValidity(position : Vector3) : boolean
	-- Creates an OverlapParams that only includes objects inside main.PathfindingInformation.BannedFolers, respecting CanCollide
	local dontAllowList = OverlapParams.new()
	dontAllowList.FilterType = Enum.RaycastFilterType.Include
	dontAllowList.FilterDescendantsInstances = main.PathfindingInformation.BannedFolders
	dontAllowList.RespectCanCollide = true
	
	-- Creates a part the size of the rig
	local makeshiftPart = Instance.new("Part")
	makeshiftPart.Size = Vector3.new(2, 5, 4)
	makeshiftPart.CFrame = rig.UpperTorso.CFrame
	makeshiftPart.Position = position
	
	-- Casts using game.Workspace:GetPartsInPart() to see if any banned objects are inside the part
	local cast = game.Workspace:GetPartsInPart(makeshiftPart, dontAllowList)
	
	-- Returns true if there are any, and therefore the path is blocked
	if table.maxn(cast) > 0 then
		return false
	end
	
	-- Returns false if there aren't any, and therefore not blocked
	return true
end

-- Function used for the Teleporter label for Enum.WaypointAction.Custom. Returns true if teleported and false if not teleported
function main.CustomActionHelpers:Telporter(position : Vector3) : boolean -- Requires the passing of the waypoint position
	-- Creates a new small part at the position of the waypoint
	local makeshiftPart = Instance.new("Part")
	makeshiftPart.Size = Vector3.new(0.1, 0.1, 0.1)
	makeshiftPart.Position = position
	
	-- Creates an OverlapParams that includes the workspaceSkips.Parts.Teleporters folder, ignoring CanCollide
	local allowList = OverlapParams.new()
	allowList.FilterType = Enum.RaycastFilterType.Include
	allowList.FilterDescendantsInstances = {workspace.Skips.Parts.Teleporters}

	local cast = game.Workspace:GetPartsInPart(makeshiftPart, allowList) -- Casts using game.Workspace:GetPartsInPart() for parts inside the waypoint position

	if cast then -- Checks if a table is returned by the previous operation
		if table.maxn(cast) > 0 then -- Makes sure there are part(s) inside the table
			local teleporterEvent : BindableFunction = cast[1]:FindFirstChild("TP") -- Tries to find the BindableFunction nammed "TP" inside the first element of the table

			-- If found, invokes it with the rig and halts until a response is recieved. If the response is (int) 200 reponse, returns true. Otherwise, returns false
			if teleporterEvent then
				local response = false

				response = teleporterEvent:Invoke(rig) -- Invokes the BindableFunction
				
				while response == false do -- Waits for the response
					if main.Died == true then
						break
					end
					
					task.wait()
				end

				if response == 200 then -- Checks if the response is 200
					return true -- Returns true
				else
					print(response) -- If not, prints the response
				end
			else
				print("Teleporter function not found.")
			end
		else
			print("Cast table is empty.")
		end
	else
		print("No casted instance.")
	end
	
	return false
end

--[[
Function used for the Moving Platform label for Enum.WaypointAction.Custom.
Waits on the platform until the platform has stopped moving.
Returns true if the rig waited and false otherwise
]]
function main.CustomActionHelpers:MovingPlatform(position) : boolean -- Requires the passing of the waypoint position
	-- Creates a small part at the position of the waypoint
	local makeshiftPart = Instance.new("Part")
	makeshiftPart.Size = Vector3.new(0.1, 0.1, 0.1)
	makeshiftPart.Position = position

	-- Creates an OVerlapParams that includes the workspace.Skips.Parts.MovingPlatforms folder, ignoring CanCollide
	local allowList = OverlapParams.new()
	allowList.FilterType = Enum.RaycastFilterType.Include
	allowList.FilterDescendantsInstances = {workspace.Skips.Parts.MovingPlatforms}

	local cast = game.Workspace:GetPartsInPart(makeshiftPart, allowList) -- Casts using game.Workspace:GetPartsInPart() for parts inside the waypoint position

	if cast then -- Checks if a table is returned by the previous operation
		if table.maxn(cast) > 0 then -- Checks if the table has elements in it
			-- If there are elements in it, tries to find the "Active" used to wait while the platform is active, and the "Touch" BindableEvent to start the platform
			local moverPlatformActive : BoolValue = cast[1].Parent.Parent:FindFirstChild("Mover"):FindFirstChild("Active")
			local moverStartEvent : BindableEvent = cast[1].Parent.Parent:FindFirstChild("Attached"):FindFirstChild("Start"):FindFirstChild("Touch")

			-- If both are found, the Touch BindableEvent is fired with the rig as an argument, and then the rig waits while the platform moves
			if moverPlatformActive and moverStartEvent then
				moverStartEvent:Fire() -- Fires the BindableEvent
				
				while moverPlatformActive.Value == false do -- Waits until the platform activates
					if main.Died == true then
						return false
					end
					
					task.wait()
				end
				
				script:SetAttribute("OnMovingPlatform", true) -- Publicses that the rig is on a moving platform
				
				while moverPlatformActive.Value == true do -- Waits until the platform deactivates
					if main.Died == true then
						return false
					end
					
					main.Humanoid:MoveTo(moverStartEvent.Parent.Position)
					task.wait()
				end
				
				script:SetAttribute("OnMovingPlatform", false) -- Publicses that the rig is not on a moving platform
				
				return true -- Returns true when the platform deactivates
			else -- If the "Active" BoolValue and/or "Touch" BindableEvent aren't found, warns useful information for debugging 
				warn("Found active boolean? ", moverPlatformActive, " Found event? ", moverStartEvent, " Instance: ", cast[1]:GetFullName(), " Parent's parent: ", cast[1].Parent.Parent.Name)
			end
		else
			print("Cast table is empty.")
		end
	else
		print("No casted instance.")
	end
	return false
end

-- Function used to move the rig to a waypoint, how it does it changes depending on the Waypoint.Action
-- Returns true if the waypoint is reached, returns false if the waypoint is not reached
function main:MoveToWaypoint(waypoint : PathWaypoint) : boolean
	local realPosition = waypoint.Position -- Initialises a variable with the position of the variable
	local adjustedPosition = realPosition + Vector3.new(0, rig.UpperTorso.Position.Y, 0) -- Initialises a variable where the height of the Waypoint.Position.Y is increased by rig.Size.Y/2
	
	-- Checks whether the waypoint is still able to reached, and if not returns false
	if main:CheckWaypointValidity(adjustedPosition) ~= true then
		return false
	end
	
	main.Moving = true -- Sets main.Moving to true to publicise that the rig is moving
	script:SetAttribute("Moving", true) -- Publicses main.Moving to everything
	
	local continueAfterCustomAction = false -- Used for whether to teleport to the next waypoint after a custom action (due to the action failing to execute)
	local customAction = false -- Used to indicate whether a custom action was actioned
	
	-- Checks whether the Waypoint.Action.Name is "Custom", and then executes functions based on the Waypoint.Label
	if waypoint.Action.Name == "Custom" then
		customAction = true
		print("Custom action: " .. waypoint.Label) -- Logging
		
		-- If the label is "Teleporter", executes main.CustomActionHelpers:Teleporter
		if waypoint.Label == "Teleporter" then
			local teleported = main.CustomActionHelpers:Telporter(realPosition)
			if teleported == false then
				continueAfterCustomAction = true
			end
		-- If the label is "Moving Platform", executes main.CustomActionHelpers:MovingPlatform()
		elseif waypoint.Label == "Moving Platform" then
			local moved = main.CustomActionHelpers:MovingPlatform(realPosition)
			if moved == false then
				continueAfterCustomAction = true
			end
		end
	end
	
	-- If the Waypoint.Action.Name isn't "Custom", then moves the rig to the next waypoint, jumping if needed
	if (continueAfterCustomAction == true and customAction == true) or customAction == false then
		-- Causes the rig to jump
		if waypoint.Action.Name == "Jump" then
			main.Humanoid.Jump = true -- Causes the Humanoid to jump
		end
		
		main.Humanoid:MoveTo(adjustedPosition) -- Moves the rig to the Waypoint.Position
		
		local reachedWaypoint = false -- Initialises a variable to track if the Waypoint has been reached
		local startTime = tick() -- Tracks the start time of when Humanoid:MoveTo() is called for main.PathfindingInformation.FailureInformation.ExhaustTime
		local exhaustTime = main.PathfindingInformation.FailureInformation.ExhaustTime / (rig.UpperTorso.Position - adjustedPosition).Magnitude --[[
		^^Sets the amount of time before exhausting the loop]]
		local exhausted = false -- Tracks if the loop exhausts
		
		main.Humanoid.MoveToFinished:Connect(function() -- Flags reachedWaypoint to true when the Humanoid.MoveToFinished is fired
			reachedWaypoint = true
		end)
		
		-- Waits until rig reaches the Waypoint.Position, or until the loop exhausts based on exhaustTime
		while task.wait() do
			if main.Died == true then
				break
			end
			
			if reachedWaypoint == true then
				break
			elseif tick()-startTime >= exhaustTime then -- checks whether the loop has exhausted
				exhausted = true -- Flags exhausted as true
				print("Exhausted")
				break
			end
		end
		
		-- Tells the programme whether to recalculate the path based on main.PathfindingInformation.FailureInformation.RecalculatePath
		if exhausted == true then
			if main.PathfindingInformation.FailureInformation.RecalculatePath == true then
				main.Moving = false
				script:SetAttribute("Moving", false)
				
				-- Tells the programme whether to force the calculated path to be the goal based on main.PathfindingInformation.FailureInformation.ForcePathfinding
				if main.PathfindingInformation.FailureInformation.ForcePathfinding == true then
					print("Forced the next goal to: " .. main.Goal:GetFullName())
					main.PathfindingInformation.ForcedPart = main.Goal
				end
				
				return false
			end
		end
	end

	main.Moving = false -- Indicates that the rig is no longer moving
	script:SetAttribute("Moving", false) -- Publicses main.Moving to everything
	
	return true -- Returns true to indicate the rig successfully moved
end

-- Function used to loop through each waypoint
function main:MoveThroughWaypoints() : nil
	if main.InCycle == true then -- Makes sure that the script will only run once at a time
		return
	end
	
	main.InCycle = true -- Indicates that the script is already running
	script:SetAttribute("InCycle", true) -- Publicses main.InCycle to everything
	
	local waypoints : table = main:GetPathfindingWaypoints() -- Gets the waypoints to reach a goal
	
	-- If VisualisationInformation.VisualisePath is true, calls upon VisualisationInformation:PathVisualise() to visualise the path nodes
	if VisualisationInformation.VisualisePath == true then
		VisualisationInformation:PathVisualiser(waypoints)
	end
	
	if VisualisationInformation.BillboardTextLabel ~= nil then -- Nil check on VisualisationInformation.BillboardTextLabel
		VisualisationInformation.BillboardTextLabel.Text = "Target: " .. main.TrueGoal.Name -- Changes the VisualisationInformation.BillboardTextLabel text to the current goal 
	end
	
	-- Listener and variables to track if the target has died or not, and if so to find a new target
	local goalHumanoid : Humanoid? = main.TrueGoal:FindFirstChildOfClass("Humanoid")
	local targetDied = false
	
	if goalHumanoid then
		goalHumanoid.Died:Connect(function()
			targetDied = true
		end)
	end
	
	-- Loops through each waypoint, moving to each waypoint and doing a specific action for each, breaks out if the path is blocked
	for i, v in pairs(waypoints) do
		if main.Died == true or targetDied == true then -- If the rig or target dies, break out of the loop
			break
		end
		
		ShootingFunctions:Halt() -- Halts the programme if the rig is able to see an enemy
		
		while main.Moving == true do -- Halts the programme until the rig has stopped moving
			if main.Died == true then -- If the rig dies, break out of the loop
				break
			end
			
			task.wait()
		end
		
		if main:MoveToWaypoint(v) ~= true then -- If main:MoveToWaypoint() returns false, the path is blocked and the loop is broken out of
			print("Blocked!")
			break
		end
	end
	
	main.InCycle = false -- Indicates the script has finished
	script:SetAttribute("InCycle", false) -- Publicses main.InCycle to everything
end

-- Sets the Humanoid's movespeed and jump height
main.Humanoid.WalkSpeed = main.PathfindingInformation.MoveSpeed
main.Humanoid.JumpPower = main.PathfindingInformation.JumpHeight

while task.wait() do
	if main.Died == true then
		break
	end
	
	if ShootingFunctions.ShouldHaltOnSeenEnemy == false then
		if ShootingFunctions.ReducedWalkspeed == true then
			ShootingFunctions.ReducedWalkspeed = false
			stateManagerScript:SetAttribute("Walkspeed", stateManagerScript:GetAttribute("Walkspeed") + ShootingFunctions.WalkspeedReduction)
		end
	end
	
	main:MoveThroughWaypoints()
end

-- Destroys the path visualisation folder
if VisualisationInformation.PathVisualiserFolder ~= nil then
	VisualisationInformation.PathVisualiserFolder:Destroy()
end

script:SetAttribute("Shutoff", true)
