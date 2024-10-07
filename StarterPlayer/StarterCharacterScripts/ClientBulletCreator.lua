local tracker : {[number] : {Part : Part, Tween : Tween}} = {}
local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local byteNet = require(game:GetService("ReplicatedStorage"):WaitForChild("ByteNet"):WaitForChild("ByteNet"))
local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("ByteNet"):WaitForChild("Packets"))

function RemoveBullet(index : number) : nil
	if tracker[index] ~= nil then
		if tracker[index].Part then
			game:GetService("Debris"):AddItem(tracker[index].Part, 0)
			tracker[index].Tween:Cancel()
			tracker[index] = nil
		end
	end
end

packets.BulletCreation.BulletCreation.listen(function(data)
	if data.Setting == "D" then
		RemoveBullet(data.Index)
	elseif data.Setting == "C" then
		local bullet = game:GetService("ReplicatedStorage").Bullet:Clone()
		bullet.Parent = workspace.Bullets
		bullet.CFrame = helper.Conversions.Vector3ToCFrame(helper.Conversions.StringToVector3(data.Position, ","), helper.Conversions.StringToVector3(data.Rotation, ","))

		tracker[data.Index] = {}

		tracker[data.Index].Tween = game:GetService("TweenService"):Create(bullet, TweenInfo.new(helper.Delta(helper.Conversions.StringToVector3(data.Position, ","), helper.Conversions.StringToVector3(data.EndPosition, ","))/data.Speed, Enum.EasingStyle.Linear), {Position = helper.Conversions.StringToVector3(data.EndPosition, ",")})

		tracker[data.Index].Part = bullet
		
		tracker[data.Index].Tween:Play()
		tracker[data.Index].Tween.Completed:Connect(function()
			RemoveBullet(data.Index)
		end)
	else
		warn("Setting '" .. data.Setting .. "' not registered.")
	end
end)
