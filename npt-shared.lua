

local npt = _G.NoPixelToolbox


--local pointers
local Wait = Wait
local floor = math.floor
local type = type
local unpack = table.unpack
local pairs = pairs
local ipairs = ipairs
local match = string.match
local upper = string.upper
local tinsert = table.insert
local tremove = table.remove
local Vdist2 = Vdist2
local PlayerPedId = PlayerPedId
local GetPlayerPed = GetPlayerPed
local GetFrameTime = GetFrameTime or function() return 0 end
local GetGameTimer = GetGameTimer
local GetUtcTime = GetUtcTime
local GetActivePlayers = GetActivePlayers
local GetEntityCoords = GetEntityCoords
local StartShapeTestCapsule = StartShapeTestCapsule
local GetShapeTestResult = GetShapeTestResult

local IsPlayerDead = IsPlayerDead

---------------------------------------------------------------
--variable checker
---------------------------------------------------------------

npt.isVector = function (value)
	return type (value) == "vector2" or type (value) == "vector3" or type (value) == "vector4"
end

--check if the function is a regular function or a function reference
--return true if is a function or reference of a function
function npt.CheckFunction (func, funcName, funcLocation)
	
	funcName = funcName or "unnamed function"

	if (type (funcLocation) == "string") then
		funcLocation = "on ." .. funcLocation .. " member."
	else
		funcLocation = funcLocation or 1
		funcLocation = "as #" .. funcLocation .. " argument."
	end
	
	local funcType = type (func)
	
	if (funcType ~= "function" and funcType ~= "table") then
		assert (funcType == "function" and funcType == "table", funcName .. " require a function or functionRef " .. funcLocation)
		
	elseif (funcType == "table") then
		assert (type (func.__cfx_functionReference) == "string", funcName .. " require a function or functionRef " .. funcLocation)
	end
	
	return true
end


---------------------------------------------------------------
--	table functions
---------------------------------------------------------------

npt.table = {}

--wipe table
function npt.table.wipe (t)
	for i = #t, 1, -1 do
		tremove (t, i)
	end
	
	for key, _ in pairs (t) do
		t [key] = nil
	end
end

--find the index of an object within an index table
--need 't' as a table and 'value' as any object in lua
function npt.table.find (t, value)
	for i = 1, #t do
		if (t[i] == value) then
			return i
		end
	end
end

--add a unique object into the table, if the object already exists, won't add anything
function npt.table.addUnique (t, index, value)
	if (not value) then
		--if the value is nil, it means the call was addUnique (table, value)
		--the value will be added at the end of the table using this way
		value = index
		index = #t + 1
	end

	for i = 1, #t do
		if (t[i] == value) then
			return false
		end
	end
	
	tinsert (t, index, value)
	return true
end

function npt.table.removeValue (t, value)
	for i = #t, 1, -1 do
		if (t[i] == value) then
			tremove (t, i)
			return true
		end
	end
end

--create a new table adding all the objects in 't' in the reverse order
function npt.table.reverse (t)
	local new = {}
	local index = 1
	for i = #t, 1, -1 do
		new [index] = t[i]
		index = index + 1
	end
	return new
end

--copy from table2 to table1 overwriting values
function npt.table.copy (t1, t2)
	for key, value in pairs (t2) do 
		if (key ~= "__index") then
			if (type (value) == "table") then
				t1 [key] = t1 [key] or {}
				npt.table.copy (t1 [key], t2 [key])
			else
				t1 [key] = value
			end
		end
	end
	return t1
end

--copy values that does exist on table2 but not on table1
function npt.table.deploy (t1, t2)
	for key, value in pairs (t2) do 
		if (type (value) == "table") then
			t1 [key] = t1 [key] or {}
			npt.table.deploy (t1 [key], t2 [key])
		elseif (t1 [key] == nil) then
			t1 [key] = value
		end
	end
	return t1
end

--convert the table to a string text showing it's values
-- t is the table do dump to text
-- s is the textm is nil it'll create an empty string
-- deep is for recursive calls
function npt.table.dump (t, s, deep)

	s = s or ""
	deep = deep or 0
	local space = ""
	for i = 1, deep do
		space = space .. "   "
	end
	
	if (type (t) ~= "table") then
		if (not t) then
			return "nil"
		else
			return t
		end
	end
	
	for key, value in pairs (t) do
		local tpe = type (value)
		
		if (type (key) == "function") then
			key = "#function#"
		elseif (type (key) == "table") then
			key = "#table#"
		end	
		
		if (type (key) ~= "string" and type (key) ~= "number") then
			key = "unknown?"
		end
		
		if (tpe == "table") then
			if (type (key) == "number") then
				s = s .. space .. "[" .. key .. "] =  {\n"
			else
				s = s .. space .. "[\"" .. key .. "\"] =  {\n"
			end
			s = s .. npt.table.dump (value, nil, deep+1)
			s = s .. space .. "},\n"
			
		elseif (tpe == "vector2") then
			s = s .. space .. "[\"" .. key .. "\"] = vector2 (" .. value.x .. ", " .. value.y .. "),\n"
			
		elseif (tpe == "vector3") then
			s = s .. space .. "[\"" .. key .. "\"] = vector3 (" .. value.x .. ", " .. value.y .. ", " .. value.z .. "),\n"	
			
		elseif (tpe == "vector3") then
			s = s .. space .. "[\"" .. key .. "\"] = vector3 (" .. value.x .. ", " .. value.y .. ", " .. value.z .. ", " .. value.w .. "),\n"
		
		elseif (tpe == "string") then
			s = s .. space .. "[\"" .. key .. "\"] = \"" .. value .. "\",\n"
			
		elseif (tpe == "number") then
			s = s .. space .. "[\"" .. key .. "\"] = " .. value .. ",\n"
			
		elseif (tpe == "function") then
			s = s .. space .. "[\"" .. key .. "\"] = function()end,\n"
			
		elseif (tpe == "boolean") then
			s = s .. space .. "[\"" .. key .. "\"] = " .. (value and "true" or "false") .. ",\n"
		end
	end
	
	return s
