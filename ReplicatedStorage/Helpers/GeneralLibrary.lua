local module = {}

module.Conversions = {}

-- Rounds a number to "places" decimal places
function module.Rounder(input : number, places : number) : number
	return math.round(input * places)/places
end

-- Finds the delta between two numbers or two Vector3s, will warn if both variables do not match types
function module.Delta(initial : number | Vector3, final : number | Vector3) : number
	if typeof(initial) == "number" and typeof(final) == "number" then
		return final-initial
	elseif typeof(initial) == "Vector3" and typeof(final) == "Vector3" then
		return (final-initial).Magnitude
	else
		warn("Helper function 'Delta' warning: Non-matching types: Initial type '" .. typeof(initial) .. "' does not match final type '" .. typeof(final) .. "'.")
	end
end

--[[Converts a string to a Vector3
Accepts overloads of:
stringEquivilant <string> → The string that should be converted to a Vector3
seperator <string> → The seperator between each positional axis
]]
function module.Conversions.StringToVector3(stringEquivilant : string, seperator : string) : Vector3
	local split = string.split(stringEquivilant, seperator)
	return Vector3.new(split[1], split[2], split[3])
end

--[[Converts a Vector3 to a CFrame
Accepts overloads of:
position <Vector3> → The Vector3 that should be converted to CFrame.new(x, y, z)
rotation <Vector3> → The Vector3 that should be converted to CFrame.Angles(x, y, z)
seperator <string> → The seperator between each positional component
]]
function module.Conversions.Vector3ToCFrame(position : Vector3, rotation : Vector3) : CFrame
	return CFrame.new(position) * CFrame.Angles(rotation.X, rotation.Y, rotation.Z)
end

--[[Converts a Vector3 to a string representation
Accepts overloads of:
vector <Vector3?> → The Vector3 that should be converted to a string
seperator <string?> → The seperator between each positional axis
round <boolean?> → Whether the Vector3 components should be rounded
places <number?> → How many places to round the components to
]]
function module.Conversions.Vector3ToString(vector : Vector3?, seperator : string?, round : boolean?, places : number?) : string | nil
	if vector == nil or seperator == nil then
		return nil
	end
	
	if round == true then
		return module.Rounder(vector.X, places) .. seperator .. module.Rounder(vector.Y, places) .. seperator .. module.Rounder(vector.Z, places)
	else
		return vector.X .. seperator .. vector.Y .. seperator .. vector.Z
	end
end

--[[Converts a CFrame to a string equivilant of its rotation
Accepts overloads of:
converted <CFrame> → The CFrame that should be converted to a string of its rotation
round <boolean?> → Whether the Vector3 components should be rounded
places <number?> → How many places to round the components to
]]
function module.Conversions.CFrameToVector3(converted : CFrame, round : boolean, places : number?) : Vector3
	local angleX, angleY, angleZ = converted:ToEulerAnglesXYZ()

	if round == true then
		return Vector3.new(module.Rounder(angleX, places), module.Rounder(angleY, places), module.Rounder(angleZ, places))
	else
		return Vector3.new(angleX, angleY, angleZ)
	end
end

return module
