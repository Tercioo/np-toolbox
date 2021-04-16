

local npt = _G.NoPixelToolbox

local _DEBUG = true

--print in the server console the location of the player
RegisterNetEvent ("np-toolbox:debugPlayerLocation")
AddEventHandler ("np-toolbox:debugPlayerLocation", function (source, args)
	local playerPed = GetPlayerPed (-1)
	local loc = GetEntityCoords (playerPed)
	
	TriggerServerEvent ("np-toolbox:consoleprint", {loc})
end)

function npt.Chat (...)
	TriggerEvent ("chat:addMessage", {
		args = {...},
	})
end

---------------------------------------------------------------
-- Debug
---------------------------------------------------------------

function npt.DebugMessage (resourceName, message, criticLevel)
	
	criticLevel = criticLevel or 1
	
	if (not message or type(message) ~= "string") then
		return false
	end
	
	if (_DEBUG) then
		if (criticLevel == 3) then
			--print ("[ERROR: " .. resourceName .. "] " .. message .. " | " .. debug.traceback (nil, 2))
			print ("[^1ERROR: " .. resourceName .. "^0] ^1" .. message .. "^0 | ^1" .. debug.traceback (nil, 2) .. "^0")
			print ("^1--------------------------------------------------------------")
			
		elseif (criticLevel == 2) then
			print ("[WARNING: " .. resourceName .. "] " .. message)
		
		elseif (criticLevel == 1) then
			print ("[" .. resourceName .. "] " .. message)
		
		end
	
	end
end


local debugTextHandle, debugTaskHandle, debugObject
function npt.Debug (wildCard)
	debugObject = wildCard
	
	if (not debugTextHandle) then
		local text = npt.table.dump (debugObject)

		local taskFunc = function (taskHandle)
			npt.SetText (debugTextHandle, text)
		end
	
		debugTextHandle = npt.CreateText ({text = "??", x = .6, y = .35, name = "realTimeDebugMessage", outline = true})
		debugTaskHandle = npt.CreateTask (taskFunc, 1, false, true, false, false, "Debug Text Anything")
	end
end
