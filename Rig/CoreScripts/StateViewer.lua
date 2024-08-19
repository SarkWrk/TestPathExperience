local rig = script.Parent.Parent
local pathfindScript = script.Parent.PathfindingScript


local highlight = Instance.new("Highlight")

highlight.Parent = rig

local idled = false
local walking = false

while task.wait() do
	walking = pathfindScript:GetAttribute("Moving")
	idled = not pathfindScript:GetAttribute("InCycle")
	
	if walking == true then
		highlight.FillColor = Color3.new(0, 1, 1)
	else
		highlight.FillColor = Color3.new(1, 0, 0)
	end
end
