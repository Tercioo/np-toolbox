
--[=[
	Show a simple text in the player screen or in the world
	below is a template with all suppoted entries and their default values
	
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
--]=]


local npt = _G.NoPixelToolbox

local unpack = table.unpack
local tremove = table.remove
local floor = math.floor
local ceil = math.ceil
local type = type
local min = math.min
local max = math.max
local SetTextColour = SetTextColour
local SetTextScale = SetTextScale
local SetTextEntry = SetTextEntry
local AddTextComponentString = AddTextComponentString
local DrawText = DrawText

local CONST_DEFAULT_COLOR = {210, 210, 210, 255}
local CONST_BG_DEFAULT_COLOR = {0, 0, 0, 75}

--text on screen manager main object
local textOnScreenManager = {
	allTextsOnScreen = {},
	
	textPool = {},
	textHandleId = 1,
}

--store all texts shown in the screen
local allTextsOnScreen = textOnScreenManager.allTextsOnScreen

--hash table with text handles as key and the text object as value
local textPool = textOnScreenManager.textPool


--add a text handle into the texts pool and return a handle id
local addToTextPool = function (textObject) --private
	local handleId = textOnScreenManager.textHandleId
	textPool [handleId] = textObject
	textObject.handleId = handleId
	
	--increment the handle id
	textOnScreenManager.textHandleId = handleId + 1
	
	--return the text handle index
	return handleId
end

local removeFromTextPool = function (handleId) --private
	--wipe the table
	local textObject = textPool [handleId]
	npt.table.wipe (textObject)
	
	--mark the handle as non existent
	textPool [handleId] = nil
end


