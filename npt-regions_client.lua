

--[=[
	For documentation open 'documentation.txt' which is located inside the toolbox folder.

	Slash Commands:
	/regiondebug - show info about the grid and which region the player is in
	/regionpaint [size multiplier] - start "paiting" a region while you walk in the world, use the command again to send the template to server console, 'squareSize' is how large the area around you will be painted.
--]=]

local npt = _G.NoPixelToolbox

-- local pointers
local unpack = table.unpack
local tremove = table.remove
local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local gsub = string.gsub

local tinsert = table.insert
local randomseed = math.randomseed
local random = math.random
local GetGameTimer = GetGameTimer
local ipairs = ipairs
local GetActivePlayers = GetActivePlayers

--this is a function, its definition is after the create region stuff
local regionAddedDebug

--settings
--how fast the system checks which region the player is in milliseconds, default 1000
local CONST_CHECK_LOCATION_INTERVAL = 1000

--if the region has .debug = true, this is the amount of time markers will be shown in the ground representing the region area
local CONST_DEBUG_MARKER_TIMEOUT = 10000

--location manager main object
local RegionManager = {
	debugInfo = {}, --store data for region debug
	regionGrid = {},
	regionsPool = {},
	regionCacheByName = {},
	regionHandleId = 1,
	regionSquareSizeRegistered = {},
	backgroundCallback = {}, --hold callback for resources which registered to be informed about background region changes
}

--default settings for painting the region
RegionManager.squareSize = 1

--hash table with region handle as key and the region object as value
local regionsPool = RegionManager.regionsPool

--store grid coordinates information, which X Y coordinates has a region attach to
local regionsGrid = RegionManager.regionGrid

--store different square sizes of all registered regions
local registeredSquareSizes = RegionManager.regionSquareSizeRegistered

--store which regions the player is currently in that already triggered the onEnterFunc
--last zones are added at the end of the table
local regionsPlayerIsWithin = {}


--add a marker handle into the markers pool and return a handle id
local addToRegionPool = function(regionObject)
	local handleId = RegionManager.regionHandleId
	regionsPool[handleId] = regionObject
	regionObject.handleId = handleId

	--increment the handle id
	RegionManager.regionHandleId = handleId + 1

	--return the marker handle index
	return handleId
end


local removeFromRegionPool = function(handleId)
	--wipe the table
	local regionObject = regionsPool [handleId]
	if (regionObject) then
		npt.table.wipe (regionObject)
	end

	--mark the handle as non existent
	regionsPool [handleId] = nil
end

--get the region object by the handle
local getRegionObjectByHandle = function(handleId)
	return regionsPool[handleId]
end

--get the region object by passing a region name
local getRegionObjectByName = function(regionName)
	local regionHandle = RegionManager.regionCacheByName[regionName]
	return getRegionObjectByHandle(regionHandle)
end

--return if a region exists by the region name
function npt.RegionExists(regionName)
	return RegionManager.regionCacheByName[regionName]
end

--return if a ped is inside a region, can pass a region name or a region handle
function npt.IsPedInsideRegion(pedId, regionIdentification)

	--get the region object
	local regionObject = regionsPool[regionIdentification]
	if (not regionObject) then
		regionObject = getRegionObjectByName(regionIdentification)
	end

	if (not pedId) then
		npt.DebugMessage("IsPedInsideRegion():", "invalid ped.", 3)
		return false
	end

	if (not regionObject) then
		npt.DebugMessage("IsPedInsideRegion():", "region not found.", 3)
		return false
	end

	local regionSquareSize = regionObject.squareSize

	local pedCoords = GetEntityCoords(pedId)
	if (pedCoords) then
		local locX = floor(pedCoords.x / regionSquareSize)
		local locY = floor(pedCoords.y / regionSquareSize)
		
		local regions = regionsGrid [locX] and regionsGrid [locX] [locY]
		if (regions) then
			for i = 1, #regions do
				if (regions [i] == regionObject) then
					return true
				end
			end
		end
	end

	return false
end

--query the server if the target player is inside a region, note: use first npt.IsPedInsideRegion (pedId, regionHandle or regionName)
--can be performed only on regions which has .isNetwork = true on its creation table
local callbackPromissesPlayerInRegion = {}

function npt.IsPlayerInsideRegionAsync(playerClientId, regionName, callback)
	if (NetworkIsPlayerActive(playerClientId)) then
		local playerServerId = GetPlayerServerId(playerClientId)
		if (playerServerId) then
			callbackPromissesPlayerInRegion [playerClientId] = callbackPromissesPlayerInRegion [playerClientId] or {}
			callbackPromissesPlayerInRegion [playerClientId] [regionName] = callbackPromissesPlayerInRegion [playerClientId] [regionName] or {}
			tinsert (callbackPromissesPlayerInRegion [playerClientId] [regionName], callback)

			TriggerServerEvent("np-toolbox:queryIsPlayerInsideRegion", playerServerId, regionName)
		end
	end
