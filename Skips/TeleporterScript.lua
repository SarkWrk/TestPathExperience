local teleportFunction = require(game:GetService("ServerStorage").CustomActions).Teleport

function reply(part : Part)
	teleportFunction(part, script.Parent.Parent[script.Parent.Linked.Value].Position)

	return 200
end

script.Parent.TP.OnInvoke = reply
