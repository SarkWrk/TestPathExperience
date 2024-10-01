local class = {}
class.interface = {}
class.schema = {}
class.metatable = {__index = class.schema}

function class.interface.New(info) : Bullet
	local bullet = setmetatable({}, class.metatable)
	
	bullet.Information = class.schema.SetUpInformation(info)
	bullet.Variable = class.schema.VariableInformation(bullet.Information)
	bullet.RBXScriptConnections = {}
	bullet.Allies = {}
	
	-- Create a raycast params for hitreg
	bullet.RaycastParameters = RaycastParams.new()
	bullet.RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
	bullet.RaycastParameters.RespectCanCollide = true
	
	bullet.Movement(bullet)
	
	return bullet
end

function class.schema.SetUpInformation(info)
	local information = {}
	
	information.Damage = info.Damage -- HP
	information.Enemy = info.Enemy -- Tags
	information.IgnoreTagged = info.IgnoreTagged -- Tags
	information.MoveTowards = info.MoveTowards -- Vector3
	information.BulletDrop = info.BulletDrop -- Studs/sec
	information.DistanceTimeOut = info.DistanceTimeOut -- Studs
	information.Speed = info.Speed -- Studs/sec
	information.Pierce = info.Pierce -- Parts
	information.PierceDamageLoss = info.PierceDamageLoss -- %damage
	information.StartPosition = info.StartPosition -- Vector3
	
	return information
end

function class.schema.VariableInformation(information)
	local variable = {}
	
	variable.BulletPart = nil
	variable.DistanceMoved = 0
	variable.CalculatedMovingDirection = Vector3.new(0, 0, 0)
	variable.ToDestroy = false
	variable.Position = information.StartPosition
	variable.PartsPierced = {}
	
	return variable
end

-- Check if the bullet has hit a part
function class.schema.HitDetection(self : Bullet) : nil
	debug.profilebegin("HitDetection")
	
	-- Returns if the bullet has already hit something
	if self.Variable.ToDestroy == true then
		return
	end

	table.clear(self.Allies)

	for i, v in pairs(self.Information.IgnoreTagged) do
		table.insert(self.Allies, game:GetService("CollectionService"):GetTagged(v))
	end

	self.RaycastParameters.FilterDescendantsInstances = self.Allies

	local rayCast = workspace:Raycast(self.Variable.Position, self.Variable.CalculatedMovingDirection, self.RaycastParameters)

	if not rayCast then
		debug.profileend()
		return
	end

	if table.maxn(self.Variable.PartsPierced) >= self.Information.Pierce then
		self.Variable.ToDestroy = true -- Tells the programme that it has hit more parts than the pierce limit + 1, and therefore the bullet should afterwards be destroyed
	else
		if table.maxn(self.Variable.PartsPierced) > 0 then
			self.Information.Damage = self.Information.Damage - (self.Information.Damage/100*self.Information.PierceDamageLoss)
		end
	end

	local hitPart = rayCast.Instance
	local isEnemy = false

	-- Check if the part has already been pierced through, and therefore should be ignored
	if table.find(self.Variable.PartsPierced, hitPart) then
		return
	end

	-- Detects if the hitpart or if the clostest ancestor has a tag that is affilated with the enemy
	for i, v in pairs(self.Information.Enemy) do
		if hitPart:HasTag(v) then
			isEnemy = true
		end
	end
	for i, v in pairs(self.Information.Enemy) do
		if hitPart:FindFirstAncestorOfClass("Model"):HasTag(v) then
			isEnemy = true
		end
	end

	-- Destroys itself if it's not an enemy
	if isEnemy == false then
		debug.profileend()
		self.SafeRemova(self)
		self.Variable.PartsPierced[table.maxn(self.Variable.PartsPierced)] = hitPart
		return
	end

	-- Attempts to find the humanoid
	local humanoid = hitPart:FindFirstChildOfClass("Humanoid")

	if humanoid == nil then
		humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid")
	end

	-- If there's no Humanoid, destroys itself
	if not humanoid then
		debug.profileend()
		self.SaveRemoval(self)
		self.Variable.PartsPierced[table.maxn(self.Variable.PartsPierced)] = hitPart
		return
	end

	local defense = hitPart:GetAttribute("Defense")

	if defense == nil then
		defense = hitPart.Parent:GetAttribute("Defense")
	end

	if defense == nil then
		defense = 0
	end

	humanoid:TakeDamage(self.Information.Damage - (self.Information.Damage/100*defense))

	debug.profileend()
	self.SafeRemoval(self)
	self.Variable.PartsPierced[table.maxn(self.Variable.PartsPierced)] = hitPart
end

-- Sets the CFame to look in the direction that it should be moving towards
function class.schema.LookAtMovementDirection(self : Bullet) : nil
	local part : Part = self.CreateBullet(self).Bullet
	
	part.CFrame = CFrame.lookAt(self.Information.StartPosition, self.Information.MoveTowards.LookVector * self.Information.DistanceTimeOut) * CFrame.Angles(0, math.rad(90), 0)
end

-- A function to remove all RBXScriptConnections
function class.schema.RemoveRBXConnections(self : Bullet) : nil
	for _, v : RBXScriptConnection in pairs(self.RBXScriptConnections) do
		v:Disconnect()
	end
end

-- A function to create a bullet
function class.schema.CreateBullet(self : Bullet) : Part
	if self.Variable.BulletPart ~= nil then
		return self.Variable.BulletPart
	end

	local part = game:GetService("ServerStorage").Bullet:Clone()
	self.Variable.BulletPart = part

	part.Parent = workspace.Bullets

	return part
end

-- A function to destroy the bullet
function class.schema.SafeRemoval(self) : nil
	if self.Variable.ToDestroy == true then
		local part = class.schema.CreateBullet(self)

		self.RemoveRBXConnections(self)

		game:GetService("Debris"):AddItem(part, 0)
	end
end

-- Moves the bullet and drops it every second, also destroys the bullet if it has passed main.DistanceTimeOut
function class.schema.Movement(self : Bullet)
	local part = self.CreateBullet(self).Bullet
	
	self.LookAtMovementDirection(self)
	
	self.RBXScriptConnections.Movement = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		
		-- Calculates the direction for the bullet to move, and then moves it in that direction
		self.Variable.CalculatedMovingDirection = self.Information.MoveTowards.LookVector * self.Information.Speed * deltaTime
		self.Variable.Position = self.Variable.Position + self.Variable.CalculatedMovingDirection - Vector3.new(0, self.Information.BulletDrop * deltaTime, 0)
		part.Position = self.Variable.Position
		
		-- Runs the hitreg in a coroutine
		coroutine.resume(coroutine.create(function()
			self.HitDetection(self)
		end))
		
		self.Variable.DistanceMoved += self.Variable.CalculatedMovingDirection.Magnitude -- Updates how far the bullet has moved
		
		-- If the bullet has moved further than main.DistanceTimeOut, then destroy the bullet
		if self.Variable.DistanceMoved >= self.Information.DistanceTimeOut then
			self.Variable.ToDestroy = true
			self.SafeRemoval(self)
		end
	end)
end

type Bullet = typeof(class.interface.New(table.unpack(...)))

return class
