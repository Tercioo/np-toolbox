
--[=[
	TASK
	Creates a new task, which has the advantage of not creating new "threads" (CreateThread) reducing the overhead necessary to execute a function
	Tasks has the disadvantage of not supporting Citizen.Wait in the middle of the code, but can be executed between intervals
	
	local taskHandle = npt.CreateTask (callback, interval, loops, priority, isReliable, isRecursive, taskName, ...)
	
	callback: function to be called when the interval time is done
	interval: amount of time to wait until the callback is called again
	loops: how many times the task will be executed (respecting the interval), if loop is false it'll run until npc.CancelTask is called
	priority: if priority is true, the task will be added in the first index of the task table
	taskName: optional, a name for the task
	isReliable: won't use pcall when calling the callback
	isRecursive: won't pass the task object before the payload, also recursive is always reliable
	... payload: arguments to pass within the callback
	
	
	The returned value from CreateTask is a handle which can be used on several function to control the task if needed:
	
	npt.PauseTask (taskHandle): put the task on hold until resume is called, loop amount isn't affected when the task is paused
	npt.ResumeTask (taskHandle): resume a paused task
	
	npt.CancelTask (taskHandle): cancel a task, cannot be resumed
	npt.DeleteTask (taskHandle) --alias for cancel task
	npt.StopTask (taskHandle) --alias for cancel task
	
	npt.IsTaskPaused (taskHandle): return true if the task is paused
	npt.IsTaskCancelled (taskHandle): return true if the task is cancelled
	npt.IsTaskRunning (taskHandle): return true if the task is is running (isn't paused or cancelled)
	npt.IsTaskLastLoop (taskHandle): return true if the task is on its last loop and is about to be cancelled
	
	local taskHandle = npt.SetTimeout (msec, callback, ...)
	this is the same as the Citizen.SetTimeout, but uses a task instead of creating a new coroutine
	
	msec: amount of time to wait until the callback is called again
	callback: function to be called when the interval time is done
	... payload: arguments to pass within the callback
	
	
	KEYBIND
	Register a keybind, calls the callback when the key is pressed
	npt.RegisterKeybind (key, callback)
	npt.DeleteKeybind (key)
	npt.RemoveKeybind (key) --alias

--]=]



local npt = _G.NoPixelToolbox

local STRING = "string"
local _DEBUG = false

local CONST_TASK_CLEANUP_INTERVAL_TIME = 5000


--local pointers
local Wait = Wait
local type = type
local unpack = table.unpack
local upper = string.upper
local pcall = pcall
local GetGameTimer = GetGameTimer
local GetFrameTime = GetFrameTime or function() return 0 end
local GetGameTimer = GetGameTimer
local IsControlJustPressed = IsControlJustPressed

local keyTable = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["F"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

---------------------------------------------------------------
--	Task Manager
---------------------------------------------------------------

local TaskControl = {
	amount = 0,
	
	taskPool = {},
	taskHandleId = 1,
}

local allTasks = TaskControl

--hash table with task handles as key and the task object as value
local taskPool = allTasks.taskPool


--add a task handle into the tasks pool and return a handle id
local addToTaskPool = function(taskObject)
	local handleId = TaskControl.taskHandleId
	taskPool[handleId] = taskObject
	taskObject.handleId = handleId
	
	--increment the handle id
	TaskControl.taskHandleId = handleId + 1
	
	--return the task handle index
	return handleId
end

local removeFromTaskPool = function(handleId)
	--wipe the table
	local taskObject = taskPool[handleId]
	if (taskObject) then
		npt.table.wipe(taskObject)
	end
	
	--mark the handle as non existent
	taskPool[handleId] = nil
end


---using a method table instead of metatables to avoid overhead inside the tick loop
local methodTable = {
	Resume = function (taskObject)
		if (taskObject:IsCancelled()) then
			return
		end
		taskObject.paused = false
	end,

	Pause = function (taskObject)
		taskObject.paused = true
	end,
	
	Cancel = function (taskObject)
		taskObject.cancelled = true
	end,
	
	Stop = function (taskObject) --alias
		taskObject.cancelled = true
	end,
	
	IsPaused = function (taskObject)
		return taskObject.paused
	end,
	
	IsCancelled = function (taskObject)
		return taskObject.cancelled
	end,
	
	IsRunning = function (taskObject)
		return not taskObject.cancelled and not taskObject.paused
	end,
	
	IsLastLoop = function (taskObject)
		if (taskObject.loops) then
			if (taskObject.loops <= 1) then
				return true
			end
		end
	end,
}

--functions to be used to control tasks on other resources
function npt.ResumeTask (taskHandle)
	local taskObject = taskPool [taskHandle]
	if (taskObject) then
		return taskObject:Resume()
	else
		return npt.DebugMessage ("npt.ResumeTask", "task not found for the passed handle", 2)
	end
end

function npt.PauseTask (taskHandle)
	local taskObject = taskPool [taskHandle]
	if (taskObject) then
		return taskObject:Pause()
	else
		return npt.DebugMessage ("npt.PauseTask", "task not found for the passed handle", 2)
	end
end

function npt.CancelTask (taskHandle)
	local taskObject = taskPool [taskHandle]
	if (taskObject) then
		return taskObject:Cancel()
	else
		return npt.DebugMessage ("npt.CancelTask", "task not found for the passed handle", 2)
	end
end
function npt.DeleteTask (taskHandle) --alias for cancel task
	return npt.CancelTask (taskHandle)
end
function npt.StopTask (taskHandle) --alias for cancel task
	return npt.CancelTask (taskHandle)
end

function npt.IsTaskPaused (taskHandle)
	local taskObject = taskPool [taskHandle]
	if (taskObject) then
		return taskObject:IsPaused()
	else
		return npt.DebugMessage ("npt.IsTaskPaused", "task not found for the passed handle", 2)
	end
end

function npt.IsTaskCancelled (taskHandle)
	local taskObject = taskPool [taskHandle]
	if (taskObject) then
		return taskObject:IsCancelled()
	else
		return true
	end
end

function npt.IsTaskRunning (taskHandle)
	local taskObject = taskPool [taskHandle]
	if (taskObject) then
		return taskObject:IsRunning()
	else
		return npt.DebugMessage ("npt.IsTaskRunning", "task not found for the passed handle", 2)
	end
end

function npt.IsTaskLastLoop (taskHandle)
	local taskObject = taskPool [taskHandle]
	if (taskObject) then
		return taskObject:IsLastLoop()
	else
		return npt.DebugMessage ("npt.IsTaskLastLoop", "task not found for the passed handle", 2)
	end
end

--return the task object
function npt.GetTask(handleId)
	return taskPool[handleId]
end


--registered keybinds, it'll run inside the task scheduler
local registeredKeybinds = {}
local keybindsCallback = {}

function npt.RegisterKeybind (key, callback)
	--check if the table is valid
	if (type (key) ~= "string") then
		return npt.DebugMessage ("RegisterKeybind", "require a string on #1 argument.", 3)
	end
	
	npt.CheckFunction (callback, "RegisterKeybind", 2)
	
	key = upper (key)
	key = keyTable [key]
	
	if (not key) then
		return npt.DebugMessage ("RegisterKeybind", "invalid key.", 3)
	end
	
	local added = npt.table.addUnique (registeredKeybinds, key)
	if (not added) then
		return npt.DebugMessage ("RegisterKeybind", "couldn't add the keybind, already registered?.", 3)
	end
	
	keybindsCallback [key] = callback
	
	return true
end

function npt.RemoveKeybind (key)
	if (type (key) ~= "string") then
		return npt.DebugMessage ("RemoveKeybind", "require a string on #1 argument.", 3)
	end
	
	key = upper (key)
	key = keyTable [key]
	
	npt.table.removeValue (registeredKeybinds, key)
	keybindsCallback [key] = nil
	
	return true
end

function npt.DeleteKeybind (key) --alias
	return npt.RemoveKeybind (key)
end

--task scheduler
local taskFunc = function()
	
	--get the time for the next cleanup of removed tasks
	local nextCleanup = GetGameTimer() + CONST_TASK_CLEANUP_INTERVAL_TIME
	
	while (true) do
		
		--add the elapsed time into the counter
		local currentGameTime = GetGameTimer()
		
		--collect tasks that has been cancelled
		if (currentGameTime > nextCleanup) then
			local tasksRemoved = 0
			for i = allTasks.amount, 1, -1 do
				local task = allTasks [i]
				if (task.cancelled) then
					removeFromTaskPool (task.handleId)
					table.remove (allTasks, i)
					tasksRemoved = tasksRemoved + 1
				end
			end
			
			allTasks.amount = allTasks.amount - tasksRemoved
			nextCleanup = currentGameTime + CONST_TASK_CLEANUP_INTERVAL_TIME
		end
		
		local deltaTime = GetFrameTime()
		
		--iterate among all create tasks
		for i = allTasks.amount, 1, -1 do
			local task = allTasks [i]
			
			if (not task.paused and not task.cancelled) then
				--check if the interval time has passed
				if (currentGameTime > task.nextTick) then
				
					--when the next tick will be triggered
					--the function it self can add a bigger interval if desired
					task.nextTick = currentGameTime + task.interval
					task.deltaTime = deltaTime
					
					--the first parameter the function receives is the taskObject
					--the called function can manipulated the task object at will
					--if is reliable, the task promises that its function won't produce errors
					if (task.isReliable) then
						task.callback(deltaTime, unpack(task.payLoad))
					
					--if is recursive it won't pass the task object and it's also reliable
					elseif (task.isRecursive) then
						--[=[
							if (type (task.callback) == "table" and task.callback.__cfx_functionReference) then
								local payload = msgpack.pack (task.payLoad)
								InvokeFunctionReference (task.callback.__cfx_functionReference, payload, payload:len())
							else
								task.callback (unpack (task.payLoad))
							end
						--]=]
						
						--function references seems to have a __call matatable
						--this needs be a tail call, not sure how to arrange the function to make it
						task.callback(unpack(task.payLoad))
						
					else
						
						--testing function references
						--if (type (task.callback) == "table") then
							--print (task.callback)
							--local payload = msgpack.pack (task.payLoad)
							--InvokeFunctionReference (task.callback.__cfx_functionReference, payload, payload:len())
							--task.callback(unpack (task.payLoad))
						--end

						local result, errorText_returnValue = pcall (task.callback, deltaTime, unpack (task.payLoad))
						if (not result) then
							npt.DebugMessage(task.name, errorText_returnValue, 3)
						end
					end
					
					--when false the loop is infinity, so it doesn't need to check
					--runs after the call so the function knows what is the loop number
					--the function can also add more loop is desired
					if (task.loops) then
						if (task.loops > 1) then
							task.loops = task.loops - 1
						else
							task:Cancel()
						end
					end
				end
			end
		end

		--check keybinds
		for i = 1, #registeredKeybinds do
		--for key, callback in pairs (registeredKeybinds) do
			if (IsControlJustPressed (1, registeredKeybinds [i])) then
				local result, errorText_returnValue = pcall (keybindsCallback [registeredKeybinds[i]])
				if (not result) then
					npt.DebugMessage ("keybind callback for [" .. registeredKeybinds [i] .. "].", errorText_returnValue, 3)
				end
			end
		end

		Wait(0)
	end
	
end

Citizen.CreateThread(taskFunc)

--[=[
	creates a new task
	callback: function to be called when the interval time is done
	interval: amount of time to call the function again
	loops: how many times the script loop, false to loop infinity
	priority: if priority is true, the task will be added in the first index of the task table
	taskName: optional, a name for the task
	isReliable: won't use pcall when calling the callback
	isRecursive: won't pass the task object before the payload, also recursive is always reliable
	... payload: arguments to pass within the callback
	
	this function returns a task object
--]=]

function npt.CreateTask(callback, interval, loops, priority, isReliable, isRecursive, taskName, ...)

	npt.CheckFunction(callback, "CreateTask")
	
	if (type (interval) ~= "number") then
		interval = 1
	end
	
	if (type (loops) ~= "number") then
		loops = false
	end
	
	taskName = taskName or "unnamed task"
	
	--arguments passed within the callback when the task is triggered
	local payLoad = {...}
	
	--create the an object for the new task
	local newTask = {
		callback = callback,
		interval = interval,
		name = taskName,
		loops = loops,
		
		nextTick = GetGameTimer() + interval,
		payLoad = payLoad,
		paused = false,
		isReliable = isReliable,
		isRecursive = isRecursive,
	}
	
	--inject methods and members into the task object
	npt.Mixin(newTask, methodTable)
	
	--add the task into the task table
	local newAmount = allTasks.amount + 1
	allTasks.amount = newAmount
	
	--if priority is not nil or false, the task will be added in the first index of the table
	if (priority) then
		table.insert(allTasks, 1, newTask)
	else
		allTasks [newAmount] = newTask
	end
	
	local taskHandle = addToTaskPool(newTask)
	
	return taskHandle
end

--[=[
	samething as cfx SetTimeout but uses the tasker and support payload
--]=]
function npt.SetTimeout(msec, callback, ...)
	return npt.CreateTask(callback, msec, 1, false, false, true, "SetTimeout", ...)
end

