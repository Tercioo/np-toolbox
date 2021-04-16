


local npt = _G.NoPixelToolbox
local FramerateDeviation = {}

-- local pointers
local floor = math.floor
local GetFrameTime = GetFrameTime
local tremove = table.remove

--median and deviation do the same calcs but called different due to organization
local medianFpsCache = {}
local medianFpsResult = 0
local medianFpsCacheLimit = 500
local deviationFpsCache = {}
local deviationFpsResult = 0

local isRunning = false
local firstTime = true

local updateFpsFunc = function()
    local frameTime = GetFrameTime()
    local fps = floor (1 / frameTime)
    local fpsDeviation
    medianFpsResult = medianFpsResult + fps

    --amount of frames stored in cache
    local amountFrames = #medianFpsCache

    if (amountFrames > medianFpsCacheLimit) then
        --fps median
        local removedMedianValue = tremove(medianFpsCache, 1)
        medianFpsResult = medianFpsResult - removedMedianValue
        medianFpsCache[amountFrames] = fps

        --fps deviation
            --remove
                local removedDeviationValue = tremove(deviationFpsCache, 1)
                deviationFpsResult = deviationFpsResult - removedDeviationValue
            --add
                fpsDeviation = floor(medianFpsResult / amountFrames)
                deviationFpsResult = deviationFpsResult + fpsDeviation
                deviationFpsCache[amountFrames] = fpsDeviation

    else
        --add fps median
        medianFpsCache[amountFrames+1] = fps

        --add fps deviation
        fpsDeviation = floor(fps / #medianFpsCache)
        deviationFpsCache[amountFrames+1] = fpsDeviation
        deviationFpsResult = deviationFpsResult + fpsDeviation
    end

    local currentFps = floor(medianFpsResult / amountFrames)
    local currentDeviation = floor(deviationFpsResult / amountFrames) - currentFps
    currentDeviation = currentDeviation * -1

    npt.SetText(FramerateDeviation.fpsTextHandle, "FPS: " .. currentFps .. "\nCHANGE: " .. currentDeviation)
end

RegisterCommand ("fpsdev", function(source, ...)
    isRunning = not isRunning

    if (isRunning) then
        if (firstTime) then
            firstTime = true
            local updateFpsTaskHandle = npt.CreateTask(updateFpsFunc, 0, false, false, false, false, "Fps Deviation Updater")
            FramerateDeviation.updateFpsTaskHandle = updateFpsTaskHandle

            local textSettings = {
                text = "Hello World",
                x = 0.25,
                y = 0.41,
                enabled = true,
                scale = vector2(.5, .5),
                color = 'white',
                outline = true,
                name = 'Frame Rate Deviation Text',
            }

            FramerateDeviation.fpsTextHandle = npt.CreateText(textSettings)
        end
    else
        npt.PauseTask(FramerateDeviation.updateFpsTaskHandle)
        FramerateDeviation.fpsTextHandle:Disable()
    end
end)

