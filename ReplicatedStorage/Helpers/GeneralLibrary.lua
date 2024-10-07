local module = {}

function module.Rounder(input : number, places : number) : number
	return math.round(input * places)/places
end

function module.Delta(initial : number | Vector3, final : number | Vector3) : number
	if typeof(initial) == "number" and typeof(final) == "number" then
		return final-initial
	elseif typeof(initial) == "Vector3" and typeof(final) == "Vector3" then
		return (final-initial).Magnitude
	else
		warn("Helper function 'Delta' warning: Non-matching types: Initial type '" .. typeof(initial) .. "' does not match final type '" .. typeof(final) .. "'.")
	end
end

return module
