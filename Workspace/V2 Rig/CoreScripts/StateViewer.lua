local rig = script.Parent.Parent
local AIScript = script.Parent.AI
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
	
	walking = AIScript:GetAttribute("Moving")
	idled = not AIScript:GetAttribute("InCycle")
	canSeeEnemy = AIScript:GetAttribute("CanSeeEnemy")
	
	if walking == true then
		if animatorScript:GetAttribute("WalkAnimation") == true then
			highlight.FillColor = Color3.new(0, 1, 1)
		else
			highlight.FillColor = Color3.new(0.666667, 1, 1)
		end
	else
		highlight.FillColor = Color3.new(0.666667, 0, 0)
	end
	
	if canSeeEnemy == true then
		highlight.FillColor = Color3.new(0, 0, 0.498039)
	end
end

script:SetAttribute("Shutoff", true)
