
local npt = _G.NoPixelToolbox

--local pointers
local pairs = pairs
local TriggerClientEvent = TriggerClientEvent

--player requested to play an animation of a ped for all players connected
RegisterNetEvent ("np-toolbox:sendPlayPedAnimation")
AddEventHandler ("np-toolbox:sendPlayPedAnimation", function (netId, animationDict, animation, blendInSpeed, blendOutSpeed, duration, flag)
    return TriggerClientEvent ("np-toolbox:gotPlayPedAnimation", -1, netId, animationDict, animation, blendInSpeed, blendOutSpeed, duration, flag)
end)

--player requested to play an animation of a ped for players within a region
RegisterNetEvent ("np-toolbox:sendPlayPedAnimationOnRegion")
AddEventHandler ("np-toolbox:sendPlayPedAnimationOnRegion", function (regionName, netId, animationDict, animation, blendInSpeed, blendOutSpeed, duration, flag)
    local playersOnRegion = npt.GetAllPlayersInRegion (regionName)
    if (playersOnRegion) then
        for playerServerId, _ in pairs (playersOnRegion) do
            TriggerClientEvent ("np-toolbox:gotPlayPedAnimation", playerServerId, netId, animationDict, animation, blendInSpeed, blendOutSpeed, duration, flag)
        end
    end
end)
