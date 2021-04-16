

--[=[
    server framework
]=]

local npt = _G.NoPixelToolbox

RegisterServerEvent ("np-toolbox:consoleprint")
AddEventHandler ("np-toolbox:consoleprint", function (lines)
	if (IsPlayerAceAllowed (source, _G.nptAce.command)) then
		for i = 1, #lines do
			print (lines [i])
		end
	end
end)

--debug and test commands
RegisterCommand ("testblip", function (source, args)
	if (IsPlayerAceAllowed (source, _G.nptAce.command)) then
		TriggerClientEvent ("np-toolbox:testCreateBlip", source, source, args)
	end
end)

RegisterCommand ("testnpc", function (source, args)
	if (IsPlayerAceAllowed (source, _G.nptAce.command)) then
		TriggerClientEvent ("np-toolbox:testNpc", source, source, args)
	end
end)

RegisterCommand ("loc", function (source, args)
	if (IsPlayerAceAllowed (source, _G.nptAce.command)) then
		TriggerClientEvent ("np-toolbox:debugPlayerLocation", source, source, args)
	end
end)
