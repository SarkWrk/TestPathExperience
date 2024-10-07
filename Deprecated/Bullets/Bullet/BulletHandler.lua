local tagService = game:GetService("CollectionService")

local main = {}

main.Damage = 0 -- How much damage to do
main.Enemy = {} -- Should damage Humanoid if hit a part tagged with this
main.IgnoreTagged = {} -- Should not destroy self when hitting a part tagged with this
main.MoveTowards = CFrame.new(0, 0, 0) -- Direction to move the bullet
main.BulletDrop = 0 -- Studs per second
main.DistanceTimeOut = 0 -- Studs
main.Speed = 0 -- Studs per second
main.SetInformation = false -- Check for whether the table has been filled out
main.TotalStudsMoved = 0 -- Total studs moved (not including bullet drop)
main.Pierce = 0 -- How many parts the bullet can pierce
main.PierceDamageLoss = 0 -- How much damage to loose on pierce (%)
main.PartsPierced = {} -- Parts already pierced

main.CalculatedMovingDirection = Vector3.new(0, 0, 0) -- Where the bullet is currently moving towards
main.ToDestroy = false -- Sets to true when the bullet should be destroyed

-- Fire BindableEvent to store information for the bullet to function
script.Parent.Parent:BindToMessageParallel("Inform", function(information : table)
	-- But only do it once
	if main.SetInformation == false then
		main.Damage = information.Damage
		main.Enemy = information.Enemy
		main.IgnoreTagged = information.IgnoreTagged
		main.MoveTowards = information.MoveTowards
		main.BulletDrop = information.BulletDrop
		main.DistanceTimeOut = information.DistanceTimeOut
		main.Speed = information.Speed
		main.Pierce = information.Pierce
		main.PierceDamageLoss = information.PierceDamageLoss
		main.SetInformation = true
	end
end)


-- Halt while information is not set
while main.SetInformation == false do
	task.wait()
end

-- A function to destroy the bullet
function Remove() : nil
	if main.ToDestroy == true then
		game:GetService("Debris"):AddItem(script.Parent.Parent, 0)
	end
end

-- Create a raycast params for hitreg
local castParams = RaycastParams.new()
castParams.FilterType = Enum.RaycastFilterType.Exclude
castParams.RespectCanCollide = true

local allies = {}

-- Check if the bullet has hit a part
local function CheckHit(moveDirection) : nil
	debug.profilebegin("HitDetection")
	-- Returns if the bullet has already hit something
	if main.ToDestroy == true then
		return
	end
	
	table.clear(allies)
	
	for i, v in pairs(main.IgnoreTagged) do
		table.insert(allies, tagService:GetTagged(v))
	end
	
	castParams.FilterDescendantsInstances = allies
	
	local rayCast = workspace:Raycast(script.Parent.Position, main.CalculatedMovingDirection, castParams)
	
	if not rayCast then
		debug.profileend()
		return
	end
	
	if not rayCast.Instance then
		debug.profileend()
		return
	end
	
	if table.maxn(main.PartsPierced) >= main.Pierce then
		main.ToDestroy = true -- Tells the programme that it has hit more parts than the pierce limit + 1, and therefore the bullet should afterwards be destroyed
	else
		if table.maxn(main.PartsPierced) > 0 then
			main.Damage = main.Damage - (main.Damage/100*main.PierceDamageLoss)
		end
	end
	
	local hitPart = rayCast.Instance
	local isEnemy = false
	
	-- Check if the part has already been pierced through, and therefore should be ignored
	if table.find(main.PartsPierced, hitPart) then
		return
	end

	-- Detects if the hitpart or parent has a tag that is affilated with the enemy
	for i, v in pairs(main.Enemy) do
		if hitPart:HasTag(v) then
			isEnemy = true
		end
	end
	for i, v in pairs(main.Enemy) do
		if hitPart.Parent:HasTag(v) then
			isEnemy = true
		end
	end

	-- Destroys itself if it's not an enemy
	if isEnemy == false then
		debug.profileend()
		Remove()
		main.PartsPierced[main.Pierce] = hitPart
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
		Remove()
		main.PartsPierced[main.Pierce] = hitPart
		return
	end
	
	local defense = hitPart:GetAttribute("Defense")
	
	if defense == nil then
		defense = hitPart.Parent:GetAttribute("Defense")
	end
	
	if defense == nil then
		defense = 0
	end
	
	humanoid:TakeDamage(main.Damage - (main.Damage/100*defense))

	debug.profileend()
	Remove()
	main.PartsPierced[main.Pierce] = hitPart
end

script.Parent.CFrame = CFrame.lookAt(script.Parent.Position, main.MoveTowards.LookVector * main.DistanceTimeOut)
	* CFrame.Angles(0, math.rad(90), 0) -- Sets the CFame to look in the direction that it should be moving towards

-- Moves the bullet and drops it every second, also destroys the bullet if it has passed main.DistanceTimeOut
game:GetService("RunService").Heartbeat:Connect(function(delta)
	-- Calculates the direction for the bullet to move, and then moves it in that direction
	main.CalculatedMovingDirection = main.MoveTowards.LookVector * (main.Speed*delta)
	script.Parent.Position = script.Parent.Position + main.CalculatedMovingDirection - Vector3.new(0, main.BulletDrop * delta, 0)

	coroutine.resume(coroutine.create(CheckHit)) -- Runs the hitreg in a coroutine

	main.TotalStudsMoved += main.CalculatedMovingDirection.Magnitude -- Updates how far the bullet has moved

	-- If the bullet has moved further than main.DistanceTimeOut, then destroy the bullet
	if main.TotalStudsMoved >= main.DistanceTimeOut then
		main.ToDestroy = true
		Remove()
	end
end)
