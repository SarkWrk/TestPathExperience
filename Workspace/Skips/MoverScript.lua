local touched = false
local cooldown = 0
local studsPerSecond = 10

local tweenService = game:GetService("TweenService")
local firstTween = {}
local secondTween = {}

local link : PathfindingLink = game.Workspace.Skips.Links.MovingPlatforms[script.Parent.Parent.LinkName.Value]
local attach1 = script.Parent.Parent.Ends.End2.End2
local attach2 = script.Parent.Parent.Ends.End1.End1

local startPos = Vector3.new(attach2.Parent.Position.X, script.Parent.Position.Y, attach2.Parent.Position.Z)
local endPos = Vector3.new(attach1.Parent.Position.X, script.Parent.Position.Y, attach1.Parent.Position.Z)

local timeToStartPos = (script.Parent.Position-startPos).Magnitude/studsPerSecond
local timeToEndPos = (script.Parent.Position-endPos).Magnitude/studsPerSecond

local startInfo = TweenInfo.new(timeToStartPos, Enum.EasingStyle.Linear)
local endInfo = TweenInfo.new(timeToEndPos, Enum.EasingStyle.Linear)

function First()
	firstTween = {}
	table.insert(firstTween, tweenService:Create(script.Parent, endInfo, {Position = endPos}))
	local function loop(x : Part | Model)
		for i, v : Part|Model in pairs(x) do
			if v.ClassName == "Model" then
				loop(v:GetChildren())
			elseif v.ClassName == "Part" then
				local distance = v.CFrame.Position-script.Parent.Position
				table.insert(firstTween, tweenService:Create(v, endInfo, {Position = endPos + distance}))
			end
		end
	end
	loop(script.Parent.Parent.Attached:GetChildren())
	link.Attachment1 = attach2
end

function Second()
	secondTween = {}
	table.insert(secondTween, tweenService:Create(script.Parent, startInfo, {Position = startPos}))
	local function loop(x : Part | Model)
		for i, v : Part|Model in pairs(x) do
			if v.ClassName == "Model" then
				loop(v:GetChildren())
			elseif v.ClassName == "Part" then
				local distance = v.CFrame.Position-script.Parent.Position
				table.insert(secondTween, tweenService:Create(v, startInfo, {Position = startPos + distance}))
			end
		end
	end
	loop(script.Parent.Parent.Attached:GetChildren())
	link.Attachment1 = attach1
end

function Remove()
	touched = false
	cooldown = 1
	
	script.Parent.Active.Value = false
	
	while cooldown > 0 do
		cooldown -= 0.1
		task.wait(0.1)
	end
end

script.Parent.Parent.Attached.Start.Touch.Event:Connect(function()
	if cooldown > 0 then
		return
	end
	
	touched = true
end)

while task.wait() do
	while touched == false do
		task.wait()
	end
	
	First()
	script.Parent.Active.Value = true
	
	for i, v : Tween in pairs(firstTween) do
		v:Play()
	end
	task.wait(timeToEndPos)
	
	Remove()
	
	while touched == false do
		task.wait()
	end
	
	Second()
	script.Parent.Active.Value = true
	
	for i, v : Tween in pairs(secondTween) do
		v:Play()
	end
	task.wait(timeToStartPos)
	
	Remove()
end
