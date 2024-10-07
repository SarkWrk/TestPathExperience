local tracker : {[number] : {Part : Part, Tween : Tween}} = {}
local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))

function StringSplitter(toBeSplit : string, seperator : string?) : {}
	if seperator == nil then
		seperator = ","
	end
	
	return string.split(toBeSplit, seperator)
end

function FixVector3(toBeFixed : string) : Vector3
	local splitInformation = StringSplitter(toBeFixed)
	return Vector3.new(splitInformation[1], splitInformation[2], splitInformation[3])
end

function RemoveBullet(index : number) : nil
	if tracker[index] ~= nil then
		if tracker[index].Part then
			game:GetService("Debris"):AddItem(tracker[index].Part, 0)
			tracker[index].Tween:Cancel()
			tracker[index] = nil
		end
	end
end

game:GetService("ReplicatedStorage").MoveBullets.OnClientEvent:Connect(function(eventType : string, information : {Index : number, Position : string, EndPosition : string, Speed : number, Rotation : string} | number)
	if eventType == "D" then
		RemoveBullet(information)
	elseif eventType == "C" then
		local rotation = StringSplitter(information.Rotation)
		
		local bullet = game:GetService("ReplicatedStorage").Bullet:Clone()
		bullet.Parent = workspace.Bullets
		bullet.CFrame = CFrame.new(FixVector3(information.Position)) * CFrame.Angles(rotation[1], rotation[2], rotation[3])

		tracker[information.Index] = {}

		local tween = game:GetService("TweenService"):Create(bullet, TweenInfo.new(helper.Delta(FixVector3(information.Position), FixVector3(information.EndPosition))/information.Speed, Enum.EasingStyle.Linear), {Position = FixVector3(information.EndPosition)})
		tween:Play()
		
		tween.Completed:Connect(function()
			RemoveBullet(information.Index)
		end)

		tracker[information.Index].Part = bullet
		tracker[information.Index].Tween = tween
		
	else
		warn("EventType '" .. eventType .. "' not registered.")
	end
end)
