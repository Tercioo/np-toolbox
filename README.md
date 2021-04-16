# np-toolbox
A set of tools to help on creating other resources



--------------------------------------------------------------------------------------------------------------------------------------------
	General Functions
--------------------------------------------------------------------------------------------------------------------------------------------

functions:
npt.CheckPedExistsAtLocation (x, y, z, radius)
npt.GetClosestPed (...)

local entity = npt.CheckPedExistsAtLocation (x, y, z, radius)
	@x, @y, @z: are the center position
	@radius: how big is the area to search (in meters, e.g. 2.50 equal to 2 and half meters)
	
	Check if there's an entity near the location and return the pedId

local nearestPed, distance = npt.GetClosestPed (...)
	@...: peds, any amount.
	
	Given n peds, calculate which one of them is the nearest to the  player ped

	Example:
	local nearestPed, distance = npt.GetClosestPed (pedId1, pedId2, pedId3, pedId4, pedId5, pedId6, pedId7, etc...)


--------------------------------------------------------------------------------------------------------------------------------------------
	Tasks
--------------------------------------------------------------------------------------------------------------------------------------------

Creates a task (same thing as CreateThread, but with more options
Tasks doesn't support Citizen.Wait in the middle of the code, but can be executed between intervals, paused and resumed
Can run functions from different resources but isn't recommended to run functions from different resources on tick due to the fiveM insane overhead

functions:
npt.CreateTask (callback, interval, loops, priority, isReliable, isRecursive, taskName, ...)
npt.SetTimeout (msec, callback, ...)
npt.PauseTask (taskHandle)
npt.ResumeTask (taskHandle)
npt.CancelTask (taskHandle)
npt.IsTaskPaused (taskHandle): return true if the task is paused
npt.IsTaskCancelled (taskHandle): return true if the task is cancelled
npt.IsTaskRunning (taskHandle): return true if the task is is running (isn't paused or cancelled)
npt.IsTaskLastLoop (taskHandle): return true if the task is on its last loop and is about to be cancelled


local taskHandle = npt.CreateTask (callback, interval, loops, priority, isReliable, isRecursive, taskName, ...)
	@callback: unction to be called when the interval time is done
	@interval: amount of time to wait until the callback is called again
	@loops: how many loops it will do until stop
	@priority: placed in index 1 in the table
	@isReliable: won't use pcall, send deltaTime
	@isRecursive: won't send the taskId or delta time as #1 #2 arguments
	@taskName: name of the task, optional.
	@...: payload
	
The returned value from CreateTask is a handle which can be used with several function to control task flow:
	npt.PauseTask (taskHandle): put the task on hold until resume is called, loop amount isn't affected when the task is paused
	npt.ResumeTask (taskHandle): resume a paused task

	npt.CancelTask (taskHandle): cancel a task, cannot be resumed
	npt.DeleteTask (taskHandle): alias for cancel task
	npt.StopTask (taskHandle): alias for cancel task

	npt.IsTaskPaused (taskHandle): return true if the task is paused
	npt.IsTaskCancelled (taskHandle): return true if the task is cancelled
	npt.IsTaskRunning (taskHandle): return true if the task is is running (isn't paused or cancelled)
	npt.IsTaskLastLoop (taskHandle): return true if the task is on its last loop and is about to be cancelled


local taskHandle = npt.SetTimeout (msec, callback, ...)
Same as the Citizen.SetTimeout, but uses the task system and support payload
	@msec: amount of time to wait until the callback is called again
	@callback: function to be called when the interval time is done
	@... payload: arguments to pass within the callback

	


--------------------------------------------------------------------------------------------------------------------------------------------
	Keybinds
--------------------------------------------------------------------------------------------------------------------------------------------

Register a keybind, calls the callback when the key is pressed

npt.RegisterKeybind (key, callback)
	@key: keybind (A B C,etc)
	@callback: function to call the the key is pressed

npt.DeleteKeybind (key)
	@key: keybind (A B C,etc)


--------------------------------------------------------------------------------------------------------------------------------------------
	Fps Deviation
--------------------------------------------------------------------------------------------------------------------------------------------

Slash Commands:
	/fpsdev

Description:
	Shows the framerate with smooth transition between values and the deviation of the value changed.


--------------------------------------------------------------------------------------------------------------------------------------------
	Regions
--------------------------------------------------------------------------------------------------------------------------------------------

A region system based on 'painting' area technique (doesn't use x > x1 x < x2 etc), supports thousands of location with very low cpu cost.
Creates regions of any size which can run a function when the player enters the region and another when the player leaves.
Regions can be loaded when the client load the map or created at run time if needed.
The term 'Grid' is a table with regular XY locations but only with integers (x = 351.54751 on grid coordinates is just 351).
If a region has .isNetwork, the player notifies the server when enter and leave the region, server side resources can get this information.

functions:

client:
npt.CreateRegion (regionSettingsTable)
npt.RemoveRegion (regionHandle)
npt.GetPlayerLocationOnRegionGrid (squareSize)
npt.GetPlayerStandingRegions()
npt.GetRegionName (regionHandle)
npt.IsPlayerInsideRegion (regionName or regionHandle)
npt.IsPedInsideRegion (pedId, regionName or regionHandle)
npt.GetAllPlayersInRegion (regionNameOrHandle)
npt.RegionExists (regionName)
npt.RegisterBackgroundAreaCallback(callback)
npt.GetBackgroundAreaName()
npt.ScaleCoordsForSquareSize(x, y, squareSize)


server (region must have isNetwork true in the region settings):
npt.IsPlayerInsideRegion(playerServerId, regionName)
npt.GetAllPlayersInRegion(regionName)

local regionHandle = npt.CreateRegion(regionSettingsTable)
	Creates a new area in the region grid. 
	When the player enters the area, it runs a function and another when the player leaves the area.

npt.DeleteRegion (regionHandle, noOnLeave = false)
	Removes a region

local v2GridLocation, floatWorldHeight = npt.GetPlayerLocationOnRegionGrid(gridSize = 1)
	Return the player location on the grid as vector2 and a scalar for the the world height
	
local tableRegionHandles = npt.GetPlayerStandingRegions()
	Return table (ipairs) with handles for all regions that exists in the player current location of a specific squareSize.
	
local regionName = npt.GetRegionName(regionHandle)
	Get the region name
	
local boolIsInside = npt.IsPlayerInsideRegion(regionName or regionHandle)
	Check if the player is inside a region, accept the region name or the region handle
	
client:

local x, y = npt.ScaleCoordsForSquareSize(x, y, squareSize)
	convert a regular world coordination into a grid square coords

local isInside = npt.IsPedInsideRegion(pedId, regionName or regionHandle)
server (server side resources can query if the player is inside a region if that region has been created with .isNetwork = true):
local issInside = npt.IsPlayerInsideRegion (playerServerId, regionName)
	Check if a ped is inside a specific region, accept the region name or the region handle

local playerPedsTable = npt.GetAllPlayersInRegion(regionNameOrHandle)
server (server side resources can query if the player is inside a region if that region has been created with .isNetwork = true):
local playersServerIdsTable = npt.GetAllPlayersInRegion (regionName)
	Get a table with all player peds inside a region

local regionHandle = npt.RegionExists(regionName)
	return a region handle if the region exists

npt.IsPlayerInsideRegionAsync(playerClientId, regionName, callback)
	Query the server if a playerId is inside a region, only works for networked regions

npt.RegisterBackgroundAreaCallback(callback)
	By default there's 1024 region with the size of 1000x1000, these are considered 'background' regions
	Resources can register to know when a player enter or leave any of those regions

npt.GetBackgroundAreaName()
	Get the region name of the current background region the player is in

Server:
local isInside = npt.IsPlayerInsideRegion(playerServerId, regionName)
	For other resources in the server (the region need to be networked)

example:
local callbackIsPlayerInsideFunc = function(playerServerId, regionName, isInside)
	local playerClientId = GetPlayerFromServerId(playerServerId)
	if (isInside) then
		--do something
	end
end
npt.IsPlayerInsideRegionAsync(playerClientId, regionName, callbackIsPlayerInsideFunc)


npt.GetAllPlayersInsideRegionAsync (regionName, callback)
	Query the server for all players inside a region, only works for networked regions
	

example:
local callbackPlayersInsideFunc = function(regionName, playersInside)
	for playerServerId, isInside in pairs(playersInside) do
		local playerClientId = GetPlayerFromServerId(playerServerId)
		--do sothing
	end
end
npt.GetAllPlayersInsideRegionAsync(regionName, callbackPlayersInsideFunc)


Slash Commands:
/regiondebug - show info about the grid and which region the player is in
/regionpaint [float squareSize] - start "paiting" a region while you walk in the world, use the command again to send the template to server consolo, 'squareSize' is how large the area around you will be painted.

After used the commands a table like this is printed in the server console:

{
	name = 'Test Area',
	worldHeight = 54.221775054932,
	regionHeight = 20,
	regionEnterCallback = function() print ('') end,
	regionLeaveCallback = function() print ('') end,
	payLoad = {'caw', 'horse', 'cat'},
	isPermanent = true,
	debug = false,
	isNetwork = true,

	--this show using /regionadd
		coordsTopLeft = vector2 (312.08383178711, -206.82113647461),
		coordsBottomLeft = vector2 (306.89663696289, -231.5192565918),
		coordsTopRight = vector2 (339.6962890625, -217.9861907959),
	
	--this show when using /regionpaint 
		regionCoords = {
			[400] = {-357, -356, -355, -354, -353, },
			[401] = {-357, -356, -355, -354, -353, },
			[397] = {-357, -356, -355, -354, -353, },
			[398] = {-357, -356, -355, -354, -353, },
			[399] = {-357, -356, -355, -354, -353, },
		},
},


--------------------------------------------------------------------------------------------------------------------------------------------
	Create Ped
--------------------------------------------------------------------------------------------------------------------------------------------

functions:
	npt.CreatePedAsync (callback, settingsTable)
	npt.CreatePedAsyncWithNetwork (callback, settingsTable)
	npt.LoadAnimationAsync (callback, animationString)
	npt.SetPedStationary (pedId, netId)
	npt.PlayerGunPointAtPedAsync (callback, playerId, pedId)
	npt.CancelGunPointCheck (checkHandle)
	npt.PlayerGunPointAtPed (playerId, pedId, distance)
	npt.PlayAnimationNetworked (netId, animationDict, animation)
	npt.PlayAnimationOnNetworkRegion (regionName, netId, animationDict, animation)

Description:
	Create and control peds with a few lines of code.

@callback: function to call when the ped is spawned
@settingsTable: a table with the settings for CreatePed()
npt.CreatePedAsync (callback, settingsTable)
	Creates a new ped and call the callback and the ped is ready to be used (wait model load, etc).

Example:
local pedSettings = {
	type = 20,
	hash = -1306051250,
	loc = vector3 (1693.312, 1341.154, 54.4323),
	heading = 90.0,
	network = false,
	thisScriptCheck = false,
}
local myCallback = function(pedId) print ("pedId is: " .. pedId) end
npt.CreatePedAsync (myCallback, pedSettings)


@callback: function to call when the ped is spawned
@settingsTable: a table with the settings for CreatePed()
npt.CreatePedAsyncWithNetwork (callback, settingsTable)
	Creates a new ped, register it to be networked and call the callback when it's all done.
	

Example:
local pedSettings = {
	type = 20,
	hash = -1306051250,
	loc = vector3 (1693.312, 1341.154, 54.4323),
	heading = 90.0,
	network = false,
	thisScriptCheck = false,
}
local myCallback = function(pedId, netId) print ("netId is: " .. netId) end
npt.CreatePedAsyncWithNetwork (myCallback, pedSettings)


@pedId: id of a ped
@netId: netId of a ped
npt.SetPedStationary (pedId, netId)
	Set some settings on the ped  to make it stationary.



@callback: function to call when the animation is done loading
@animationString: animation to load
npt.LoadAnimationAsync (callback, animationString)
	Load an animation, calls the callback whenever the animation is ready to be used.
	
@playerId: a playerId
@pedId: any pedId
@distance: how far can the player be poiting the gun, default 6
local isPointingGun = npt.PlayerGunPointAtPed (playerId, pedId, distance)
	Check if a player is poiting a gun to a pedId
	


@playerId: a playerId
@pedId: any pedId
local checkHandle = npt.PlayerGunPointAtPedAsync (callback, playerId, pedId)
npt.CancelGunPointCheck (checkHandle)
	Check if a player is poiting a gun to a pedId, does more checks than the version above
	Every 500ms it calls the callback function telling if the playerId is poiting the gun to the ped


@netId: netId of a ped
@animationDict: anim dict
@animation: animation within anim dict
npt.PlayAnimationNetworked (netId, animationDict, animation)
	Send the animation to all clients to player on the specific ped
	
@region: region name from the regions system
@netId: netId of a ped
@animationDict: anim dict
@animation: animation within anim dict
npt.PlayAnimationOnNetworkRegion (regionName, netId, animationDict, animation)
	Send the animation to all clients to player on the specific ped
	



--------------------------------------------------------------------------------------------------------------------------------------------
	Screen Text
--------------------------------------------------------------------------------------------------------------------------------------------

Show a simple text in the player screen or in the world
below is a template with all suppoted entries and their default values

Template:
local textHandle = npt.CreateText (
{
	text = "Hello World",
	
	--optional entries including their default values
	x = .2,
	y = .17,
	enabled = true,
	scale = vector2 (.3, .3),
	color = 'silver',
	font = 0,
	outline = false,
	timeout = false,
	fadeInTime = false,
	fadeOutTime = false,
	name = '',
	type = 'screen', --'world'
	useBackground = false, --only for world
})

the returned value from CreateText is a handle which can be used to control the text:

npt.SetText (textHandle, text) - change the default text
npt.EnableText (textHandle) - show the text in case it was disabled
npt.DisableText (textHandle) - disable the text, removing from the screen or from the world
npt.DeleteText (textHandle) - delete the text


--------------------------------------------------------------------------------------------------------------------------------------------
	World Markers
--------------------------------------------------------------------------------------------------------------------------------------------

Create a marker in the world, receives a table with parameters and return a handle id.
timeout: amount in milisseconds to auto hide the marker.
timeoutDelete: when the timeout expires, delete the marker, if deleted it cannot be enabled again.

Template:
local markerHandle = fw.CreateMarker ({
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

npt.EnableMarker (markerHandle)
npt.DisableMarker (markerHandle)
npt.DeleteMarker (markerHandle)


--------------------------------------------------------------------------------------------------------------------------------------------
	Blips
--------------------------------------------------------------------------------------------------------------------------------------------

All in one tool to create blips

local blipHandle = npt.CreateBlip (blipType, wildcard, sprite, displayType, areaSize)
npt.ConfigBlip (blipHandle, settingsTable)

blipType: "coords" "area" "radius" "entity" "pickup"
sprite: https://docs.fivem.net/game-references/blips/

wildcard: vector3 location for coords, area and radius
wildcard: it's an entity for entity
wildcard: it's a pickup for pickup type

displayType: 0 hidden, 2 show map and minimap, 3 map only, 5 minimap only, 8 map and minimap (cant select on map)

areaSize: on "area" is a vector2 where x = width and y = height
areaSize: on "radius" is an integer 0 ... 360

Template:
local blipType = "coords"
local loc = GetEntityCoords (GetPlayerPed (-1))
local blipSprite = 51
local displayType = 2

local blipHandle = npt.AddBlip (blipType, loc, blipSprite, displayType)

local settingsTable = {
	rotation = 0, --integer degrees
	alpha = 255, --integer
	bright = false, --??
	color = 0, --integer
	scale = 1.0, --float
	
	text = "Blip Blap",
	
	shrink = false, --smaller minimap icon when the blip is far away
	
	--sometimes the first blip added won't fade in
	fade = { 
		fade = false,  --is fade enabled?
		opacity = 100, 
		duration = 2000
	},
	
	flash = {
		flash = false, --is flash enabled?

		interval = 1000, --how fast the blip hide/show
		duration = 5000, --for how much time it'll be flashing
		
		alternate = false,
		pulse = false,
	},
	
	category = 1, --1 2 7 10 11 categories
}

npt.ConfigBlip (blipHandle, settingsTable)


--------------------------------------------------------------------------------------------------------------------------------------------
	Colors
--------------------------------------------------------------------------------------------------------------------------------------------

Get a table with the r, g, b values by just giving the name of the color.

Create a new color, require a string with the name of the color and a table with 3 indexes with integers {r, g, b} 0 to 255.
	local colorTable = npt.CreateColor (colorName, table{r, g, b})
	
Get a color by its name, if the color doesn't exists defaultColor will be used, if no defaultColor passed and the colorName doesn't exists, returns nil.
	local colorTable = npt.GetColor (colorName, defaultColor)
	
Similar to GetColor but does more verification, accept a table with rgb values and color name, trow debug messages if invalid color name or table.
	local colorTable = npt.ValidateColor (colorNameOrTable, defaultColor)


--------------------------------------------------------------------------------------------------------------------------------------------
	Run Code
--------------------------------------------------------------------------------------------------------------------------------------------

Slash Commands:
	/dump (value)
	/run (lua code string)

Dump a value or run lua code from the console.

Examples:
    Dump prints the result of 'any value', examples:
    /dump 25*25 | prints '625'
    /dump print | prints 'function: 000101BABABA'
    /dump print("hello world") | prints 'Hello world'

    Run executes a regular line of lua code without returning values except the values the function it self return, examples:
    /run ClearPedBloodDamage(playerPed)
    /run print("printing this")


--------------------------------------------------------------------------------------------------------------------------------------------
	Math
--------------------------------------------------------------------------------------------------------------------------------------------

	npt.FindHeading (vector1, vector2)
	
	
	npt.DotProduct (vector1, vector2)
	
	
	npt.NormalizeVector (vector)
