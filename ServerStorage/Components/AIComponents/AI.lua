local class = {}
class.interface = {}
class.schema = {}
class.metatable = {__index = class.schema}

local types = require(game:GetService("ServerStorage"):WaitForChild("Types"))

function class.interface.New(info : types.AIConfigurations)
	local self = setmetatable({}, class.metatable)
	self.Combat = require(script.Parent:WaitForChild("CombatAI")).interface.New(info.owner, info.rig, info.combatInformation, info.diedEvent, info.locationToShootFrom, info.weaponInformation, info.firedEvent, info.difficulty)
	self.Pathfinding = require(script.Parent:WaitForChild("PathfindingAI")).interface.New(info.owner, info.rig, info.pathfindingInformation, info.combatScript, info.diedEvent, info.stateManagerScript)
	
	self.Shutoff(self, info.combatScript, info.pathfindingScript, info.owner)
	
	return self
end

function class.schema.Shutoff(self : BaseAI, pathfindScript : Script, combatScript : Script, owner : Script)
	if owner == pathfindScript and owner == combatScript then
		coroutine.resume(coroutine.create(function()
			while self.Combat.Shutoff == false and self.Pathfinding.Shutoff == false do
				task.wait()
			end

			owner:SetAttribute("Shutoff", true)
		end))
	else
		coroutine.resume(coroutine.create(function()
			while self.Combat.Shutoff == false do
				task.wait()
			end

			combatScript:SetAttribute("Shutoff", true)
		end))

		coroutine.resume(coroutine.create(function()
			while self.Pathfinding.Shutoff == false do
				task.wait()
			end

			pathfindScript:SetAttribute("Shutoff", true)
		end))
	end
end

function class.schema.CleanUp(self : BaseAI)
	local _, _ = pcall(function()
		self.Combat:CleanUp()
	end)
	local _, _ = pcall(function()
		self.Pathfinding:CleanUp()
	end)
end

export type BaseAI = typeof(class.interface.New(table.unpack(...)))


return class