end


RegisterNetEvent("np-toolbox:answerIsPlayerInsideRegion")
AddEventHandler("np-toolbox:answerIsPlayerInsideRegion", function (playerServerId, regionName, isInside)
	local playerClientId = GetPlayerFromServerId(playerServerId)
	if (playerClientId) then
		local callbackTable = callbackPromissesPlayerInRegion [playerClientId] and callbackPromissesPlayerInRegion [playerClientId] [regionName]

		for i = 1, #callbackTable do
			local result, errorText_returnValue = pcall(callbackTable [i], playerClientId, regionName, isInside)

			if (not result) then
				npt.DebugMessage("np-toolbox:answerIsPlayerInsideRegion: " .. playerClientId, errorText_returnValue, 3)
			end
		end

		--clean up
		npt.table.wipe (callbackTable)
		callbackPromissesPlayerInRegion [playerClientId] [regionName] = nil
		
		if (not next (callbackPromissesPlayerInRegion [playerClientId])) then
			callbackPromissesPlayerInRegion [playerClientId] = nil
		end
	end
end)


--ask the server for all players inside a region and calls back with a table when the query is done
--the region must have 'isNetwork = true'
local callbackPromissesAllPlayersInRegion = {}
function npt.GetAllPlayersInsideRegionAsync(regionName, callback)
	--store callbacks for each region queried
	local regionCallback = callbackPromissesAllPlayersInRegion[regionName]
	if (regionCallback) then
		tinsert(regionCallback, callback)
	else
		regionCallback = {}
		tinsert(regionCallback, callback)
		callbackPromissesAllPlayersInRegion [regionName] = regionCallback
	end
	
	TriggerServerEvent("np-toolbox:queryAllPlayerInsideRegion", regionName)
end


--call the callback function, format:
--for playerServerId, isInside in pairs (playersInside) do print (playerServerId, isInside) end 
RegisterNetEvent("np-toolbox:answerAllPlayerInsideRegion")
AddEventHandler("np-toolbox:answerAllPlayerInsideRegion", function(regionName, playersInside)
	--get callbacks registered for this region
	local regionCallback = callbackPromissesAllPlayersInRegion[regionName]

	if (regionCallback) then
		for i = 1, #regionCallback do
			local result, errorText_returnValue = pcall(regionCallback [i], regionName, playersInside)

			if (not result) then
				npt.DebugMessage("np-toolbox:answerAllPlayerInsideRegion: " .. regionName, errorText_returnValue, 3)
			end
		end

		npt.table.wipe(regionCallback)
	end
end)


--return an indexed table with all pedIds of players inside the region
function npt.GetAllPlayersInRegion(regionNameOrHandle)
	local resultTable = {}
	for _, player in ipairs(GetActivePlayers()) do
		local pedId = GetPlayerPed (player)
		
		if (pedId) then
			local isInside = npt.IsPedInsideRegion(pedId, regionNameOrHandle)
			if (isInside) then
				tinsert(resultTable, pedId)
			end
		end
	end

	return resultTable
end


--return the player location on the grid as vector2 and a scalar for the the height
function npt.GetPlayerLocationOnRegionGrid (squareSize)

	squareSize = squareSize or 1

	--get the player ped
	local playerPed = PlayerPedId()
	
	--player coords
	local v3PlayerPosition = GetEntityCoords (playerPed)
	--check if coords is valid
	if (not v3PlayerPosition) then
		return
	end
	
	local loc = floor (v3PlayerPosition.xy / squareSize) --v3PlayerPosition.xy should return a vector2
	--return vec2GridLocation, v3PlayerPosition.z
	return loc, v3PlayerPosition.z
end

