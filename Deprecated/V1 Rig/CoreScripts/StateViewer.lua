local rig = script.Parent.Parent
local pathfindScript = script.Parent.PathfindingScript
local shootingScript = script.Parent.ShootingScript
local animatorScript = script.Parent.AnimatorScript
local died = false

local highlight = Instance.new("Highlight")

highlight.Parent = rig

local idled = false
local walking = false
local canSeeEnemy = false

script.Parent.RigDied.Event:Connect(function()
	died = true
end)

while task.wait() do
	if died == true then
		break
	end
	
	walking = pathfindScript:GetAttribute("Moving")
	idled = not pathfindScript:GetAttribute("InCycle")
	canSeeEnemy = shootingScript:GetAttribute("CanSeeEnemy")
	
	if walking == true then
		if animatorScript:GetAttribute("WalkAnimation") == true then
			highlight.FillColor = Color3.new(0, 1, 1)
		else
			highlight.FillColor = Color3.new(0.666667, 1, 1)
		end
	else
		highlight.FillColor = Color3.new(1, 0, 0)
	end
	
	if canSeeEnemy == true then
		highlight.FillColor = Color3.new(0, 0, 0.498039)
	end
end

script:SetAttribute("Shutoff", true)
