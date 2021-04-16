
--[=[
	World Markers:
	Create a marker in the world, receives a table with parameters and return a handle id.

	Template:
	local markerHandle = npt.CreateMarker ({
		markerType = integer,
		coords = vector3,
		
		--optional entries including their default values
		forwardDirection = vector3 (0, 0, 0),
		rotation = vector3 (0, 180, 0),
		scale = vector3 (2, 2, 2),
		color = {255, 255, 255, 255},
		yawAnimation = 0,
		enabled = true,
		timeout = false,
		timeoutDelete = false,
	})

	npt.EnableMarker (markerHandle) - show the marker in the world for the player
	npt.DisableMarker (markerHandle) - hide the marker, until :Enable() is called again.
	npt.DeleteMarker (markerHandle) - destroy the marker.
--]=]


local npt = _G.NoPixelToolbox

-- local pointers
local unpack = table.unpack
local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local gsub = string.gsub
local tremove = table.remove

local isVector = npt.isVector
local DrawMarker = DrawMarker

--world indicators main object
local WorldMarkers = {
	markersPool = {},
	markersActive = {},
	markerHandleId = 1,
}

--hash table with marker handles as key and the marker object as value
local markersPool = WorldMarkers.markersPool
--active markers are the markers that the task function will draw in the screen
local activeMarkers = WorldMarkers.markersActive


--world marker default values
local CONST_DEFAULT_COLOR = {255, 255, 255, 255}
local CONST_DEFAULT_SCALE = vector3 (2, 2, 2)
local CONST_DEFAULT_FORWARDDIRECTION = vector3 (0, 0, 0)
local CONST_DEFAULT_ROTATION = vector3 (0, 180, 0)


--add a marker handle into the markers pool and return a handle id
local addToMarkersPool = function (markerObject)
	local handleId = WorldMarkers.markerHandleId
	markersPool [handleId] = markerObject
	markerObject.handleId = handleId
	
	--increment the handle id
	WorldMarkers.markerHandleId = handleId + 1
	
	--return the marker handle index
	return handleId
end

local removeFromMarkersPool = function (handleId)
	--wipe the table
	local markerObject = markersPool [handleId]
	npt.table.wipe (markerObject)
	
	--mark the handle as non existent
	markersPool [handleId] = nil
end

