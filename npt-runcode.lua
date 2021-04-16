

--[=[
    /dump (value):
    prints the result of 'any value', examples:
    /dump 25*25 | prints '625'
    /dump print | prints 'function: 0000078A45BEFC1'
    /dump print("hello world") | prints 'Hello world'

    /run (lua code)
    run Lua code without returning values except the values the function it self return, examples:
    /run ClearPedBloodDamage(playerPed)
    /run print("printing this")

--]=]

RegisterCommand ("dump", function(source, ...)

    local lineOfCode = select(2, ...)

    --remove the 'dump' text from the string start
    lineOfCode = select(2, lineOfCode:match("(%w+)(.+)"))
    
    local func = [=[return function()
        return @lineOfCode
    end]=]
    func = func:gsub("@lineOfCode", lineOfCode)

    local compiledCode, errorText = load(func, "Code to Dump: " .. lineOfCode)
    if (compiledCode) then
        local result = compiledCode()
        local results = {result()}

        for i = 1, #results do
            local thisParameter = results[i]

            if (type(thisParameter) ~= "table") then
                print("[" .. i .. "]", thisParameter)
            else
                print(exports["np-toolbox"]:GetNoPixelToolbox().table.dump(thisParameter))
            end
        end
    else
        print("Couldn't compile code:")
        print(errorText)
    end

end)

RegisterCommand ("run", function(source, ...)

    local lineOfCode = select(2, ...)

    --remove the 'run' text from the string start
    lineOfCode = select(2, lineOfCode:match("(%w+)(.+)"))
    
    local func = [=[@lineOfCode]=]
    func = func:gsub("@lineOfCode", lineOfCode)

    local compiledCode, errorText = load(func, "Running Code: " .. lineOfCode)
    if (compiledCode) then
        local result, errorText = pcall(compiledCode)
        if (not result) then
            print(errorText)
        end
    else
        print("Couldn't compile code:")
        print(errorText)
    end

end)