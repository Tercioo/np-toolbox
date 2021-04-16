

--[=[
	Regions with member .isNetwork calls the server when the player enter/leave that region
--]=]

local npt = _G.NoPixelToolbox

--local pointers
local tonumber = tonumber
local TriggerClientEvent = TriggerClientEvent

npt.serverRegionManager = {
	regionCache = {},
	playerCache = {},
}

local regionCache = npt.serverRegionManager.regionCache
local playerCache = npt.serverRegionManager.playerCache

--client informed the player entered a region, store the player into a region cache
local addPlayerToRegionCache = function(regionName, playerServerId)

	--all players inside the region
	local playersInsideRegion

	--check if the zone exists in the server and add to region cache
	if (not regionCache[regionName]) then
		playersInsideRegion = {}
		regionCache[regionName] = playersInsideRegion
	else
		playersInsideRegion = regionCache[regionName]
	end

	--add to player cache
	playerCache[playerServerId] = regionName

	--add the player in the region table, now the server know that this player is inside this region
	playersInsideRegion [playerServerId] = true
end

--client informed the player left a region, remove the player from the region cache
local removePlayerFromRegionCache = function(regionName, playerServerId)
	--remove from region cache
	if (regionCache [regionName]) then
		regionCache [regionName] [playerServerId] = nil
	end

	--remove from player cache
	playerCache[playerServerId] = nil
end

--RPCs
--when the client enters a new region, it informs the server about the region it just entered
RegisterNetEvent("np-toolbox:tellPlayerEnteredRegion")
AddEventHandler("np-toolbox:tellPlayerEnteredRegion", function(regionName)
	local playerServerId = tonumber(source)
	return addPlayerToRegionCache(regionName, playerServerId)
end)

--when the client leaves a region, it informs the server about the region it just left
RegisterNetEvent("np-toolbox:tellPlayerLeftRegion")
AddEventHandler("np-toolbox:tellPlayerLeftRegion", function(regionName)
	local playerServerId = tonumber(source)
	return removePlayerFromRegionCache(regionName, playerServerId)
end)

--player disconnect, remove the player from all regions
AddEventHandler("playerDropped", function()
	local serverIdDropped = tonumber(source)
	local playerRegion = playerCache[serverIdDropped]
	if (playerRegion) then
		return removePlayerFromRegionCache(playerRegion, serverIdDropped)
	end
end)

--server-side is player inside region
function npt.IsPlayerInsideRegion(playerServerId, regionName)
	playerServerId = tonumber (playerServerId)

	if (not regionCache [regionName]) then
		return false

	elseif (regionCache [regionName] [playerServerId]) then
		return true

	else
		return false
	end
end

--request all players inside a region
--returns a table: {[playerServerId] = true}
function npt.GetAllPlayersInRegion(regionName)
	return regionCache[regionName] or {}
end

--client queries
local sendAnswer = function(source, playerServerId, regionName, isInside)
	return TriggerClientEvent("np-toolbox:answerIsPlayerInsideRegion", source, playerServerId, regionName, isInside)
end

--a client is asking if a player is inside a specific region
RegisterNetEvent("np-toolbox:queryIsPlayerInsideRegion")
AddEventHandler("np-toolbox:queryIsPlayerInsideRegion", function(playerServerId, regionName)

	playerServerId = tonumber(playerServerId)

	if (not regionCache [regionName]) then
		return sendAnswer(source, playerServerId, regionName, false)
	
	elseif (regionCache [regionName] [playerServerId]) then
		return sendAnswer(source, playerServerId, regionName, true)
		
	else
		return sendAnswer(source, playerServerId, regionName, false)
	end
	
end)

--client asking for all players inside a region
RegisterNetEvent("np-toolbox:queryAllPlayerInsideRegion")
AddEventHandler("np-toolbox:queryAllPlayerInsideRegion", function (regionName)
	return TriggerClientEvent("np-toolbox:answerAllPlayerInsideRegion", source, regionName, regionCache [regionName] or false)
end)

----------------------------------------
--> commands

RegisterCommand("regiondebug", function(source, args)
	if (IsPlayerAceAllowed(source, _G.nptAce.command)) then
		TriggerClientEvent("np-toolbox:regionDebug", source, source, args)
	end
end)

RegisterCommand("regionpaint", function(source, args)
	if (IsPlayerAceAllowed(source, _G.nptAce.command)) then
		TriggerClientEvent("np-toolbox:regionPaint", source, source, args)
	end
end)