--return a table with player locations for each registered square size, and, a scalar for the height
function npt.GetPlayerCoordsByGridSize()

	local result = {}

	--get the player ped
	local playerPed = PlayerPedId()

	--player coords
	local v3PlayerPosition = GetEntityCoords(playerPed)

	--check if coords is valid
	if (not v3PlayerPosition) then
		return
	end

	for i = 1, #registeredSquareSizes do
		local loc = floor(v3PlayerPosition.xy / registeredSquareSizes[i])
		result[#result + 1] = {loc, registeredSquareSizes[i]}
	end

	return result, v3PlayerPosition.z
end

function npt.GetRegionName(handleId)
	local regionObject = regionsPool[handleId]
	if (regionObject) then
		return regionObject.name
	else
		return ""
	end
end

-- runs the on enter and on leave functions for the region
local execOnEnterFunc = function(regionObject)
	--if is a networked region, tell the server this player entered the region
	if (regionObject.isNetwork) then
		TriggerServerEvent("np-toolbox:tellPlayerEnteredRegion", regionObject.name)
	end

	if (regionObject.regionEnterCallback) then
		--can give error "Missing Bytes" if the resource that registered the region gets restarted or stopped
		local result, errorText_returnValue = pcall(regionObject.regionEnterCallback, regionObject.handleId, unpack(regionObject.payLoad))
		if (not result) then
			npt.DebugMessage("regionEnterCallback: " .. regionObject.name, errorText_returnValue, 3)
		end
	end
end

local execOnLeaveFunc = function(regionObject)
	--if is a networked region, tell the server this player entered the region
	if (regionObject.isNetwork) then
		TriggerServerEvent("np-toolbox:tellPlayerLeftRegion", regionObject.name)
	end
	
	if (regionObject.regionLeaveCallback) then
		--ATTENTION: can give error "Missing Bytes" if the resource that registered the region got restarted or stopped, because this resource is still storing a func reference of a function that got deleted
		local result, errorText_returnValue = pcall(regionObject.regionLeaveCallback, regionObject.handleId, unpack(regionObject.payLoad))
		if (not result) then
			npt.DebugMessage("regionLeaveCallback: " .. regionObject.name, errorText_returnValue, 3)
		end
	end
end


--check the world height and height offset in the regionObject returning if the player is inside the region
local checkRegionHeight = function (regionObject, locationHeight)
	if (not locationHeight) then
		local pedId = PlayerPedId()
		if (pedId) then
			locationHeight = GetEntityCoords (pedId).z
		end
	end

	if (not locationHeight) then
		return 0
	end

	--the terrain height at the region location
	local worldHeight = regionObject.worldHeight
	--the height offset the region accept to be considered 'inside'
	local offsetHeight = regionObject.regionHeight
	
	--get the region min and max accepted height
	local regionHeightMin = worldHeight - offsetHeight
	local regionHeightMax = worldHeight + offsetHeight
	
	if (locationHeight >= regionHeightMin and locationHeight <= regionHeightMax) then
		return true
	end
end


--returns a index table (ipairs) with all region handles that exists at the current player location
--maybe just iterate regions and return the .isInside?
--optional is iterate among all region scales and check the x y
function npt.GetPlayerStandingRegions()
	--player locations for each registered square size
	local playerLocationsOnDifferentGridSizes = npt.GetPlayerCoordsByGridSize()
	
	--check if the location is invalid
	if (not registeredSquareSizes) then
		return
	end
	
	local result = {}

	for locationIndex = 1, #playerLocationsOnDifferentGridSizes do --locations for each square size
		local playerLocation = 	playerLocationsOnDifferentGridSizes [locationIndex] [1] --get the player location vector
		local squareSize = 		playerLocationsOnDifferentGridSizes [locationIndex] [2] --square size of this location

		--get the region objects under the x y player position
		local regionsAtPlayerLocation = regionsGrid [playerLocation.x] and regionsGrid [playerLocation.x] [playerLocation.y]
		
		--check if there's any regions at the current player location
		if (regionsAtPlayerLocation) then
			--there's regions at the current location, iterate among
			for regionTableIndex = 1, #regionsAtPlayerLocation do
				--get the region object for this region and check if the object is valid
				local regionObject = regionsAtPlayerLocation [regionTableIndex]
				if (regionObject) then
					--check if this region square size matches with the square size of the current loop
					if (regionObject.squareSize == squareSize) then
						--check if the player isn't already on this region
						if (regionObject.playerIsIn) then
							tinsert (result, regionObject.handleId)
						end
					end
				end
			end
		end
	end

	return result
end


--check if the player is inside a region, regionIdentification can be the region handle or region name
function npt.IsPlayerInsideRegion(regionIdentification)
	local regionObject = regionsPool [regionIdentification]
	if (regionObject) then
		if (regionObject.playerIsIn) then
			return true
		end
	else
		for handleId, regionObject in pairs (regionsPool) do
			if (regionObject.name == regionIdentification and regionObject.playerIsIn) then
				return true
			end
		end
	end
end

--given a region, check if the player is still inside it
--xy are coords already scaled to squareSize
local checkRegionLeft = function(regionObject, x, y)

	--the player is in this region, check if the player left
	local playerStillInTheRegion = false
	
	local xGrid = regionsGrid [x]
	if (xGrid) then
		local regionsInGridLocation = xGrid [y]
		if (regionsInGridLocation) then
			--iterate among all regions within the current player location (already scaled with the square size)
			for regionIndex = 1, #regionsInGridLocation do
				local region = regionsInGridLocation [regionIndex]
				--if this region is equal to the region passed, the player is still in
				if (region == regionObject) then
					playerStillInTheRegion = true
					break
				end
			end
		end
	end

	if (playerStillInTheRegion) then
		if (not checkRegionHeight(regionObject)) then
			playerStillInTheRegion = false
		end
	end
	
	--the player left the region?
	if (not playerStillInTheRegion) then
		regionObject.playerIsIn = false
		regionsPlayerIsWithin[regionObject] = nil
		
		--trigger onLeaveFunc
		execOnLeaveFunc(regionObject)
	end

end

--check all regions the player is in to know if the player left any of them
--this runs only for regions tagged as 'have player inside'
local checkIfPlayerLeftRegions = function()
	local v3PlayerPosition = GetEntityCoords(PlayerPedId())

	for regionObject, isInside in pairs(regionsPlayerIsWithin) do
		if (regionObject.playerIsIn) then
			local x = floor (v3PlayerPosition.x / regionObject.squareSize)
			local y = floor (v3PlayerPosition.y / regionObject.squareSize)
			checkRegionLeft(regionObject, x, y)
		end
	end
end


--check the regions the player is in
local locationTaskFunc = function(deltaTime)
	--get table with different player coords on each registered grid sizes (square sizes)
	local playerLocationsOnDifferentGridSizes, locationHeight = npt.GetPlayerCoordsByGridSize()
	
	--check if the location is invalid
	if (not registeredSquareSizes) then
		return
	end
	
	for locationIndex = 1, #playerLocationsOnDifferentGridSizes do
		local playerLocation = 	playerLocationsOnDifferentGridSizes [locationIndex] [1] --get the player location vector
		local squareSize = 		playerLocationsOnDifferentGridSizes [locationIndex] [2] --square size of this location
		
		--get the regions under the x y position
		local regionsAtPlayerLocation = regionsGrid [playerLocation.x] and regionsGrid [playerLocation.x] [playerLocation.y]
		
		--check if there's any regions at the current player location
		if (regionsAtPlayerLocation) then
			--there's regions at the current location, iterate among
			for regionTableIndex = 1, #regionsAtPlayerLocation do
				--get the region object for this region and check if the object is valid
				local regionObject = regionsAtPlayerLocation [regionTableIndex]
				if (regionObject) then
					--check if this region square size matches with the square size of the current loop
					if (regionObject.squareSize == squareSize) then
						--check if the player isn't already on this region
						if (not regionObject.playerIsIn) then
							if (checkRegionHeight(regionObject, locationHeight)) then
								--tag player is within this region
								regionObject.playerIsIn = true
								--store the region as the player is in
								regionsPlayerIsWithin [regionObject] = true
								--trigger onEnterFunc
								execOnEnterFunc(regionObject)
							end
						end
					end
				end
			end
		end
	end
	
	--check all regions the player is in if the player left any one of them
	checkIfPlayerLeftRegions()
end


--create a simple task to run the location manager
local checkPlayerRegionTaskHandle = npt.CreateTask(locationTaskFunc, CONST_CHECK_LOCATION_INTERVAL, false, true, false, false, "Location Manager")
RegionManager.checkPlayerRegionTaskHandle = checkPlayerRegionTaskHandle


--[=[
	creates an area location in the grid 
	it runs the regionEnterCallback when the player enters the area
	runs the regionLeaveCallback when the player left the area
--]=]

--regionSettingsTable is stored as a regionObject, when the call is from another resource, a copy of the original table is passed
function npt.CreateRegion(regionSettingsTable)

	--check if enter/leave functions exists and if they are valid functions
	if (regionSettingsTable.regionEnterCallback) then
		npt.CheckFunction(regionSettingsTable.regionEnterCallback, "CreateRegion", "regionEnterCallback")
	end

	if (regionSettingsTable.regionLeaveCallback) then
		npt.CheckFunction(regionSettingsTable.regionLeaveCallback, "CreateRegion", "regionLeaveCallback")
	end

	if (type (regionSettingsTable.isPermanent) ~= "boolean") then
		regionSettingsTable.isPermanent = false
	end

	--set the region id into the region object and store it
	if (not regionSettingsTable.name) then
		randomseed (GetGameTimer())
		regionSettingsTable.name = "UnnamedRegion" .. random (1, 10000000)
	end

	regionSettingsTable.playerIsIn = false

	--payload
	regionSettingsTable.payLoad = type (regionSettingsTable.payLoad) == "table" and regionSettingsTable.payLoad or {}

	--square size
	npt.table.addUnique(registeredSquareSizes, regionSettingsTable.squareSize)

	--check if the painted coords table is valid
	if (type (regionSettingsTable.regionCoords) ~= "table") then
		return
	end

	regionSettingsTable.coordinateType = "painted"
	RegionManager.debugLocations = {} --debug, if enabled

	if (regionSettingsTable.coordinateType == "painted") then

		local coords = regionSettingsTable.regionCoords

		for X, yCoords in pairs (coords) do

			--x coordinate
			local xGrid = regionsGrid[X]
			if (not xGrid) then
				xGrid = {}
				regionsGrid[X] = xGrid
			end

			for index, Y in ipairs (yCoords) do
				--y coordinate
				local yGrid = xGrid[Y]
				if (not yGrid) then
					yGrid = {}
					xGrid[Y] = yGrid
				end

				--store the region in the grid
				yGrid [#yGrid + 1] = regionSettingsTable

				if (regionSettingsTable.debug) then
					local initX = floor (X * regionSettingsTable.squareSize)
					local initY = floor (Y * regionSettingsTable.squareSize)
					local endX = floor ((X+1) * regionSettingsTable.squareSize)
					local endY = floor ((Y+1) * regionSettingsTable.squareSize)
			
					local topLeft = vector2 (initX, initY)
					local bottomLeft = vector2 (initX, endY)
					local topRight = vector2 (endX, initY)
					local bottomRight = vector2 (endX, endY)
			
					npt.realTimeRegionPaintDebug (unpack (topLeft))
					npt.realTimeRegionPaintDebug (unpack (topRight))
					npt.realTimeRegionPaintDebug (unpack (bottomLeft))
					npt.realTimeRegionPaintDebug (unpack (bottomRight))

					--paint the area temporarly
					--tinsert (RegionManager.debugLocations, {X, Y})
				end
			end
		end
		
		--if the region is permanent, erase the pre-computed coordinates table
		if (regionSettingsTable.isPermanent) then
			--wipe since we don't need the original coords in case the region needs to be deleted
			npt.table.wipe (regionSettingsTable.regionCoords)
		end
		
	else
		return npt.DebugMessage ("CreateRegion", "no valid coordinate type.", 3)
	end
	
	--show markers if debug for this region is enabled
	if (regionSettingsTable.debug) then
		regionAddedDebug()
	end
	
	--add the region into the regions created pool
	local regionHandle = addToRegionPool(regionSettingsTable)

	--add to the regions by name cache
	RegionManager.regionCacheByName[regionSettingsTable.name] = regionHandle
	
	--return the handler for this region
	return regionHandle
end

--removes a region from the grid
function npt.DeleteRegion(regionHandle, noOnLeave)

	if (not regionHandle) then
		return npt.DebugMessage("DeleteRegion()", "require a valid region handle on #1 argument.", 3)
	end

	local regionObject = regionsPool [regionHandle]

	--silently quit if the region doesn't exists
	if (not regionObject) then
		return npt.DebugMessage("DeleteRegion()", "invalid region object.", 3)
	end

	if (regionObject.isPermanent) then
		return npt.DebugMessage("DeleteRegion()", "can't delete a permanent region ("..regionObject.name.."), use .isPermanent = false on the region table.", 3)
	end

	if (regionObject.playerIsIn) then
		--argument passed in the function call, if true it won't exec the function when the player leaves the area
		if (not noOnLeave) then
			execOnLeaveFunc(regionObject)
		end

		regionObject.playerIsIn = false
		regionsPlayerIsWithin[regionObject] = nil
	end

	--cleanup the region grid
	if (regionObject.coordinateType == "painted") then
		local coords = regionObject.regionCoords

		for X, yCoords in pairs(coords) do
			for o = 1, #yCoords do
				local Y = yCoords[o]

				local regionsInCoordinate = regionsGrid[X] and regionsGrid[X][Y]
				if (regionsInCoordinate) then
					for i = #regionsInCoordinate, 1, -1 do
						local thisRegion = regionsInCoordinate[i]
						if (regionHandle == thisRegion.handleId) then
							tremove(regionsInCoordinate, i)
							break
						end
					end
				end
			end
		end
	end

	--remove the region from regions by name cache
	RegionManager.regionCacheByName[regionObject.name] = nil

	--remove the region
	removeFromRegionPool(regionObject)
	return true
end


--background regions
--these are default regions which split the map into a 32x32 grid forming 1024 sub regions
--resources can register to know when the player enter and leave these background regions
function npt.RegisterBackgroundAreaCallback(callback)
	RegionManager.backgroundCallback[#RegionManager.backgroundCallback+1] = callback

	--send the first callback at the moment of register
	local currentBackgroundRegionName = npt.GetBackgroundAreaName()
	local regionObject = getRegionObjectByName(currentBackgroundRegionName)
	local okay, errortext = pcall(callback, true, regionObject)
	if (not okay) then
		print("[callback error]:", errortext)
	end

	return true
end

function npt.OnEnterBackgroundArea(regionHandle)
	local regionObject = getRegionObjectByHandle(regionHandle)
	for i = 1, #RegionManager.backgroundCallback do
		pcall(RegionManager.backgroundCallback[i], true, regionObject)
	end
end

function npt.OnLeaveBackgroundArea(regionHandle)
	local regionObject = getRegionObjectByHandle(regionHandle)
	for i = 1, #RegionManager.backgroundCallback do
		pcall(RegionManager.backgroundCallback[i], false, regionObject)
	end
end

function npt.GetBackgroundAreaName()
	--get all regions the player is in
	local standinRegions = npt.GetPlayerStandingRegions()
	for i = 1, #standinRegions do
		local regionObject = getRegionObjectByHandle(standinRegions[i])
		if (regionObject.isBackground) then
			return regionObject.name
		end
	end
end

--convert a regular world coord to square coords
function npt.ScaleWorldCoordsToGridCoords(x, y, squareSize)
	return floor(x / squareSize), floor(y / squareSize)
end

--[=[
	slash command
	/regionpaint <squareSize>
--]=]

local paintingRegion = {}
local regionPaintFunc = function(deltaTime)
	local v3PlayerLocation = GetEntityCoords(paintingRegion.playerPed)

	--draw marker where the player is at the moment in case is flying
	local gotZed, groundZ = GetGroundZFor_3dCoord(v3PlayerLocation.x, v3PlayerLocation.y, v3PlayerLocation.z + 500, 0.0)
	if (gotZed) then
		local distanceFromGround = v3PlayerLocation.z - groundZ

		if (distanceFromGround > 2) then
			local indicatorSize = distanceFromGround * 0.01

			DrawMarker(
				28,
				v3PlayerLocation.x,
				v3PlayerLocation.y,
				groundZ,
				0.0,
				0.0,
				0.0,
				0.0,
				0.0,
				0.0,
				indicatorSize,
				indicatorSize,
				indicatorSize,
				255,
				255,
				255,
				255,
				false,
				false
			)
		end
	end

	local squareSize = RegionManager.squareSize
	local x = floor(v3PlayerLocation.x / squareSize)
	local y = floor(v3PlayerLocation.y / squareSize)

	--get the grid currently being painted
	local xGrid = paintingRegion.locationsAdded[x]

	--check X grid
	if (not xGrid) then
		paintingRegion.locationsAdded[x] = {}
		xGrid = paintingRegion.locationsAdded[x]
	end

	--check Y grid
	local yGrid = xGrid[y]
	if (not yGrid) then
		xGrid[y] = true

		--center coord using scale 1
		local initX = floor(x * squareSize)
		local initY = floor(y * squareSize)
		local endX = floor((x+1) * squareSize)
		local endY = floor((y+1) * squareSize)

		local topLeft = vector2(initX, initY)
		local bottomLeft = vector2(initX, endY)
		local topRight = vector2(endX, initY)
		local bottomRight = vector2(endX, endY)

		npt.realTimeRegionPaintDebug(unpack(topLeft))
		npt.realTimeRegionPaintDebug(unpack(topRight))
		npt.realTimeRegionPaintDebug(unpack(bottomLeft))
		npt.realTimeRegionPaintDebug(unpack(bottomRight))

		--draw a square in the ground indicating the part painted
		local z1 = select (2, GetGroundZFor_3dCoord(initX+0.00001, initY+0.00001, v3PlayerLocation.z + 300.0, 0.0))
		local z2 = select (2, GetGroundZFor_3dCoord(endX+0.00001, endY+0.00001, v3PlayerLocation.z + 300.0, 0.0))

		Citizen.CreateThread(function()
			while (npt.IsTaskRunning (RegionManager.drawActiveTaskHandle)) do
				DrawBox(initX + 0.00001, initY + 0.00001, z1 + 0.1, endX + 0.00001, endY + 0.00001, z2 + 0.2, 255, 0, 0, 50)
				Wait(1)
			end
		end)
	end
end

RegisterNetEvent("np-toolbox:regionPaint")
AddEventHandler("np-toolbox:regionPaint", function (source, args)

	--check if is running, if it is, stop and dump the coords
	if (RegionManager.drawActiveTaskHandle and npt.IsTaskRunning(RegionManager.drawActiveTaskHandle)) then
		npt.PauseTask(RegionManager.drawActiveTaskHandle)

		local playerPed = PlayerPedId()
		local vec3PlayerPosition = GetEntityCoords(playerPed)

		local export = {}

		for xLoc, t in pairs (paintingRegion.locationsAdded) do
			for yLoc, _ in pairs (t) do
				local xLocations = export [xLoc]
				if (not xLocations) then
					xLocations = {}
					export [xLoc] = xLocations
				end
				tinsert(xLocations, yLoc)
			end
		end

		--dump region settings table on server console
		local resultTable = {
			"local regionHandle = npt.CreateRegion ({",
			"name = '-- --',",
			"worldHeight = " .. vec3PlayerPosition.z .. ",",
			"regionHeight = 20,", 
			"isPermanent = true,",
			"debug = false,",
			"isNetwork = false,",
			"regionEnterCallback = function() print ('Entered Region') end,",
			"regionLeaveCallback = function() print ('Left Region') end,",
			"payLoad = {'Hello Region!'},",
			"squareSize = " .. RegionManager.squareSize .. ",",
		}

		TriggerServerEvent("np-toolbox:consoleprint", resultTable)

		resultTable = {}

		--build the coords table
		local coordsResult = {"regionCoords = {"}
		for xLoc, yLocTable in pairs (export) do
			local yString = "[" .. xLoc .. "] = {"
			for i = 1, #yLocTable do
				yString = yString .. "" .. yLocTable[i] .. ", "
			end
			yString = yString .. "},"

			tinsert(coordsResult, yString)
		end

		for i = 1, #coordsResult do
			tinsert(resultTable, coordsResult[i])
		end

		tinsert(resultTable, "}")
		tinsert(resultTable, "})")

		TriggerServerEvent("np-toolbox:consoleprint", resultTable)

		RegionManager.squareSize = 1

		for i = #RegionManager.debugInfo.markers, 1, -1 do
			local markerHandle = RegionManager.debugInfo.markers[i]
			npt.DeleteMarker(markerHandle)
			tremove(RegionManager.debugInfo.markers, i)
		end

		return
	end

	--> start painting
		--how large is the square
		if (args and args [1]) then
			RegionManager.squareSize = floor(tonumber(args[1])) or 1
		else
			RegionManager.squareSize = 1
		end

		if (not RegionManager.drawActiveTaskHandle) then
			--create a task to paint the area
			local regionPaintTaskHandle = npt.CreateTask(regionPaintFunc, 1, false, false, false, false, "Region Painting")
			npt.PauseTask(regionPaintTaskHandle)
			RegionManager.drawActiveTaskHandle = regionPaintTaskHandle
		end
		
		paintingRegion.locationsAdded = {}
		paintingRegion.playerPed = GetPlayerPed(-1)

		npt.ResumeTask(RegionManager.drawActiveTaskHandle)
end)


--show information about the region grid and what region the player is in
RegisterNetEvent("np-toolbox:regionDebug")
AddEventHandler("np-toolbox:regionDebug", function (source, args)
	RegionManager.debugInfo.isDebugging = not RegionManager.debugInfo.isDebugging

	if (RegionManager.debugInfo.isDebugging) then

		if (not RegionManager.debugInfo.debugTexts) then

			RegionManager.debugInfo.debugTexts = {}
			local debugTexts = RegionManager.debugInfo.debugTexts

			local xLocation = .65
			local yLocation = .40

			tinsert(debugTexts, npt.CreateText({text = "", x = xLocation, y = yLocation, name = "xLoc", outline = true}))
			tinsert(debugTexts, npt.CreateText({text = "", x = xLocation, y = yLocation+0.02, name = "sec", outline = true}))
			tinsert(debugTexts, npt.CreateText({text = "", x = xLocation, y = yLocation+0.04, name = "thr", outline = true}))
			tinsert(debugTexts, npt.CreateText({text = "", x = xLocation, y = yLocation+0.06, name = "qua", outline = true}))

			local updateDebugLinesFunc = function (deltaTime)
				local v3PlayerPosition = GetEntityCoords(GetPlayerPed(-1))
				npt.SetText(debugTexts [1], "x: " .. floor (v3PlayerPosition.x))
				npt.SetText(debugTexts [2], "y: " .. floor (v3PlayerPosition.y))
				npt.SetText(debugTexts [3], "heading: " .. floor(GetEntityHeading(PlayerPedId())))

				local regionsIn = ""
				for regionObject, isInside in pairs (regionsPlayerIsWithin) do
					regionsIn = regionsIn .. regionObject.name .. ": " .. (isInside and "inside" or "NOP") .. "\n"
				end

				npt.SetText(debugTexts [4], regionsIn)
			end

			RegionManager.debugInfo.updateDebugLinesTaskHandle = npt.CreateTask(updateDebugLinesFunc, 1, false, true, false, false, "Debug Location Manager")
			npt.PauseTask(RegionManager.debugInfo.updateDebugLinesTaskHandle)
		end

		local debugTexts = RegionManager.debugInfo.debugTexts
		for i = 1, #debugTexts do
			npt.EnableText(debugTexts [i])
		end

		npt.ResumeTask(RegionManager.debugInfo.updateDebugLinesTaskHandle)

	else
		local debugTexts = RegionManager.debugInfo.debugTexts
		for i = 1, #debugTexts do
			npt.DisableText(debugTexts [i])
		end

		npt.PauseTask(RegionManager.debugInfo.updateDebugLinesTaskHandle)
	end
end)

--[=[ --debug on asking the server if a player is inside a region
RegisterCommand ("regionserver", function(source, args)
	local regionName = args [1]
	npt.IsPlayerInsideRegionAsync (PlayerId(), 'Pink Cage NEW')
end)
--]=]

--[=[ --debug ask if a ped is inside a region
RegisterCommand ("regionplayerisinside", function(source, args)
	local regionName = args [1]
	print (npt.IsPedInsideRegion (PlayerPedId(), regionName))
end)

RegisterCommand ("regionplayerisinsideserver", function(source, args)
	npt.IsPlayerInsideRegionAsync (PlayerId(), 'Test squareSize 4', function(playerClientId, regionName, isInside) print (playerClientId, regionName, isInside) end)
end)

RegisterCommand ("regionallplayerisinsideserver", function(source, args)
	npt.GetAllPlayersInsideRegionAsync ('Test squareSize 4', function(regionName, playersInside) 
		if (playersInside) then
			for playerServerId, isInside in pairs (playersInside) do 
				print (playerServerId, isInside) 
			end 
		end
	end)
end)
--]=]

--function declared in the header of the file
--show the region space using markers while debugging
--there's a max of 128 markers in the screen at the same time
regionAddedDebug = function()
	Citizen.CreateThread(function()
		Wait(100)
		
		local allMarkersCreated = {}
		
		for i = 1, #RegionManager.debugLocations do
			local s = RegionManager.debugLocations [i]
			local gridXCoord, gridYCoord = unpack (s)
			
			local v3PlayerPosition = GetEntityCoords(GetPlayerPed(-1))
			local regularCoords = vector2(gridXCoord, gridYCoord)
			local gotCoord, worldHeight = GetGroundZFor_3dCoord(regularCoords.x, regularCoords.y, v3PlayerPosition.z + 300.0, 0.0)
			
			if (gotCoord) then
				worldHeight = worldHeight and worldHeight + 0.3
			else
				worldHeight = v3PlayerPosition.z
			end
			
			local coordinateMarkerPoint = {
				markerType = 0,
				coords = vector3 (regularCoords.x, regularCoords.y, worldHeight),
				forwardDirection = false, --or false to use rotation
				rotation = vector3 (0.0, 180.0, 0.0), --yaw, pitch, roll... if false will use 0, 0, 0
				scale = vector3 (.6, .6, .6), --x, y, z scale
				color = {255, 255, 255, 255}, --can be the color name or a vector4 (r, g, b, a)
				alpha = false, --if alpha is false or nil, it'll use the default value, sometimes this won't work
				bobUpAndDown = false, --the marker animates up and down
				faceCamera = true, --if true, the front of the object is always facing the player
				rotate = 0.0, --if 1 the marker rotates on it's own yaw axis
			}
			
			local markerHandle = npt.CreateMarker(coordinateMarkerPoint)
			tinsert(allMarkersCreated, markerHandle)
			
			Wait(100)
		end
		
		npt.table.wipe(RegionManager.debugLocations)
		
		Wait(CONST_DEBUG_MARKER_TIMEOUT)
		
		for _, markerHandle in ipairs(allMarkersCreated) do
			npt.DeleteMarker(markerHandle)
		end
		
		npt.table.wipe(allMarkersCreated)
	end)
end

--draw markers while the region is being painted
function npt.realTimeRegionPaintDebug(x, y, timeout)
	local v3PlayerPosition = GetEntityCoords(GetPlayerPed(-1))
	local gotCoord, worldHeight = GetGroundZFor_3dCoord(x, y, v3PlayerPosition.z + 300.0, 0.0)

	worldHeight = worldHeight and worldHeight + 0.3
	worldHeight = v3PlayerPosition.z

	local testMarkerObject = {
		markerType = 0, 
		coords = vector3 (x, y, worldHeight or 53.96321),
		forwardDirection = false, --or false to use rotation
		rotation = vector3 (0.0, 180.0, 0.0), --yaw, pitch, roll... if false will use 0, 0, 0
		scale = vector3 (.6, .6, .6), --x, y, z scale
		color = "white", --can be the color name or a vector4 (r, g, b, a)
		alpha = false, --if alpha is false or nil, it'll use the default value, sometimes this won't work
		bobUpAndDown = false, --the marker animates up and down
		faceCamera = true, --if true, the front of the object is always facing the player
		rotate = 0.0, --if 1 the marker rotates on it's own yaw axis
		timeout = timeout or 20000000,
		timeoutDelete = true,
		enabled = true,
	}

	--the marker has a timeout, it'll be delete automatically
	local marker = npt.CreateMarker(testMarkerObject)
	RegionManager.debugInfo.markers = RegionManager.debugInfo.markers or {}
	tinsert (RegionManager.debugInfo.markers, marker)
end