--methods added into the table passed with the npt.CreateMarker
local markersMethodTable = {
	Enable = function (markerObject)
		if (not markerObject.enabled) then
			markerObject.enabled = true
			activeMarkers [#activeMarkers + 1] = markerObject
			
			if (markerObject.timeout) then
				markerObject.elapsedTime = 0
			end
			
			npt.ResumeTask (WorldMarkers.drawActiveTask)
			return true
		end
	end,

	Disable = function (markerObject)
		if (markerObject.enabled) then
			markerObject.enabled = false
			for activeMarkerIndex = #activeMarkers, 1, -1 do
				if (activeMarkers [activeMarkerIndex] == markerObject) then
					tremove (activeMarkers, activeMarkerIndex)
					
					if (#activeMarkers == 0) then
						npt.PauseTask (WorldMarkers.drawActiveTask)
					end
					
					return true
				end
			end
			
			npt.DebugMessage ("markerObject:Disable()", "the marker was enabled but couldn't find it in the activeMarkers table.", 2)
		end
	end,
	
	Delete = function (markerObject)
		if (markerObject.enabled) then
			markerObject:Disable()
		end

		removeFromMarkersPool (markerObject.handleId)

		return true
	end,
}

--enable the marker
function npt.EnableMarker (markerHandle)
	local markerObject = markersPool [markerHandle]
	if (markerObject) then
		return markerObject:Enable()
	else
		return npt.DebugMessage ("npt.EnableMarker", "marker not found for the passed handle", 2)
	end
end

--disable the marker
function npt.DisableMarker (markerHandle)
	local markerObject = markersPool [markerHandle]
	if (markerObject) then
		return markerObject:Disable()
	else
		return npt.DebugMessage ("npt.DisableMarker", "marker not found for the passed handle", 2)
	end
end

--delete marker
function npt.DeleteMarker (markerHandle)
	local markerObject = markersPool [markerHandle]
	if (markerObject) then
		return markerObject:Delete()
	else
		return npt.DebugMessage ("npt.DeleteMarker", "marker not found for the passed handle", 2)
	end
end



--creates a world marker
--markerSettingsTable is stored as a markerObject, when the call is from another resource, a copy of the original table is passed, hence the original table can be recycled to create other markers
function npt.CreateMarker (markerSettingsTable)
	
	--is the markerObject valid?
	if (type (markerSettingsTable) ~= "table") then
		return npt.DebugMessage ("CreateMarker", "require a table as #1 argument.", 3)
	end
	
	--check data
	if (type (markerSettingsTable.markerType) ~= "number") then
		return npt.DebugMessage ("CreateMarker", "require a number on member .markerType.", 3)
	end
	
	if (type (markerSettingsTable.coords) ~= "vector3") then
		return npt.DebugMessage ("CreateMarker", "require a vector3 on member .coords.", 3)
	end
	
	--make default values for missing values
	if (not isVector (markerSettingsTable.forwardDirection)) then
		markerSettingsTable.forwardDirection = CONST_DEFAULT_FORWARDDIRECTION
	end
	if (not isVector (markerSettingsTable.rotation)) then
		markerSettingsTable.rotation = CONST_DEFAULT_ROTATION
	end
	if (not isVector (markerSettingsTable.scale)) then
		markerSettingsTable.scale = CONST_DEFAULT_SCALE
	end
	
	markerSettingsTable.color = npt.ValidateColor (markerSettingsTable.color, CONST_DEFAULT_COLOR)
	
	markerSettingsTable.timeout = type (markerSettingsTable.timeout) == "number" and markerSettingsTable.timeout or false
	markerSettingsTable.timeoutDelete = type (markerSettingsTable.timeoutDelete) == "boolean" and markerSettingsTable.timeoutDelete or false
	
	--other members
	markerSettingsTable.yawAnimation = type (markerSettingsTable.yawAnimation) == "number" and markerSettingsTable.yawAnimation or 0
	
	--check the enabled state
	if (type (markerSettingsTable.enabled) ~= "boolean") then
		markerSettingsTable.enabled = true
	end
	
	npt.Mixin (markerSettingsTable, markersMethodTable)
	
	local buildDrawFunc = [[
	return function()
		return DrawMarker (
			type,
			posX, 
			posY, 
			posZ, 
			dirX, 
			dirY, 
			dirZ, 
			rotX, 
			rotY, 
			rotZ, 
			scaleX, 
			scaleY, 
			scaleZ, 
			red, 
			green, 
			blue, 
			alpha, 
			bobUpAndDown, 
			faceCamera, 
			2, 
			rotate, 
			textureDict, 
			textureName, 
			drawOnEnts
		)
	end
]]

	buildDrawFunc = gsub (buildDrawFunc, "type", markerSettingsTable.markerType)

	buildDrawFunc = gsub (buildDrawFunc, "posX", markerSettingsTable.coords.x)
	buildDrawFunc = gsub (buildDrawFunc, "posY", markerSettingsTable.coords.y)
	buildDrawFunc = gsub (buildDrawFunc, "posZ", markerSettingsTable.coords.z)
	
	buildDrawFunc = gsub (buildDrawFunc, "dirX", markerSettingsTable.forwardDirection.x)
	buildDrawFunc = gsub (buildDrawFunc, "dirY", markerSettingsTable.forwardDirection.y)
	buildDrawFunc = gsub (buildDrawFunc, "dirZ", markerSettingsTable.forwardDirection.z)

	buildDrawFunc = gsub (buildDrawFunc, "rotX", markerSettingsTable.rotation.x)
	buildDrawFunc = gsub (buildDrawFunc, "rotY", markerSettingsTable.rotation.y)
	buildDrawFunc = gsub (buildDrawFunc, "rotZ", markerSettingsTable.rotation.z)
	
	buildDrawFunc = gsub (buildDrawFunc, "scaleX", markerSettingsTable.scale.x)
	buildDrawFunc = gsub (buildDrawFunc, "scaleY", markerSettingsTable.scale.y)
	buildDrawFunc = gsub (buildDrawFunc, "scaleZ", markerSettingsTable.scale.z)
	
	buildDrawFunc = gsub (buildDrawFunc, "red", markerSettingsTable.color[1])
	buildDrawFunc = gsub (buildDrawFunc, "green", markerSettingsTable.color[2])
	buildDrawFunc = gsub (buildDrawFunc, "blue", markerSettingsTable.color[3])
	buildDrawFunc = gsub (buildDrawFunc, "alpha", markerSettingsTable.color[4])
	
	buildDrawFunc = gsub (buildDrawFunc, "bobUpAndDown", markerSettingsTable.bobUpAndDown and "true" or "false")
	buildDrawFunc = gsub (buildDrawFunc, "faceCamera", markerSettingsTable.faceCamera and "true" or "false")
	buildDrawFunc = gsub (buildDrawFunc, "rotate", markerSettingsTable.rotate)
	buildDrawFunc = gsub (buildDrawFunc, "textureDict", "nil")
	buildDrawFunc = gsub (buildDrawFunc, "textureName", "nil")
	buildDrawFunc = gsub (buildDrawFunc, "drawOnEnts", "false")
	
	--extract the function
	local execFunc = load (buildDrawFunc)
	execFunc = execFunc()
	markerSettingsTable.drawFunc = execFunc
	
	if (markerSettingsTable.enabled) then
		markerSettingsTable.enabled = false
		markerSettingsTable:Enable()
	end
	
	--store the marker object and return a marker handle
	local markerHandleId = addToMarkersPool (markerSettingsTable)
	return markerHandleId
end

--task to draw all the enabled world indicators
--this only runs when there's a marker active in the player screen
local drawActiveMarkersTaskFunc = function (deltaTime)
	for markerIndex = #activeMarkers, 1, -1 do
		local markerObject = activeMarkers [markerIndex]
		if (markerObject.timeout) then
			markerObject.elapsedTime = markerObject.elapsedTime + (deltaTime * 1000)
			
			if (markerObject.elapsedTime >= markerObject.timeout) then
				if (markerObject.timeoutDelete) then
					markerObject:Delete()
				else
					markerObject:Disable()
				end
			else
				--draw the marker in the world
				markerObject.drawFunc()
			end
		else
			--draw the marker in the world
			markerObject.drawFunc()
		end
	end
end

--create the task to update the markers each frame
--the task starts paused and it's resumed when a marker is set to enabled
--if no marker is enabled, the task pauses again
local drawActiveWorldMarkersTask = npt.CreateTask (drawActiveMarkersTaskFunc, 1, false, false, false, false, "Draw Active World Markers")
npt.PauseTask (drawActiveWorldMarkersTask)
WorldMarkers.drawActiveTask = drawActiveWorldMarkersTask
