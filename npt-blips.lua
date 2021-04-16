
local npt = _G.NoPixelToolbox

local floor = math.floor
local lower = string.lower

--[=[
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

--]=]

function npt.CreateBlip (blipType, coords, sprite, displayType, areaSize)

	if (type (blipType) ~= "string") then
		return npt.DebugMessage ("CreateBlip", "require a valid blipType on #1 argument.", 3)
	end
	
	blipType = lower (blipType)

	local blipHandle
	sprite = sprite or 1
	displayType = displayType or 2

	if (blipType == "area") then --area
		--areaSize is a vector2 with the width and height
		local width = areaSize.x
		local height = areaSize.y
		blipHandle = AddBlipForArea (coords.x, coords.y, coords.z, width, height)
		SetBlipDisplay (blipHandle, displayType)
		
	elseif (blipType == "coords") then --coords
		blipHandle = AddBlipForCoord (coords.x, coords.y, coords.z)
		SetBlipSprite (blipHandle, sprite)
		SetBlipDisplay (blipHandle, displayType)
		
	elseif (blipType == "radius") then --radius
		--areaSize is a number with the radius
		local radius = areaSize
		blipHandle = AddBlipForRadius (coords.x, coords.y, coords.z, radius)
		SetBlipDisplay (blipHandle, displayType)
		
	elseif (blipType == "entity") then --entity
		local entity = coords
		blipHandle = AddBlipForEntity (entity)
		SetBlipAsFriendly (blipHandle, true)
		SetBlipSprite (blipHandle, sprite)
		SetBlipDisplay (blipHandle, displayType)
		
	elseif (blipType == "pickup") then --pickup
		local pickup = coords
		blipHandle = AddBlipForPickup (pickup)
		SetBlipSprite (blipHandle, sprite)
		SetBlipDisplay (blipHandle, displayId)
		SetBlipDisplay (blipHandle, displayType)
	
	elseif (blipType == "ai") then
		local aiPed = coords
		local persistant = displayType
		
		SetPedAiBlip (aiPed, true)
		
		if (persistant) then
			IsAiBlipAlwaysShown (aiPed, true)
			SetAiBlipMaxDistance (aiPed, 9999999)
			HideSpecialAbilityLockonOperation (aiPed, false)
			SetAiBlipType (aiPed, sprite) --0 red 1 yellow 2 blue
		end
	end

	return blipHandle
end


function npt.ConfigBlip (blipHandle, settingsTable)
	
	--rotation
	if (settingsTable.rotation and type (settingsTable.rotation) == "number") then
		SetBlipRotation (blipHandle, floor (settingsTable.rotation))
	end
	
	--alpha
	if (settingsTable.alpha and type (settingsTable.alpha) == "number") then
		SetBlipAlpha (blipHandle, floor (settingsTable.alpha))
	end
	
	--bright
	if (type (settingsTable.bright) == "boolean") then
		SetBlipBright (blipHandle, settingsTable.bright)
	end
	
	--color
	if (settingsTable.color and type (settingsTable.color) == "number") then
		SetBlipColour (blipHandle, floor (settingsTable.color))
	end
	
	--scale
	if (settingsTable.scale and type (settingsTable.scale) == "number") then
		SetBlipScale (blipHandle, settingsTable.scale)
	end
	
	--text
	if (type (settingsTable.text) == "string" and settingsTable.text ~= "") then
		BeginTextCommandSetBlipName ("STRING")
		AddTextComponentString (settingsTable.text)
		EndTextCommandSetBlipName (blipHandle)
	end
	
	--flash
	if (settingsTable.flash and type (settingsTable.flash) == "table") then
		local doFade = false
		if (type (settingsTable.flash.flash) == "boolean") then
			SetBlipFlashes (blipHandle, settingsTable.flash.flash) --if it flahes or not
			if (settingsTable.flash.flash) then
				doFlash = true
			end
		end
		
		--?? ignores duration and interval and flash until disabled
		if (type (settingsTable.flash.alternate) == "boolean") then
			SetBlipFlashesAlternate (blipHandle, settingsTable.flash.alternate)
			if (settingsTable.flash.alternate) then
				doFlash = true
			end
		end
		
		--interval of fade in and out in milliseconds
		if (doFlash and settingsTable.flash.interval and type (settingsTable.flash.interval) == "number") then
			SetBlipFlashInterval (blipHandle, floor (settingsTable.flash.interval))
		end
		
		--duration in milisseconds
		if (doFlash and settingsTable.flash.duration and type (settingsTable.flash.duration) == "number") then
			SetBlipFlashTimer (blipHandle, floor (settingsTable.flash.duration))
		end

		--??
		if (type (settingsTable.flash.pulse) == "boolean") then
			PulseBlip (blipHandle)
		end
	end
	
	--category
	if (settingsTable.category and type (settingsTable.category) == "number") then
		SetBlipCategory (blipHandle, settingsTable.category)
	end
	
	--shrink
	if (type (settingsTable.shrink) == "boolean") then
		SetBlipShrink (blipHandle, settingsTable.shrink)
	end
	
	--fade
	if (settingsTable.fade and type (settingsTable.fade) == "table" and settingsTable.fade.fade) then
		SetBlipFade (blipHandle, floor (settingsTable.fade.opacity), floor (settingsTable.fade.duration))
	end
	
end


