

local npt = _G.NoPixelToolbox

--default regions loaded when the player logs in
local defaultRegions = {
	{
		name = 'Test squareSize 4',
		worldHeight = 44.84351348877,
		regionHeight = 20,
		isPermanent = true,
		debug = 1,
		isNetwork = true,
		regionEnterCallback = function() print ('ENTER test square 4') end,
		regionLeaveCallback = function() print ('LEFT test square 4') end,
		payLoad = {'caw', 'horse', 'cat'},
		squareSize = 1,
		regionCoords = {
			[276] = {-336, },
		}
	}
}

--'install' default regions into the region manager
for i = 1, #defaultRegions do
	--get the region from the default regions table
	local region = defaultRegions [i]
	--add the location
	local r = npt.CreateRegion (region)

	--debug: delete regions
	--npt.SetTimeout (3000, function()
		--print ("removing region:", r)
		--npt.DeleteRegion (r)
	--end)
end

--divide the map into 1024 pieces of 1 kilometer square
--this support background sub division of the map for resources
--regions here does not count Z axis
for i = -16, 16 do
	for o = -16, 16 do
		local newRegion = {
			name = "background" .. i .. "" .. o,
			worldHeight = 0,
			regionHeight = 65536,
			isPermanent = true,
			regionEnterCallback = npt.OnEnterBackgroundArea,
			regionLeaveCallback = npt.OnLeaveBackgroundArea,
			squareSize = 1024,
			regionCoords = {[i] = {o}},
			isBackground = true,
			isNetwork = true,
		}
		npt.CreateRegion(newRegion)
	end
end