--test if all texts on the screen are disabled
--disables the text if no task is active
local canDisableTextOnScreenTask = function() --private
	if (#allTextsOnScreen < 1) then
		npt.PauseTask (textOnScreenManager.showTextOnScreenTaskHandle)
		return true
	else
		for i = 1, #allTextsOnScreen do
			if (allTextsOnScreen[i].enabled) then
				return false
			end
		end
		
		npt.PauseTask (textOnScreenManager.showTextOnScreenTaskHandle)
		return true
	end
end

--methods added into the table passed with the npt.CreateText
local textOnScreenMethodTable = {

	SetText = function (textObject, newText)
		textObject.text = newText
	end,
	
	Enable = function (textObject)
		if (not textObject.enabled) then
			textObject.enabled = true
			npt.ResumeTask (textOnScreenManager.showTextOnScreenTaskHandle)
			
			if (textObject.fadeInTime) then
				textObject.elapsedTime = 0
				textObject.alphaFadeInValue = max (textObject.alphaFadeOutValue or 0, 1)
				textObject.isFadingIn = true
			end
			
			if (textObject.timeout) then
				textObject.elapsedTime = 0
			end
			
			textObject.isFadingOut = false
		end
	end,
	
	Disable = function (textObject)
		if (textObject.enabled) then
			if (textObject.fadeOutTime) then
				textObject.elapsedTime = 0
				textObject.alphaFadeOutValue = textObject.alphaFadeInValue or textObject.alphaFadeInValue or textObject.color [4]
				textObject.isFadingOut = true
			else
				textObject.enabled = false
			end
			
			textObject.isFadingIn = false
			
			canDisableTextOnScreenTask()
		end
	end,
	
	Delete = function (textObject)
		for i = #allTextsOnScreen, 1, -1 do
			if (allTextsOnScreen [i] == textObject) then
				tremove (allTextsOnScreen, i)
				
				--remove from text pool
				removeFromTextPool (textObject.handleId)
				
				--check if there's no more texts to show
				canDisableTextOnScreenTask()
				return true
			end
		end
	end,
}

--functions to be used to control tasks on other resources
function npt.SetText (textHandle, newText)
	local textObject = textPool [textHandle]
	if (textObject) then
		return textObject:SetText (newText)
	else
		return npt.DebugMessage ("npt.SetText", "task not found for the passed handle", 2)
	end
end

function npt.EnableText (textHandle)
	local textObject = textPool [textHandle]
	if (textObject) then
		return textObject:Enable()
	else
		return npt.DebugMessage ("npt.EnableText", "task not found for the passed handle", 2)
	end
end

function npt.DisableText (textHandle)
	local textObject = textPool [textHandle]
	if (textObject) then
		return textObject:Disable()
	else
		return npt.DebugMessage ("npt.DisableText", "task not found for the passed handle", 2)
	end
end

function npt.DeleteText (textHandle)
	local textObject = textPool [textHandle]
	if (textObject) then
		return textObject:Delete()
	else
		return npt.DebugMessage ("npt.DeleteText", "task not found for the passed handle", 2)
	end
end

local validFonts = {
	[0] = true, --normal font
	[1] = true, --hand written
	[2] = true, --terminal upper case
	[4] = true, --terminal lower case
	[7] = true, --gta font
}

--creates a text on the player screen
function npt.CreateText (textSettingsTable)
	
	--check if the table is valid
	if (type (textSettingsTable) ~= "table") then
		return npt.DebugMessage ("CreateText", "require a table on #1 argument.", 3)
	end
	
	--check if the text is valid
	if (type (textSettingsTable.text) ~= "string") then
		return npt.DebugMessage ("CreateText", "text must be a string.", 3)
	end
	
	--check the enabled state
	if (type (textSettingsTable.enabled) ~= "boolean") then
		textSettingsTable.enabled = true
	end
	
	--type of the text
	textSettingsTable.type = type (textSettingsTable.type) == "string" and string.lower (textSettingsTable.type) or "screen"
	
	--scale
	textSettingsTable.scale = type (textSettingsTable.scale) == "vector2" and textSettingsTable.scale or vector2 (0.3, 0.3)
	
	if (textSettingsTable.type == "screen") then
		textSettingsTable.updateFunc = textOnScreenManager.updateTextOnScreen
		
	elseif (textSettingsTable.type == "world") then
		if (type (textSettingsTable.worldLocation) ~= "vector3") then
			return npt.DebugMessage ("CreateText", "invalid world coordinate for text type 'world', excepted 'vector3' in .worldLocation member.", 3)
		end
		
		textSettingsTable.updateFunc = textOnScreenManager.updateTextOnWorld
		if (type (textSettingsTable.useBackground) == "string" or type (textSettingsTable.useBackground) == "table") then
			textSettingsTable.useBackground = npt.ValidateColor (textSettingsTable.useBackground, CONST_BG_DEFAULT_COLOR)
			
		elseif (textSettingsTable.useBackground) then
		
			--cache the text size
			SetTextScale (textSettingsTable.scale.x, textSettingsTable.scale.y)
			SetTextCentre (true)
			BeginTextCommandWidth ("STRING")
			AddTextComponentString (textSettingsTable.text)
			local height = GetTextScaleHeight (textSettingsTable.scale.x, textSettingsTable.font)
			height = height + height*0.2
			local width = EndTextCommandGetWidth (textSettingsTable.font)
			
			local newColorTable = npt.table.copy ({}, CONST_BG_DEFAULT_COLOR)
			--add the width and height into the background color
			table.insert (newColorTable, 1, height)
			table.insert (newColorTable, 1, width)

			textSettingsTable.rectangleSizeAndColor = newColorTable
		end
		
	else
		return npt.DebugMessage("CreateText", "invalid text type, excepted 'screen' or 'world'.", 3)
	end
	
	--check coordinates
	textSettingsTable.x = type (textSettingsTable.x) == "number" and textSettingsTable.x or 0.2
	textSettingsTable.y = type (textSettingsTable.y) == "number" and textSettingsTable.y or 0.17
	
	--color
	textSettingsTable.color = npt.ValidateColor(textSettingsTable.color, CONST_DEFAULT_COLOR)
	
	--font
	textSettingsTable.font = validFonts [textSettingsTable.font] and textSettingsTable.font or 0
	
	--timeout, divide by 1000 due to deltaTime is returned as a float e.g. 0.016
	textSettingsTable.timeout = type (textSettingsTable.timeout) == "number" and textSettingsTable.timeout or false -- / 1000
	
	--fade
	textSettingsTable.fadeInTime = type (textSettingsTable.fadeInTime) == "number" and textSettingsTable.fadeInTime > 0 and textSettingsTable.fadeInTime or false
	textSettingsTable.fadeOutTime = type (textSettingsTable.fadeOutTime) == "number" and textSettingsTable.fadeOutTime > 0 and textSettingsTable.fadeOutTime or false

	--add all members into the textSettingsTable
	npt.Mixin(textSettingsTable, textOnScreenMethodTable)
	
	--store the text table
	allTextsOnScreen [#allTextsOnScreen + 1] = textSettingsTable
	if (textSettingsTable.enabled) then
		npt.ResumeTask(textOnScreenManager.showTextOnScreenTaskHandle)
	end
	
	--update the text handle ID
	local textHandle = addToTextPool(textSettingsTable)
	
	if (textSettingsTable.enabled) then
		textSettingsTable.enabled = false
		textSettingsTable:Enable()
	end
	
	return textHandle
end


textOnScreenManager.updateTextOnScreen = function (textObject)
	
	SetTextFont (textObject.font)
	
	if (textObject.outline) then
		SetTextOutline()
	end

	if (textObject.isFadingIn) then
		local r, g, b = unpack (textObject.color)
		SetTextColour (r, g, b, floor (textObject.alphaFadeInValue))
		
	elseif (textObject.isFadingOut) then
		local r, g, b = unpack (textObject.color)
		SetTextColour (r, g, b, floor (textObject.alphaFadeOutValue))
		
	else
		SetTextColour (unpack (textObject.color))
	end

	SetTextScale (textObject.scale.x, textObject.scale.y)
	SetTextJustification (0)
	SetTextEntry ("STRING")
	AddTextComponentString (textObject.text)
	DrawText (textObject.x, textObject.y)

end

textOnScreenManager.updateTextOnWorld = function (textObject)

	--draw the text in the world
	local x, y, z = unpack (textObject.worldLocation)
	local isOnScreen, screenX, screenY = GetScreenCoordFromWorldCoord (x, y, z)
	
	if (isOnScreen) then
		SetTextFont (textObject.font)
		
		if (textObject.outline) then
			SetTextOutline()
		end
		
		if (textObject.isFadingIn) then
			local r, g, b = unpack (textObject.color)
			SetTextColour (r, g, b, floor (textObject.alphaFadeInValue))
			
		elseif (textObject.isFadingOut) then
			local r, g, b = unpack (textObject.color)
			SetTextColour (r, g, b, floor (textObject.alphaFadeOutValue))
			
		else
			SetTextColour (unpack (textObject.color))
		end
		
		SetTextScale (textObject.scale, textObject.scale)
		SetTextCentre (true)
		SetTextEntry ("STRING")
		AddTextComponentString (textObject.text)
		EndTextCommandDisplayText (screenX, screenY)
		
		if (textObject.useBackground) then
			local width, height, r, g, b, a = unpack (textObject.rectangleSizeAndColor)
			DrawRect (screenX, screenY + height*.60, width, height, r, g, b, a)
		end
	end
end

--update texts shown in the screen, only runs when at least one text is active
local textOnScreenTaskFunc = function (deltaTime) --private

	for i = #allTextsOnScreen, 1, -1 do
		local textObject = allTextsOnScreen [i]
		
		if (textObject.enabled) then
			local deltaTime = deltaTime * 1000
			
			--check time out, if the text has fadeOut it won't disable it, but instead flag true it's isFadingOut member
			if (textObject.timeout and not textObject.isFadingOut) then
				textObject.elapsedTime = textObject.elapsedTime + deltaTime
				if (textObject.elapsedTime >= textObject.timeout) then
					textObject:Disable()
				end
			end
			
			--check fade in and out
			if (textObject.isFadingIn) then
				local currentAlpha = textObject.alphaFadeInValue
				local fadeInTime = textObject.fadeInTime
				local deltaAlpha = deltaTime / fadeInTime * 255
				textObject.alphaFadeInValue = min (currentAlpha + deltaAlpha, 255)
				
				textObject.updateFunc (textObject)
			
			elseif (textObject.isFadingOut) then
				local currentAlpha = textObject.alphaFadeOutValue
				local fadeOutTime = textObject.fadeOutTime
				local deltaAlpha = deltaTime / fadeOutTime * 255
				textObject.alphaFadeOutValue = max (currentAlpha - deltaAlpha, 0)
			
				if (textObject.alphaFadeOutValue <= 0) then
					textObject.enabled = false
					textObject.isFadingIn = false
					textObject.isFadingOut = false
					textObject.alphaFadeInValue = nil
					textObject.alphaFadeOutValue = nil
		
					SetTextColour (0, 0, 0, 0)
					SetTextScale (textObject.scale)
					SetTextEntry ("STRING")
					AddTextComponentString (textObject.text)
					DrawText (textObject.x, textObject.y)
		
					canDisableTextOnScreenTask()
				else
					textObject.updateFunc (textObject)
				end
			else
				textObject.updateFunc (textObject)
			end
		end
	end
end

--create a task which will run on each tick to update the text
--the task however only is enabled when there's a text to be shown
local taskHandle = npt.CreateTask (textOnScreenTaskFunc, 1, false, false, false, false, "Text On Screen")
npt.PauseTask (taskHandle)
textOnScreenManager.showTextOnScreenTaskHandle = taskHandle



