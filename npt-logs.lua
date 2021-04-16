

local npt = _G.NoPixelToolbox

--register a log to logs/resource name/date/logs.log
--@resourceName: the name of the resource
--@actionName: what the resource is doing, eg, creating an item
--@playerId: any identifier to know which player performed the action
--@text: text to log
function npt.LogToFile(resourceName, actionName, playerId, text)
    --data for the folder name inside the resource name folder
    local currentDate = os.date("%Y-%m")
    --time to use as prefix in each log line
    local currentTime = os.date("%Y-%m-%d %H:%M:%S")
    --make the dir
    os.execute("mkdir logs\\" .. resourceName .. "\\" .. currentDate .. "\\")

    --path to file
    local fileName = "logs/" .. resourceName .. "/" .. currentDate .. "/" .. "logs.log"

    --open the log file
    local file = assert(io.open(fileName, "a"))

    --line to log
    local lineToLog = "[" .. currentTime .. "] " .. playerId .. "|" .. actionName .. "|" .. text .. "\n"
    file:write(lineToLog)
    file:close()
end

--get all params passed and create a string separating the values with a vertical bar |
function npt.FormatTextToLog(...)
    local formatedText = ""
	for i = 1, select("#", ...) do
        local text = select(i, ...)
		formatedText = formatedText .. text .. "|"
	end
    formatedText = formatedText:gsub("|$", "")
    return formatedText
end

--[=[ --logs from client
    RegisterNetEvent("np-toolbox:LogToFile")
    AddEventHandler("np-toolbox:LogToFile", function(resourceName, actionName, playerId, text)
        actionName = actionName or "0"
        playerId = playerId or 0
        npt.LogToFile(resourceName, actionName, playerId, text)
    end)
--]=]
