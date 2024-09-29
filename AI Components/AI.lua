local class = {}
class.interface = {}
class.schema = {}
class.metatable = {__index = class.schema}

function class.interface.New(owner : Script, rig : Model, diedEvent : BindableEvent, pathfindingScript : Script, shootingScript : Script, stateManagerScript : Script, firedEvent : BindableEvent,
	locationToShootFrom : Part, weaponInformation : table
)
	local self = setmetatable({}, class.metatable)
	self.Combat = require(script.Parent:WaitForChild("CombatAI")).interface.New(owner, rig, diedEvent, locationToShootFrom, weaponInformation, firedEvent)
	self.Pathfinding = require(script.Parent:WaitForChild("PathfindingAI")).interface.New(owner, rig, shootingScript, diedEvent, stateManagerScript)
	
	return self
end

function class.schema.CleanUp(self : BaseAI)
	self.Combat:CleanUp()
	self.Pathfinding:CleanUp()
end

type BaseAI = typeof(class.interface.New(table.unpack(...)))


return class