end


--sort function to use with table.sort, ascending and descending orders
function npt.table.sort1 (t1, t2)
	return t1[1] > t2[1]
end

function npt.table.sort2 (t1, t2)
	return t1[2] > t2[2]
end

function npt.table.sort3 (t1, t2)
	return t1[3] > t2[3]
end

function npt.table.sort1R (t1, t2)
	return t1[1] < t2[1]
end

function npt.table.sort2R (t1, t2)
	return t1[2] < t2[2]
end

function npt.table.sort3R (t1, t2)
	return t1[3] < t2[3]
end


---------------------------------------------------------------
--general functions
---------------------------------------------------------------

--convert a number 10054871 to string 10.054.871
function npt.CommaValue (number)
	if (not number) then 
		return "0" 
	end
	
	number = floor (number)
	
	if (number == 0) then
		return "0"
	end
	
	--source http://richard.warburton.it
	local left, num, right = match (number, '^([^%d]*%d)(%d*)(.-)$')
	return left .. (num:reverse():gsub ('(%d%d%d)','%1,'):reverse()) .. right
end

--convert a number to time value string, 700 to 11:40
function npt.NumberToTime (number)
	return "" .. floor (number / 60) .. ":" .. format ("%02.f", number % 60)
end

--remove spaces in the from and back of a text
function npt.Trim (str)
	local from = str:match"^%s*()"
	return from > #str and "" or str:match (".*%S", from)
end

--some alias
function npt.GetDeltaTime() --alias
	return GetFrameTime()
end

--get the current game time
function npt.GetTime() --alias
	return GetGameTimer()
end


--add method and members from a table into an object
function npt.Mixin (objectToReceiveValues, ...)
	for i = 1, select ("#", ...) do
		local mixin = select (i, ...)

		--iterate on passed values and add them into the object
		for key, value in pairs (mixin) do
			objectToReceiveValues [key] = value
		end
	end

	return objectToReceiveValues
end

--given n peds, calculate which one of them is the nearest to the  player ped
function npt.GetClosestPed(...)
	local playerPed = PlayerPedId()
	local playerLoc = GetEntityCoords (playerPed)
	local nearestPed = {pedId = 0, distance = 999999}

	for i = 1, select ("#", ...) do
		local pedId = select (i, ...)
		local distance = Vdist2 (playerLoc, GetEntityCoords (pedId))
		if (distance < nearestPed.distance) then
			nearestPed.pedId = pedId
			nearestPed.distance = distance
		end
	end

	return nearestPed.pedId, nearestPed.distance
end

--cast a ray from the camera hitting what is in the middle of the screen
--https://forum.cfx.re/t/get-camera-coordinates/183555/14
function npt.CastRayFromCamera(distance)
	distance = distance or 3000.0

	--local _, forwardVector, _, position = GetCamMatrix(GetRenderingCam())

	local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()

	local adjustedRotation = {
		x = (math.pi / 180) * cameraRotation.x,
		y = (math.pi / 180) * cameraRotation.y,
		z = (math.pi / 180) * cameraRotation.z
	}
	local direction = {
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}

	local destination = {
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}

	return GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, -1, 1))
end

--check if there's an entity near the location and return the pedId
--x, y, z is the center position
--radius is in meters, e.g. 2.50 equal to 2m 50cm
function npt.CheckPedExistsAtLocation (x, y, z, radius)
	radius = radius or 55.0
	local rayHandle = StartShapeTestCapsule (x, y, z-2.0, x, y, z+2.0, radius, 12, GetPlayerPed (-1), 7)
	local _, hit, _, _, entityHit = GetShapeTestResult (rayHandle)
	return hit and hit ~= 0 and entityHit
end

--return the nearest player from a coordinate
function npt.GetNearestDeadPlayerFromCoords (coords)
	local nearestDeadPlayer = {playerId = 0, distance = 999999}

	for _, player in ipairs (GetActivePlayers()) do
		if (IsPlayerDead (PlayerId())) then --@no-pixel
			local playerPedId = GetPlayerPed (player)

			local distance = Vdist2 (coords, GetEntityCoords (playerPedId))
			if (distance < nearestDeadPlayer.distance) then
				nearestDeadPlayer.playerId = player
				nearestDeadPlayer.distance = distance
			end
		end
	end

	return nearestDeadPlayer.playerId, nearestDeadPlayer.distance
end

