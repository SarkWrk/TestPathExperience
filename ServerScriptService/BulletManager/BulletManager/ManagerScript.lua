--!strict

local bulletComponent = require(game:GetService("ServerStorage"):WaitForChild("Components"):WaitForChild("BulletComponent"):WaitForChild("BulletComponent"))
local byteNet = require(game:GetService("ReplicatedStorage"):WaitForChild("ByteNet"):WaitForChild("ByteNet"))
local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("ByteNet"):WaitForChild("Packets"))

local bulletIndex = 0
local activeBullets : {[number] : {["lookdirection"] : Vector3}} = {}
local event = game:GetService("ReplicatedStorage").MoveBullets
local totalActiveBullets = 0
local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))


local function SendToClients(setting : string, sendData : {Index : number, Position : Vector3?, EndPosition : Vector3?, Speed : number?, Rotation : Vector3?})
	packets.BulletCreation.BulletCreation.sendToAll({
		Setting = setting,
		Index = sendData.Index,
		Position = helper.Conversions.Vector3ToString(sendData.Position, ",", true, 3),
		EndPosition = helper.Conversions.Vector3ToString(sendData.EndPosition, ",", true, 3),
		Speed = sendData.Speed,
		Rotation = helper.Conversions.Vector3ToString(sendData.Rotation, ","),
	})
end

local function BulletCreation(info : {})
	coroutine.resume(coroutine.create(function()
		-- Create an index in activeBullets to track the bullet that has been fired
		local index = bulletIndex
		bulletIndex += 1
		local bullet = bulletComponent.interface.New(info)
		local lookAt = bullet.Variable.LookDirection

		activeBullets[index] = {lookdirection = helper.Conversions.CFrameToVector3(bullet.Variable.LookDirection, true, 2)}

		local heartbeat
		
		totalActiveBullets += 1
		
		local endPosition = (bullet.Variable.LookDirection * CFrame.Angles(0, math.rad(-90), 0)).LookVector * bullet.Information.DistanceTimeOut
		
		-- Prepares some data to be sent to the client for bullet creation
		local sendInformation = {}
		sendInformation.Index = index
		sendInformation.Position = bullet.Information.StartPosition
		sendInformation.EndPosition = endPosition - Vector3.new(0, helper.Delta(bullet.Information.StartPosition, endPosition)/bullet.Information.Speed * bullet.Information.BulletDrop, 0)
		sendInformation.Speed = bullet.Information.Speed
		sendInformation.Rotation = helper.Conversions.CFrameToVector3(bullet.Variable.LookDirection, true, 2)

		task.synchronize()
		SendToClients("C", sendInformation)

		-- Monitor the bullet for specific information
		heartbeat = game:GetService("RunService").Heartbeat:ConnectParallel(function()
			activeBullets[index].lookdirection = helper.Conversions.CFrameToVector3(bullet.Variable.LookDirection, true, 2)

			-- When the bullet is destroyed, tell the client to also destroy the bullet
			if bullet.Variable.ToDestroy == true then
				totalActiveBullets -= 1

				task.synchronize()
				
				SendToClients("D", {Index = index})

				heartbeat:Disconnect()
			end
		end)
	end))
end

function ServerBulletCreation(info : {})
	-- Throttle the server from creating more bullets than this amount
	if totalActiveBullets > 1000 then
		return
	end
	
	BulletCreation(info)
end

script.Parent:BindToMessage("ServerCreate", ServerBulletCreation)
