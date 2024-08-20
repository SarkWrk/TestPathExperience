local actionTable = {}

actionTable.Teleport = function(part : Model, endPosition : Vector3)
	part:PivotTo(CFrame.new(endPosition + Vector3.new(0, part.PrimaryPart.Position.Y, 0)))
end

return actionTable
