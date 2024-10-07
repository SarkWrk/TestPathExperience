local bulletComponent = require(game:GetService("ServerStorage"):WaitForChild("Components"):WaitForChild("BulletComponent"):WaitForChild("BulletComponent"))

local bulletIndex = 0
local activeBullets : {[number] : {["lookdirection"] : string}} = {}
local event = game:GetService("ReplicatedStorage").MoveBullets
local totalActiveBullets = 0
local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))

local function BulletCreation(info : {})
	coroutine.resume(coroutine.create(function()
		--[[Converts a CFrame to a string equivilant of its rotation
		Accepts overloads of:
		converted <CFrame> → The CFrame that should be converted to a string of its rotation
		seperator <string> → The seperator between the X, Y, and Z rotation
		]]
		local function ConvertCFrameToString(converted : CFrame, seperator : string?) : string
			if seperator == nil then
				seperator = ","
			end

			local angleX, angleY, angleZ = converted:ToEulerAnglesXYZ()
			
			return tostring(helper.Rounder(angleX, 2)) .. seperator .. tostring(helper.Rounder(angleY, 2)) .. seperator .. tostring(helper.Rounder(angleZ, 2))
		end
		
		--[[Converts a Vector3 to a string representation
		Accepts overloads of:
		vector <Vector3> → The Vector3 that should be converted to a string
		seperator <string> → The seperator between each positional axis
		]]
		local function ShortenVector3(vector : Vector3, seperator : string?) : string
			if seperator == nil then
				seperator = ","
			end
			return helper.Rounder(vector.X, 3) .. seperator .. helper.Rounder(vector.Y, 3) .. seperator .. helper.Rounder(vector.Z, 3)
		end

		-- Create an index in activeBullets to track the bullet that has been fired
		local index = bulletIndex
		bulletIndex += 1
		local bullet = bulletComponent.interface.New(info)
		local lookAt = bullet.Variable.LookDirection

		activeBullets[index] = {lookdirection = ConvertCFrameToString(bullet.Variable.LookDirection)}

		local heartbeat
		
		totalActiveBullets += 1
		
		-- Prepares some data to be sent to the client for bullet creation
		local sendInformation = {}
		sendInformation.Index = index
		sendInformation.Position = ShortenVector3(bullet.Information.StartPosition)
		sendInformation.EndPosition = ShortenVector3((bullet.Variable.LookDirection * CFrame.Angles(0, math.rad(-90), 0)).LookVector * bullet.Information.DistanceTimeOut)
		sendInformation.Speed = bullet.Information.Speed
		sendInformation.Rotation = ConvertCFrameToString(bullet.Variable.LookDirection)

		task.synchronize()
		event:FireAllClients("C", sendInformation)

		-- Monitor the bullet for specific information
		heartbeat = game:GetService("RunService").Heartbeat:ConnectParallel(function()
			activeBullets[index].lookdirection = ConvertCFrameToString(bullet.Variable.LookDirection)

			-- When the bullet is destroyed, tell the client to also destroy the bullet
			if bullet.Variable.ToDestroy == true then
				totalActiveBullets -= 1

				task.synchronize()
				
				event:FireAllClients("D", index)

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
