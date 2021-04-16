

local npt = _G.NoPixelToolbox
local mySqlObject = {
    byResource = {},
    currentQueries = {},
}

local isSQLReady = false
local noCallback = function()end

--check if the parameters passed are valid
local checkParameters = function(params, callback, resourceName)
    --count amount of calls from each resource
    if (resourceName) then
        mySqlObject.byResource[resourceName] = (mySqlObject.byResource[resourceName] or 0) + 1
    end

    if (not callback) then
        callback = noCallback
    end

    params = params or {}

    return params, callback
end

--check if the sql resource is ready
local checkIfSQLIsReady = function()
    if (isSQLReady) then
        return true
    end

    MySQL.ready(function()
        isSQLReady = true
    end)

    return isSQLReady
end

function npt.IsSQLReady()
    return checkIfSQLIsReady()
end

function npt.SQLExecute(query, params, callback, resourceName)
    if (not checkIfSQLIsReady()) then
        return
    end
    params, callback = checkParameters(params, callback, resourceName)
    MySQL.Async.execute(query, params, callback)
end

function npt.SQLFetch(query, params, callback, resourceName)
    if (not checkIfSQLIsReady()) then
        return
    end
    params, callback = checkParameters(params, callback, resourceName)
    MySQL.Async.fetchAll(query, params, callback)
end

function npt.SQLScalar(query, params, callback, resourceName)
    if (not checkIfSQLIsReady()) then
        return
    end
    params, callback = checkParameters(params, callback, resourceName)
    MySQL.Async.fetchScalar(query, params, callback)
end


function npt.SQLByResources()
    local orderedTable = {}
    for resourceName, amountCalls in pairs (mySqlObject.byResource) do
        orderedTable[#orderedTable+1] = {resourceName, amountCalls}
    end

    table.sort(orderedTable, npt.table.sort2)

    return orderedTable
end