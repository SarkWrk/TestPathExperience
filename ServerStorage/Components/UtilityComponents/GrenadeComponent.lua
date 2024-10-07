local class = {}
class.interface = {}
class.schema = {}
class.metatable = {__index = class.schema}

class.ExcludedTagsInRaycast = {
	"AI",
	"Visualiser",
	"Goal",
	"Bullet",
	"Enemy Utilities"
}


function class.interface.New(information : table, customisation : table) : Grenade
	local grenade = setmetatable({}, class.metatable)
	
	local part = game:GetService("ServerStorage"):WaitForChild("Utilities"):WaitForChild("Grenade"):Clone()
	part.Position = information.Position
	part.Parent = workspace.Utilities
	part.AssemblyLinearVelocity = information.Velocity
	
	grenade.Part = part
	
	grenade.Information = class.schema.Setup(customisation)
	
	coroutine.resume(coroutine.create(function()
		--local tickSound = Instance.new("Sound")
		--tickSound.SoundId = "rbxassetid://" .. 1
		--tickSound.Parent = parent

		local ylevel1 = nil
		local ylevel2 = nil
		local ylevel3 = nil
		local ylevel4 = nil
		local ylevel5 = nil
		local ylevel6 = nil
		local ylevel7 = nil
		local ylevel8 = nil
		local ylevel9 = nil
		local ylevel10 = 0

		while task.wait() do
			ylevel1 = ylevel2
			ylevel2 = ylevel3
			ylevel3 = ylevel4
			ylevel4 = ylevel5
			ylevel5 = ylevel6
			ylevel6 = ylevel7
			ylevel7 = ylevel8
			ylevel8 = ylevel9
			ylevel9 = ylevel10
			ylevel10 = math.round(part.Position.Y*10000)

			--if ylevel10 = ylevel1 then
			--	if ylevel10 == ylevel2 then
			--		if ylevel10 == ylevel3 then
			--			if ylevel10 == ylevel4 then
			--				if ylevel10 == ylevel5 then
			if ylevel10 == ylevel6 then
				if ylevel10 == ylevel7 then
					if ylevel10 == ylevel8 then
						if ylevel10 == ylevel9 then
							break
						end
					end
				end
			end
			--				end
			--			end
			--		end
			--	end
			--end
		end

		if grenade.Information.StartedExploding == true then
			return
		end

		grenade.Information.StartedExploding = true

		grenade.Part:SetAttribute("Exploding", true)

		local startTime = tick()
		local soundTime = tick()

		local speedTween = game:GetService("TweenService"):Create(part, TweenInfo.new(2, Enum.EasingStyle.Linear), {AssemblyLinearVelocity = Vector3.new(0,0,0)})
		speedTween:Play()

		while task.wait() do
			if tick()-startTime >= grenade.Information.ExplosionDelay then
				break
			elseif (tick()-soundTime) >= 1 then
				--tickSound:Play()
				soundTime = tick()
			end
		end

		--local sound = Instance.new("Sound")
		--sound.SoundId = "rbxassetid://" .. 1
		local explosion = Instance.new("Explosion")
		explosion.BlastRadius = 0
		explosion.TimeScale = 0.5

		--sound.Parent = parent
		--sound:Play()

		explosion.Position = part.Position
		explosion.Parent = part

		class.schema.Explode(grenade, part.Position)

		part.Transparency = 1

		speedTween:Pause()

		task.wait(0.05)

		game:GetService("Debris"):AddItem(part, 0)
	end))
	
	return grenade
end

function class.schema.Setup(customisation)
	local information = {}
	
	information.Damage = customisation.Damage -- In HP
	information.Range = customisation.Range -- In studs
	information.FallOff = customisation.FallOffDueToDistance -- %damage to take off per 10 studs
	information.WallFallOff = customisation.FallOffDueToObjects -- %damage to take off
	information.ExplosionDelay = customisation.Timer -- In seconds
	information.DamageableInstances = customisation.Instances -- A table
	information.StartedExploding = false
	
	return information
end

function class.schema.GetFilter(tags : table) : table
	local filtered = {}
	
	for _, tagged in pairs(tags) do
		table.insert(filtered, game:GetService("CollectionService"):GetTagged(tagged))
	end
	
	return filtered
end

function class.schema.UnsafeRemoval(self : Grenade) : nil
	game:GetService("Debris"):AddItem(self.Part, 0)
end

function class.schema.Explode(self : Grenade, position : Vector3) : nil
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = class.schema.GetFilter(self.Information.DamageableInstances)
	
	local cast = workspace:GetPartBoundsInRadius(position, self.Information.Range, params)
	
	local parts = {}
	
	for _, part in pairs(cast) do
		local acestor = part:FindFirstAncestorOfClass("Model")
		
		if acestor then
			if table.find(parts, acestor) then
				continue
			end
			
			table.insert(parts, acestor)
		end
	end
	
	for _, model in pairs(parts) do
		local humanoid : Humanoid? = model:FindFirstChildOfClass("Humanoid")
		
		if humanoid then
			local hitPosition = model.PrimaryPart.Position
			local distance = (position-hitPosition).Magnitude/10
			local hitWall = false
			
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.RespectCanCollide = true
			raycastParams.FilterDescendantsInstances = class.schema.GetFilter(class.ExcludedTagsInRaycast)
			
			if workspace:Raycast(position, CFrame.lookAt(position, hitPosition).LookVector * distance*10, raycastParams) then
				hitWall = true
			end
			
			local actualDamage = self.Information.Damage - ( (self.Information.Damage/100 * self.Information.FallOff) * distance + (self.Information.Damage/100 * self.Information.WallFallOff))
		
			humanoid:TakeDamage(actualDamage)
		end
	end
end


type Grenade = typeof(class.interface.New(table.unpack(...)))


return class
