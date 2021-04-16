

local npt = _G.NoPixelToolbox

local floor = math.floor
local lower = string.lower
local unpack = table.unpack

local unpack = table.unpack

local taskId = 0
local cancelledTaskIds = {}

local gunPointTaskId = 0
local gunPointCheckTasks = {}

local createPedObject = {}

function npt.CreatePedAsync (callback, settingsTable, loopTaskId)
	
	if (not loopTaskId) then
		taskId = taskId + 1
		loopTaskId = taskId
	end
	
	if (not HasModelLoaded (settingsTable.hash)) then
	
		--has been cancelled?
		if (cancelledTaskIds [loopTaskId]) then
			return
		end
		
		--wait the model load
		RequestModel (settingsTable.hash)
		return npt.CreateTask (npt.CreatePedAsync, 100, 1, false, false, true, "Create Npc Async", callback, settingsTable, loopTaskId)
		
	else
	
		--has been cancelled?
		if (cancelledTaskIds [loopTaskId]) then
			return
		end
	
		local npcPed = CreatePed (settingsTable.type, settingsTable.hash, settingsTable.loc.x, settingsTable.loc.y, settingsTable.loc.z, settingsTable.heading, settingsTable.network, settingsTable.thisScriptCheck)

		local result, errorText_returnValue = pcall (callback, npcPed, settingsTable.playLoad and unpack (settingsTable.playLoad))
		if (not result) then
			return npt.DebugMessage ("CreatePedAsync", errorText_returnValue, 3)
		end
		
		return loopTaskId
	end
end

function npt.CancelPedAsync (taskId)
	cancelledTaskIds [taskId] = true
end


function createPedObject.onCreatePedAsyncForNetwork (pedId, callback, loopId)

	NetworkRegisterEntityAsNetworked (pedId)

	if (not NetworkGetEntityIsNetworked (pedId) and loopId < 10) then
		if (not loopId) then
			loopId = 1
		else
			loopId = loopId + 1
		end

		NetworkRegisterEntityAsNetworked (pedId)
		return npt.CreateTask (createPedObject.onCreatePedAsyncForNetwork, 100, 1, false, false, true, "Register Ped on Network", pedId, callback, loopId)
	end

	--mission entity, won't work in onesync? saw in the forums
	SetEntityAsMissionEntity (pedId, true, true)

	--get the network id for this ped
	local netId = NetworkGetNetworkIdFromEntity (pedId)
	SetNetworkIdCanMigrate (netId, true)
	SetNetworkIdExistsOnAllMachines (netId, true)

	local result, errorText_returnValue = pcall (callback, pedId, netId)
	if (not result) then
		return npt.DebugMessage ("CreatePedAsyncWithNetwork", errorText_returnValue, 3)
	end
	
end

function npt.CreatePedAsyncWithNetwork (callback, settingsTable)
	if (settingsTable.playLoad) then
		tinsert (settingsTable.playLoad, 1, callback)
	else
		settingsTable.playLoad = {callback}
	end
	
	--request a new npc
	return npt.CreatePedAsync (createPedObject.onCreatePedAsyncForNetwork, settingsTable)
end


function npt.CheckPedNetworkIntegrity (pedId, netId)
	--does the ped exists?
	if (not DoesEntityExist (pedId)) then
		if (not netId or not DoesEntityExist (netId)) then
			return false
		end
	end

	if (IsPedDeadOrDying (pedId)) then
		return false
	end

	--this player has control of the ped?
	--this should be a away loop I believe
	if (not NetworkHasControlOfNetworkId (netId)) then
		NetworkRequestControlOfNetworkId (netId)
	end

	return true
end

function npt.SetPedStationary (pedId, netId)
	if (not npt.CheckPedNetworkIntegrity (pedId, netId)) then
		return
	end
	
	ClearPedTasksImmediately (pedId)
	ClearPedTasks (pedId)
	ClearPedSecondaryTask (pedId)
	SetBlockingOfNonTemporaryEvents (pedId, true)
	SetPedFleeAttributes (pedId, 0, 0)
    SetPedHearingRange (pedId, 0.0)
    SetPedSeeingRange (pedId, 0.0)
	SetPedAlertness (pedId, 0.0)
	SetPedCombatAttributes (pedId, 46, false)
end

local playAnimation = function (pedId, animDict, anim, blendInSpeed, blendOutSpeed, duration, flag)
	blendInSpeed = blendInSpeed or 1.0
	blendOutSpeed = blendOutSpeed or 1.0
	duration = duration or -1
	flag = flag or 1

	ClearPedSecondaryTask (pedId)
	TaskPlayAnim (pedId, animDict, anim, blendInSpeed, blendOutSpeed, duration, flag, 0, 0, 0, 0)
end

function npt.LoadAnimationAsync (callback, animation, ...)
	RequestAnimDict (animation)
	
	if (not HasAnimDictLoaded (animation)) then
		return npt.SetTimeout (100, npt.LoadAnimationAsync, callback, animation, ...)
	end

	callback (...)
