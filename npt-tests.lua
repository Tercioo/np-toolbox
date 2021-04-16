

local npt = _G.NoPixelToolbox

-- local pointers
local unpack = table.unpack
local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local gsub = string.gsub

local isVector = npt.isVector
local DrawMarker = DrawMarker


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- blips
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent ("np-toolbox:testCreateBlip")
AddEventHandler ("np-toolbox:testCreateBlip", function (source, args)
	
	local playerPed = GetPlayerPed (-1)
	local loc = GetEntityCoords (playerPed)
	loc = vector3 (loc.x + 0.0, loc.y - 4.0, loc.z + 2.0)
	local blipSprite = 51
	
	--0 hidden, 2 show map and minimap, 3 map only, 5 minimap only, 8 map and minimap (cant select on map)
	local displayType = 2
	
	local areaSize = 50.0 --vector2 (50, 30)
	local blipType = "coords" --"coords" "area" "radius" "entity" "pickup" "ai"
	
	local blipHandle = npt.CreateBlip (blipType, loc, blipSprite, displayType)
	
	local settingsTable = {
		rotation = 0, --integer degrees
		alpha = 255, --integer
		bright = false, --??
		color = 0, --integer
		scale = 1.0, --float
		
		text = "Blip Blap",
		
		shrink = false, --smaller minimap icon when the blip is far away
		
		fade = { --soetimes the first blip added won't fade in
			fade = false, 
			opacity = 100, 
			duration = 2000
		},
		
		flash = {
			flash = false, --flash until disabled if no interval and duration is set
			alternate = false, --? it's ignoring the interval and duration values, flash until disabled
			
			interval = 1000, --how fast the blip hide/show
			duration = 5000, --for how much time it'll be flashing
			
			pulse = false, -- ?
		},
		
		category = 1, --1 2 7 10 11 categories
	}
	
	npt.ConfigBlip (blipHandle, settingsTable)

end)


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- npc
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent ("np-toolbox:testNpc")
AddEventHandler ("np-toolbox:testNpc", function (source, args)
	
	local callBack = function (pedId)
		print ("ped created:", pedId)

		local pedID = NetworkGetNetworkIdFromEntity (pedId)
		local ped = NetworkGetEntityFromNetworkId (pedID)
		npt.SetTimeout (2000, function() DeletePed (pedId) end)
	end
	
	local playerPed = GetPlayerPed (-1)
	local loc = GetEntityCoords (playerPed)
	
	local settingsTable = {
		type = 4,
		hash = 539004493,
		loc = loc,
		heading = 0,
		network = true,
		thisScriptCheck = true,
	}
	
	npt.CreatePedAsync (callBack, settingsTable)
end)


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- other tests
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


RegisterCommand ("vectortest", function(source, args)
	
	local dropCoords = vector3 (150, 250, 400)
	local impactCoords = vector3 (300, 150, 10)
	
	print ("drop - impact: " .. dropCoords - impactCoords)
	print ("#: " .. Vdist2 (dropCoords - impactCoords))
	print ("Vdist: " .. Vdist2 (dropCoords - impactCoords))

	
end)

RegisterCommand ("position", function(source, args)
	local playerPed = GetPlayerPed (-1)
	local loc = GetEntityCoords (playerPed)
	print(loc)
end)
