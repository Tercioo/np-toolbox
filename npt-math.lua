

local npt = _G.NoPixelToolbox

local PI = math.pi
local atan2 = math.atan2
local sqrt = math.sqrt


--find heading from point1 to point2
--returned value is in degrees
function npt.FindHeading (vector1, vector2)
	return (atan2 (vector2.y - vector1.y, vector2.x - vector1.x) + PI) * 180 / PI
end

--dot product of two vectors
function npt.DotProduct (vector1, vector2)
	vector1 = npt.NormalizeVector (vector1)
	vector2 = npt.NormalizeVector (vector2)
	return (vector1.x * vector2.x) + (vector1.y * vector2.y)
end

--normalize a vector
function npt.NormalizeVector (vector)
	local scale = sqrt ((vector.x * vector.x) + (vector.y * vector.y) + (vector.z * vector.z))
	return vector3 (vector.x * scale, vector.y * scale, vector.z * scale)
end