end

function npt.LoadAndPlayAnimation (pedId, animDict, anim, blendInSpeed, blendOutSpeed, duration, flag)
	if (not HasAnimDictLoaded (animDict)) then
		npt.LoadAnimationAsync (playAnimation, animDict, pedId, animDict, anim, blendInSpeed, blendOutSpeed, duration, flag)
	else
		playAnimation (pedId, animDict, anim, blendInSpeed, blendOutSpeed, duration, flag)
	end
end

function npt.PlayAnimationNetworked (netId, animationDict, animation, blendInSpeed, blendOutSpeed, duration, flag)
	TriggerServerEvent ("np-toolbox:sendPlayPedAnimation", netId, animationDict, animation)
end

function npt.PlayAnimationOnNetworkRegion (regionName, netId, animationDict, animation, blendInSpeed, blendOutSpeed, duration, flag)
	TriggerServerEvent ("np-toolbox:sendPlayPedAnimationOnRegion", regionName, netId, animationDict, animation, blendInSpeed, blendOutSpeed, duration, flag)
end

--play an animation
RegisterNetEvent ("np-toolbox:gotPlayPedAnimation")
AddEventHandler	("np-toolbox:gotPlayPedAnimation", function (pedNetId, animDict, anim, blendInSpeed, blendOutSpeed, duration, flag)
	local pedId = NetToPed (pedNetId)
	if (DoesEntityExist (pedId)) then
		npt.LoadAndPlayAnimation (pedId, animDict, anim, blendInSpeed, blendOutSpeed, duration, flag)
	end
end)

--expensive check to know if the a playerId is pointing a gun at a pedId
function npt.PlayerGunPointAtPedAsync (callback, playerId, pedId, loopInterval, loopAmount, infoTable)

	if (not infoTable) then
		gunPointTaskId = gunPointTaskId + 1
		local handleId = gunPointTaskId
		infoTable = {
			handleId = handleId,
			loop = 0,
		}
	end

	loopAmount = loopAmount or 999999
	loopInterval = loopInterval or 1000 --milisseconds
	infoTable.loop = infoTable.loop + 1

	if (infoTable.loop > loopAmount) then
		return callback (false, true)
	end

	--if is the first loop:
	--register the handleId
	--schedule the next check for gunpoint
	--return the handle for the original script
	if (infoTable.loop == 1) then
		gunPointCheckTasks [infoTable.handleId] = true
		npt.SetTimeout (loopInterval, npt.PlayerGunPointAtPedAsync, callback, playerId, pedId, loopInterval, loopAmount, infoTable)
		return infoTable.handleId
	end

	if (not gunPointCheckTasks [infoTable.handleId]) then
		return callback (false, true)
	end

	--todo: the callback inside SetTimeout isn't a tail call and will add a stack layer

	local playerPed = GetPlayerPed (playerId)

	--any weapon
	if (not IsPedArmed (playerPed, 7)) then
		callback (false)
		return npt.SetTimeout (loopInterval, npt.PlayerGunPointAtPedAsync, callback, playerId, pedId, loopInterval, loopAmount, infoTable)
	end

	--player is aiming
	if not (IsPlayerFreeAiming (playerId)) then
		callback (false)
		return npt.SetTimeout (loopInterval, npt.PlayerGunPointAtPedAsync, callback, playerId, pedId, loopInterval, loopAmount, infoTable)
	end

	--ped is dead
	if (IsPedDeadOrDying (pedId)) then
		callback (false)
		return npt.SetTimeout (loopInterval, npt.PlayerGunPointAtPedAsync, callback, playerId, pedId, loopInterval, loopAmount, infoTable)
	end

	--is in sight (expensive call)
	if (not HasEntityClearLosToEntityInFront (playerPed, pedId)) then
		callback (false)
		return npt.SetTimeout (loopInterval, npt.PlayerGunPointAtPedAsync, callback, playerId, pedId, loopInterval, loopAmount, infoTable)
	end

	--distance
	if (Vdist2 (GetEntityCoords (playerPed), GetEntityCoords (pedId)) > 6) then
		callback (false)
		return npt.SetTimeout (loopInterval, npt.PlayerGunPointAtPedAsync, callback, playerId, pedId, loopInterval, loopAmount, infoTable)
	end

	callback (true, false, pedId)
	return npt.SetTimeout (loopInterval, npt.PlayerGunPointAtPedAsync, callback, playerId, pedId, loopInterval, loopAmount, infoTable)
end

function npt.CancelGunPointCheck (handleId)
	gunPointCheckTasks [handleId] = nil
end

--quickly check if a player is aiming at a ped
function npt.PlayerGunPointAtPed (playerId, pedId, distance)
	if (IsPlayerFreeAimingAtEntity (playerId, pedId)) then
		local playerPed = GetPlayerPed (playerId)
		if (Vdist2 (GetEntityCoords (playerPed), GetEntityCoords (pedId)) > (distance or 6)) then
			return true
		end
	end
end

