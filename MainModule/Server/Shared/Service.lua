server = nil
client = nil
Pcall = nil
cPcall = nil
Routine = nil
logError = nil

local main
local ErrorHandler
local RealMethods = {}
local methods = setmetatable({}, {
	__index = function(tab, index)
		return function(obj, ...)
			local r,class = pcall(function() return obj.ClassName end)
			if r and class and obj[index] and type(obj[index]) == "function" then
				if not RealMethods[class] then
					RealMethods[class] = {}
				end

				if not RealMethods[class][index] then
					RealMethods[class][index] = obj[index]
				end

				if RealMethods[class][index] ~= obj[index] then
					if ErrorHandler then
						ErrorHandler("MethodError", `{debug.traceback()} || Cached method doesn't match found method: {index}`, `Method: {index}`, index)
					end
				end

				return RealMethods[class][index](obj,...)
			end

			return obj[index](obj,...)
		end
	end;
	__metatable = "Methods";
})


return function(errorHandler, eventChecker, fenceSpecific, env)
	if env then setfenv(1, env) end

	local _G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, time, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay, spawn, task, tick =
		_G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, time, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, require, table, type, task.wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, task.delay, task.defer, task, tick;

	main = server or client
	ErrorHandler = errorHandler

	server = nil
	client = nil

	local Routine = env.Routine

	local service;
	local passOwnershipCache = {}
	local assetOwnershipCache = {}
	local assetInfoCache = {}
	local groupInfoCache = {}
	local changedLocale = nil -- This has to be nil at start, it will only be set once the user changes it in the game
	local toBoolean = function(stat: any): boolean
		return stat and true or false
	end

	local WaitingEvents = {}
	local HookedEvents = {}
	local Debounces = {}
	local Queues = {}
	local RbxEvents = {}
	local LoopQueue = {}
	local TrackedTasks = {}
	local RunningLoops = {}
	local TaskSchedulers = {}
	local ServiceVariables = {}

	local CreatedItems = setmetatable({}, {__mode = "v"})
	local Wrappers = setmetatable({}, {__mode = "kv"})

	local oldInstNew = Instance.new
	local WrapService = Instance.new("Folder")
	local ThreadService = Instance.new("Folder")
	local HelperService = Instance.new("Folder")
	local EventService = Instance.new("Folder")

	local Instance = {new = function(obj, parent) local obj = oldInstNew(obj) if parent then obj.Parent = service.UnWrap(parent) end return service and client and service.Wrap(obj, true) or obj end}
	local Events, Threads, Wrapper, Helpers = {
		TrackTask = function(name, func, errHandler, ...)
			if type(errHandler) ~= "function" or select("#", ...) == 0 and errHandler == nil then
				errHandler = function(err)
					logError(err.."\n"..debug.traceback())
				end
			end
			local index = (main and main.Functions and game:GetService("HttpService"):GenerateGUID(false)) or math.random();
			local isThread = string.sub(name, 1, 7) == "Thread:"

			local data = {
				Name = name;
				Status = "Waiting";
				Function = func;
				isThread = isThread;
				Created = os.time();
				Index = index;
			}

			local function taskFunc(...)
				TrackedTasks[index] = data
				data.Status = "Running"
				data.Returns = {xpcall(func, errHandler, ...)}

				if not data.Returns[1] then
					data.Status = "Errored"
				else
					data.Status = "Finished"
				end

				TrackedTasks[index] = nil
				return unpack(data.Returns)
			end

			if isThread then
				data.Thread = coroutine.create(taskFunc)
				return coroutine.resume(data.Thread, ...) --select(2, coroutine.resume(data.Thread, ...))
			else
				return taskFunc(...)
			end
		end;

		EventTask = function(name, func)
			local newTask = service.TrackTask
			return function(...)
				return newTask(name, func, false, ...)
			end
		end;

		GetTasks = function()
			return TrackedTasks
		end;

		TaskScheduler = function(taskName, props)
			local props = props or {};
			if not props.Temporary and TaskSchedulers[taskName] then return TaskSchedulers[taskName] end

			local new = {
				Name = taskName;
				Running = true;
				Properties = props;
				LinkedTasks = {};
				RunnerEvent = service.New("BindableEvent");
				Trigger = function(self, ...)
					self.Event:Fire(...)
				end;

				Delete = function(self)
					if not props.Temporary then
						TaskSchedulers[taskName] = nil;
					end

					self.Running = false;
					self.Event:Disconnect();
				end;
			}

			new.Event = new.RunnerEvent.Event:Connect(function(...)
				for i,v in new.LinkedTasks do
					local ran,result = pcall(v);
					if result then
						table.remove(new.LinkedTasks, i);
					end
				end
			end)

			if props.Interval then
				while wait(props.Interval) and new.Running do
					new:Trigger(os.time());
				end
			end

			if not props.Temporary then
				TaskSchedulers[taskName] = new;
			end

			return new;
		end;

		Events = setmetatable({},{
			__index = function(tab,ind)
				return service.GetEvent(ind)
			end
		});

		CheckEvents = function(waiting)
			if true then return "Disabled" end
			if waiting then
				for ind,waiter in WaitingEvents do
					if waiter.Waiting and waiter.Timeout ~= 0 and time() - waiter.Last > waiter.Timeout then
						waiter:Remove()
					end
				end
			else
				for i,v in HookedEvents do
					if #v == 0 then
						HookedEvents[i] = nil
					else
						for ind,waiter in WaitingEvents do
							if waiter.Waiting and waiter.Timeout ~= 0 and time() - waiter.Last > waiter.Timeout then
								waiter:Remove()
							end
						end
					end
				end
			end
		end;

		WrapEventArgs = function(tab)
			local Wrap = service.Wrap

			for i,v in tab do
				if type(v) == "table" and v.__ISWRAPPED and v.__OBJECT then
					tab[i] = Wrap(v.__OBJECT)
				end
			end
			return tab
		end;

		UnWrapEventArgs = function(args)
			local UnWrap = service.UnWrap
			local Wrapped = service.Wrapped

			for i,v in args do
				if Wrapped(v) then
					args[i] = {
						__ISWRAPPED = true;
						__OBJECT = UnWrap(v);
					}
				end
			end
			return args
		end;

		GetEvent = function(name)
			if not HookedEvents[name] then
				--// GoodSignal has been setup to be fully backwards-compatible with the existing Events system
				local event = service.GoodSignal.new()

				HookedEvents[name] = event
				return event
			else
				return HookedEvents[name]
			end
		end;

		HookEvent = function(name,func,env)
			if type(name) ~= "string" or type(func) ~= "function" then
				warn("Invalid argument supplied; HookEvent(string, function)")
			else
				return service.GetEvent(name):Connect(func)
			end
		end;

		FireEvent = function(name,...)
			local event = HookedEvents[name]
			return event and event:Fire(...)
		end;

		RemoveEvents = function(name)
			local event = HookedEvents[name]
			if event then
				HookedEvents[name] = nil
				event:Destroy()
			end
		end;
	},{
		Tasks = {};
		Threads = {};
		CheckTasks = function()
			for i,task in service.Threads.Tasks do
				if not task.Thread or task:Status() == "dead" then
					task:Remove()
				end
			end
		end;

		NewTask = function(name,func,timeout)
			local pid = math.random()*os.time()/1000
			local index = `{pid}:{func}`
			local newTask; newTask = {
				PID = pid;
				Name = name;
				Index = index;
				Created = os.time();
				Changed = {};
				Timeout = timeout or 0;
				Running = false;
				--Function = func;
				R_Status = "Idle";
				Finished = {};
				Function = function(...) newTask.R_Status = "Running" newTask.Running = true local ret = {func(...)} newTask.R_Status = "Finished" newTask.Running = false newTask.Remove() return unpack(ret) end;
				Remove = function() newTask.R_Status = "Removed" newTask.Running = false for i,v in service.Threads.Tasks do if v == newTask then table.remove(service.Threads.Tasks,i) end end newTask.Changed:Fire("Removed") newTask.Finished:Fire() service.RemoveEvents(`{index}_TASKCHANGED`) service.RemoveEvents(`{index}_TASKFINISHED`) newTask.Thread = nil end;
				Thread = service.Threads.Create(function(...) return newTask.Function(...) end);
				Resume = function(...) newTask.R_Status = "Resumed" newTask.Running = true newTask.Changed:Fire("Resumed") local rets = {service.Threads.Resume(newTask.Thread,...)} if not rets[1] then ErrorHandler("TaskError", rets[2]) newTask.Changed:Fire("Errored",rets[2]) newTask.Remove() end return unpack(rets) end;
				Status = function() if newTask.Timeout ~= 0 and ((os.time() - newTask.Created) > newTask.Timeout) then newTask:Stop() return "timeout" else return service.Threads.Status(newTask.Thread) end end;
				Pause = function() newTask.R_Status = "Paused" newTask.Running = false service.Threads.Pause(newTask.Thread) newTask.Changed:Fire("Paused") end;
				Stop = function() newTask.R_Status = "Stopping" service.Threads.Stop(newTask.Thread) newTask.Changed:Fire("Stopped") newTask.Remove() end;
				Kill = function() newTask.R_Status = "Killing" service.Threads.End(newTask.Thread) newTask.Changed:Fire("Killed") newTask.Remove() end;
			}

			function newTask.Changed:Connect(func)
				return service.Events[`{index}_TASKCHANGED`]:Connect(func)
			end;

			function newTask.Changed:Fire(...)
				service.Events[`{index}_TASKCHANGED`]:Fire(...)
			end

			function newTask.Finished:Connect(func)
				return service.Events[`{index}_TASKFINISHED`]:Connect(func)
			end

			function newTask.Finished:wait()
				service.Events[`{index}_TASKFINISHED`]:wait(0)
			end

			function newTask.Finished:Fire(...)
				service.Events[`{index}_TASKFINISHED`]:Fire(...)
			end

			newTask.End = newTask.Stop
			newTask.Kill = newTask.Stop

			table.insert(service.Threads.Tasks,newTask)

			service.Threads.CheckTasks()

			return newTask.Resume, newTask
		end;

		RunTask = function(name,func,...)
			local func,task = service.Threads.NewTask(name,func)
			return task,func(...)
		end;

		TimeoutRunTask = function(name,func,timeout,...)
			local func,task = service.Threads.NewTask(name,func,timeout)
			return task,func(...)
		end;

		WaitTask = function(name,func,...)
			local func,task = service.Threads.NewTask(name,func)
			local returns = {func(...)}
			task.Finished:wait()
			return task, unpack(returns)
		end;

		NewEventTask = function(name,func,timeout)
			--if true then return func end --// disabling stuff for now; Spamming tasks for events just seems like a bad idea
			return function(...)
				if service.Running then
					return service.Threads.NewTask(name,func,timeout)(...)
				else
					return function() end
				end
			end
		end;

		Stop = coroutine.yield;
		Wait = coroutine.yield;
		Pause = coroutine.yield;
		Yield = coroutine.yield;
		Status = coroutine.status;
		Running = coroutine.running;
		Create = coroutine.create;
		Start = coroutine.resume;
		--Wrap = coroutine.wrap;
		Get = coroutine.running;
		New = function(func) local new = coroutine.create(func) table.insert(service.Threads.Threads,new) return new end;
		End = function(thread) repeat if thread and service.Threads.Status(thread) ~= "dead" then service.Threads.Stop(thread) service.Threads.Resume(thread) else thread = false break end until not thread or service.Threads.Status(thread) == "dead" end;
		Wrap = function(func,...) local new = service.Threads.New(func) service.Threads.Resume(func,...) return new end;
		Resume = function(thread,...) if thread and coroutine.status(thread) == "suspended" then return coroutine.resume(thread,...) end end;
		Remove = function(thread) service.Threads.Stop(thread) for ind,th in service.Threads.Threads do if th == thread then table.remove(service.Threads.Threads,ind) end end end;
		StopAll = function() for ind,th in service.Threads.Threads do service.Threads.Stop(th) table.remove(service.Threads.Threads,ind) end end; ResumeAll = function() for ind,th in service.Threads.Threads do service.Threads.Resume(th) end end; GetAll = function() return service.Threads.Threads end;
	},{
		WrapIgnore = function(tab) return setmetatable(tab,{__metatable = if main.Core and main.Core.DebugMode then "Ignore" else nil}) end; -- Unused
		CheckWrappers = function()
			for obj,wrap in Wrappers do
				if service.IsDestroyed(obj) then
					Wrappers[obj] = nil
				end
			end
		end;
		Wrapped = function(object)
			if type(getmetatable(object)) == "table" and rawget(getmetatable(object), "__ADONIS_WRAPPED") or getmetatable(object) == "Adonis_Proxy" then
				return true
			elseif (type(object) == "table" or typeof(object) == "userdata") and object.IsProxy and object:IsProxy() then
				return true
			else
				return false
			end
		end;
		UnWrap = function(object)
			local OBJ_Type = typeof(object)

			if OBJ_Type == "Instance" then
				return object
			elseif OBJ_Type == "table" then
				local UnWrap = service.UnWrap
				local tab = {}
				for i, v in object do
					tab[i] = UnWrap(v)
				end
				return tab
			elseif service.Wrapped(object) then
				return object:GetObject()
			else
				return object
			end
		end;
		Wrap = function(object, fullWrap)
			fullWrap = fullWrap or (fullWrap == nil and client ~= nil) --// Everything clientside should be getting wrapped anyway
			if getmetatable(object) == "Ignore" or getmetatable(object) == "ReadOnly_Table" then
				return object
			elseif Wrappers[object] then
				return Wrappers[object]
			elseif type(object) == "table" then
				local Wrap = service.Wrap
				local tab = setmetatable({	}, {
					__eq = function(tab,val)
						return object
					end
				})
				for i,v in object do
					tab[i] = Wrap(v, fullWrap)
				end
				return tab
			--[[elseif type(object) == "function" then
				return function(...)
					pcall(setfenv, object, getfenv())
					return unpack(service.Wrap({object(...)}))
				end--]]
			elseif (typeof(object) == "Instance" or typeof(object) == "RBXScriptSignal" or typeof(object) == "RBXScriptConnection") and not service.Wrapped(object) then
				local UnWrap = service.UnWrap
				local sWrap = service.Wrap

				local Wrap = (not fullWrap and function(...)
					return ...
				end) or function(obj)
					return sWrap(obj, fullWrap)
				end

				local newObj = newproxy(true)
				local newMeta = getmetatable(newObj)

				local custom; custom = {
					GetMetatable = function()
						return newMeta
					end;

					AddToCache = function()
						Wrappers[object] = newObj;
					end;
					RemoveFromCache = function()
						Wrappers[object] = nil
					end;

					GetObject = function()
						return object
					end;

					SetSpecial = function(ignore, name, val)
						custom[name] = val
						return custom
					end;

					Clone = function(self, noAdd)
						local new = object:Clone()
						if not noAdd then
							table.insert(CreatedItems, new)
						end
						return sWrap(new)
					end;

					IsWrapped = function()
						return true -- Cannot fully depend on __metatable if DebugMode is enabled
					end;

					connect = function(ignore, func)
						return Wrap(object:Connect(function(...)
							local packedResult = table.pack(...)
							return func(unpack(sWrap(packedResult), 1, packedResult.n))
						end))
					end;

					wait = function(ignore,...)
						return Wrap(object.wait)(object, ...)
					end;
				}

				custom.Connect = custom.connect
				custom.Wait = custom.wait

				newMeta.__index = function(tab, ind)
					local target = custom[ind] or object[ind]

					if custom[ind] then
						return custom[ind]
					elseif type(target) == "function" then
						return function(ignore, ...)
							local packedResult = table.pack(...)
							return unpack(Wrap({
								methods[ind](object, unpack(UnWrap(packedResult), 1, packedResult.n))
							}))
						end
					else
						return Wrap(target)
					end
				end

				newMeta.__newindex = function(tab, ind, val)
					object[ind] = UnWrap(val)
				end

				newMeta.__eq = service.RawEqual
				newMeta.__tostring = function() return custom.ToString or tostring(object) end
				-- Roblox doesn't respect this afaik.
				--newMeta.__gc = function(tab)
				--	custom:RemoveFromCache()
				--end
				newMeta.__metatable = if main.Core and main.Core.DebugMode then nil else "Adonis_Proxy"
				newMeta.__ADONIS_WRAPPED = true
				custom:AddToCache()
				return newObj
			else
				return object
			end
		end;
	},{
		CloneTable = function(tab)
			local new = (getmetatable(tab) ~= nil and setmetatable({},{
				__index = function(t, ind)
					return tab[ind]
				end
			})) or {}
			for i,v in tab do
				new[i] = v
			end
			return new
		end;
				
		DeepCopy = function(tab)
			local new = (getmetatable(tab) ~= nil and setmetatable({},{
				__index = function(t, ind)
					return tab[ind]
				end
			})) or {}
			for i,v in tab do
				if typeof(v) == 'table' then 
					new[i] = service.DeepCopy(v)
				else
					new[i] = v
				end
			end
			return new
		end,

		IsLocked = function(obj) return not pcall(function() obj.Name = obj.Name return obj.Name end) end;

		Timer = function(t,func,check)
			local start = time()
			local event; event = service.RunService.RenderStepped:Connect(function()
				if time()-start>t or (check and check()) then
					func()
					event:Disconnect()
				end
			end)
		end;

		AltUnpack = function(args,shift)
			if shift then shift = shift-1 end
			return args[1+(shift or 0)],args[2+(shift or 0)],args[3+(shift or 0)],args[4+(shift or 0)],args[5+(shift or 0)],args[6+(shift or 0)],args[7+(shift or 0)],args[8+(shift or 0)],args[9+(shift or 0)],args[10+(shift or 0)]
		end;

		ExtractLines = function(str)
			local strs = table.create(#str+1)
			local new = ""
			for i=1,#str+1 do
				if string.byte(string.sub(str, i,i)) == 10 or i == #str+1 then
					table.insert(strs,new)
					new = ""
				else
					local char = string.sub(str,i,i)
					if string.byte(char) < 32 then
						char = ""
					end
					new = new..char
				end
			end
			return strs
		end;

		Filter = function(str, from, to)
			if not utf8.len(str) then
				return "Filter Error"
			end

			local new = ""
			local lines = service.ExtractLines(str)
			for i = 1,#lines do
				local ran,newl = pcall(function()
					return service.TextService:FilterStringAsync(lines[i],from.UserId):GetChatForUserAsync(to.UserId)
				end)
				newl = (ran and newl) or lines[i] or ""
				if i > 1 then
					new = `{new}\n{newl}`
				else
					new = newl
				end
			end
			return new or "Filter Error"
		end;

		LaxFilter = function(str,from,cmd)  	-- @Roblox; If this function violates the filtering rules please note that this is currently the only way
			if tonumber(str) then				-- to avoid major filter related problems (like commands becoming unusable due to numbers or names being filtered)
				return str						-- Please consider dropping the filter rules down a notch or improving on the existing filtering methods
			elseif type(str) == "string" then	-- Also always feel free to message me with any concerns you have :)!
				if not utf8.len(str) then
					return "Filter Error"
				end

				if cmd and #service.GetPlayers(from, str, {
					DontError = true;
					}) > 0 then
					return str
				else
					return service.Filter(str, from, from)
				end
			else
				return str
			end
		end;

		BroadcastFilter = function(str, from)
			if not utf8.len(str) then
				return "Filter Error"
			end

			local new = ""
			local lines = service.ExtractLines(str)
			for i = 1,#lines do
				local ran,newl = pcall(function() return service.TextService:FilterStringAsync(lines[i],from.UserId):GetNonChatStringForBroadcastAsync() end)
				newl = (ran and newl) or lines[i] or ""
				if i > 1 then
					new = `{new}\n{newl}`
				else
					new = newl
				end
			end
			return new or "Filter Error"
		end;

		EscapeSpecialCharacters = function(x)
			return string.gsub(x, "([^%w])", "%%%1")
		end;

		MetaFunc = function(func, filterArgs: boolean?)
			return service.NewProxy({
				__call = function(tab,...)
					if filterArgs then
						for _, v in {...} do
							if (type(v) == "table" or typeof(v) == "userdata") and getmetatable(v) ~= nil then
								return nil
							end
						end
					end

					local args = {pcall(func, ...)}
					local success = args[1]
					if not success then
						warn(args[2])
					else
						return unpack(args, 2)
					end
				end
			})
		end;

		NewProxy = function(meta)
			local newProxy = newproxy(true)
			local metatable = getmetatable(newProxy)
			metatable.__metatable = if main.Core and main.Core.DebugMode then nil else "Adonis_Proxy"
			metatable.__ADONIS_WRAPPED = true
			for i,v in meta do metatable[i] = v end
			return newProxy
		end;

		GetUserType = function(obj)
			local ran,err = pcall(function() local temp = obj[math.random()] end)
			if ran then
				return "Unknown"
			else
				return string.match(err, "%S+$")
			end
		end;

		CountTable = function(tab)
			local num = 0
			for _ in tab do num += 1 end
			return num
		end;

		Debounce = function(key,func)
			local env = getfenv(2)
			local Debounces = (env and env._ADONIS_DEBOUNCES) or Debounces or {}

			if env then
				env._ADONIS_DEBOUNCES = (env and env._ADONIS_DEBOUNCES) or {}
			end

			if Debounces[key] then
				return false
			else
				Debounces[key] = true
				local ran,err = pcall(func)
				Debounces[key] = false
				if not ran then
					error(err)
				end
			end
		end;

		Queue = function(key, func, timeout, doYield)
			if not Queues[key] then
				Queues[key] = {
					Processing = false;
					Functions = {};
				}
			end

			local queue = Queues[key]
			local tab = {
				Time = os.time();
				Running = false;
				Function = func;
				Timeout = timeout;

				Finished = false;
				Yield = doYield and service.Yield();
			}

			table.insert(queue.Functions, tab);

			if not queue.Processing then
				service.TrackTask(`Thread: QueueProcessor_{key}`, service.ProcessQueue, false, queue, key);
			end

			if doYield and not tab.Finished then
				return select(2, tab.Yield:Wait());
			end
		end;

		ProcessQueue = function(queue, key)
			if queue then
				if queue.Processing then
					return "Processing"
				else
					local funcs = queue.Functions;
					local Yield = service.Yield();
					local function pop()
						local n = funcs[1]
						table.remove(funcs, 1)
						return n
					end;

					queue.Processing = true

					while funcs[1] ~= nil do
						local func = pop();
						func.Running = true;

						if func.Timeout then
							delay(func.Timeout, function()
								if not func.Finished then
									Yield:Release();
									warn(`Queue Timeout Reached for {key or "Unknown"}`)

									if func.Yield then
										func.Yield:Release(false, "Timeout Reached");
									end
								end
							end)
						end

						service.TrackTask(`Thread: {key or "Unknown"}_QueuedFunction`, function()
							local r,e = xpcall(func.Function,function(e)
								func.Error = e;
								warn(`Queue Error: {key}: {e} \n {debug.traceback()}`)
							end);

							func.Running = false;
							func.Finished = true

							if func.Yield then
								func.Yield:Release(r, e)
							end

							Yield:Release();
						end,false)

						if func.Running then
							Yield:Wait();
						end
					end

					Yield:Destroy();
					queue.Processing = false;

					if key then
						Queues[key] = nil;
					end
				end
			end
		end;

		ProcessLoopQueue = function()
			for ind,data in LoopQueue do
				if not data.LastRun or (data.LastRun and time()-data.LastRun>data.Delay) then
					if data.MaxRuns and data.NumRuns and data.MaxRuns<=data.NumRuns then
						LoopQueue[ind] = nil
					else
						if data.MaxRuns and data.NumRuns then
							data.NumRuns = data.NumRuns+1
						end
						Pcall(data.Function)
						data.LastRun = time()
					end
				end
			end
		end;

		QueueItem = function(name,data)
			local new = data
			if data.MaxRuns then
				data.NumRuns = 0
			end
			LoopQueue[name] = new
		end;

		RemoveQueue = function(name)
			LoopQueue[name] = nil
		end;

		New = function(class, data, noWrap, noAdd)
			local new = noWrap and oldInstNew(class) or Instance.new(class)
			if data then
				if type(data) == "table" then
					local parent = data.Parent
					if service.Wrapped(parent) then parent = parent:GetObject() end
					data.Parent = nil

					for val,prop in data do
						new[val] = prop
					end

					if parent then
						new.Parent = parent
					end
				elseif type(data) == "userdata" then
					if service.Wrapped(data) then
						new.Parent = data:GetObject()
					else
						new.Parent = data
					end
				end
			end

			if new and not noAdd then
				table.insert(CreatedItems, new)
			end

			return new
		end;

		Iterate = function(tab,func)
			if tab and type(tab) == "table" then
				for ind,val in tab do
					local ret = func(ind,val)
					if ret ~= nil then
						return ret
					end
				end
			elseif tab and type(tab) == "userdata" then
				for ind,val in ipairs(tab:GetChildren()) do
					local ret = func(val,ind)
					if ret ~= nil then
						return ret
					end
				end
			else
				error("Invalid table")
			end
		end;

		EscapeControlCharacters = function(str)
			return string.gsub(str, "%c", {
				["\a"] = "\\a",
				["\b"] = "\\b",
				["\f"] = "\\f",
				["\n"] = "\\n",
				["\r"] = "\\r",
				["\t"] = "\\t",
				["\v"] = "\\v"
			})
		end;

		SanitizeXML = function(str)
			return string.gsub(str, "['\"<>&]", {
				["'"] = "&apos;",
				["\""] = "&quot;",
				["<"] = "&lt;",
				[">"] = "&gt;",
				["&"] = "&amp;"
			})
		end;

		GetCurrentLocale = function()
			if service.RunService:IsClient() then
				local accountLocale, systemLocale = service.LocalizationService.RobloxLocaleId, service.LocalizationService.SystemLocaleId
				return changedLocale or (accountLocale ~= "en-us" and accountLocale ~= "en") and accountLocale or systemLocale ~= "" and systemLocale or "en-us"
			end
			return "en-us"
		end,

		GetTime = os.time;

		FormatTime = function(optTime, options)
			options = if options == true then {WithDate = true} else options or {}

			local formatString = options.FormatString
			if not formatString then
				formatString = options.WithWrittenDate and "LL HH:mm:ss" or (options.WithDate and "L HH:mm:ss" or "HH:mm:ss")
			end

			local timeObj = DateTime.fromUnixTimestamp(optTime or service.GetTime())
			local success, value = pcall(timeObj.FormatLocalTime, timeObj, formatString, service.GetCurrentLocale())
			return if success then value else timeObj:ToIsoDate()
		end;

		FormatPlayer = function(plr, withUserId)
			if not plr then return "%UNKNOWN%" end
			if plr.Name == "[Unknown User]" then
				return `[Unknown User{(if plr.UserId and plr.UserId ~= -1 then ` {plr.UserId}` else "")}]`
			end
			local str = if plr.DisplayName == plr.Name then `@{plr.Name}` else string.format("%s (@%s)", plr.DisplayName or "???", plr.Name or "???")
			if withUserId then
				str ..= string.format(" [%s]", if plr.UserId and plr.UserId ~= -1 then plr.UserId else "?")
			end
			return str
		end;

		FormatNumber = function(num: number?, doAbbreviate: boolean?, separator: string?): string
			num = tonumber(num)
			separator = separator or ","

			if not num then return "NaN" end
			if math.abs(num) >= 1e150 then return "Inf" end

			local int, dec = unpack(tostring(math.abs(num)):split("."))

			if doAbbreviate and math.abs(num) >= 1000 then
				local ABBREVIATIONS = {
					"K", "M", "B", "T", "Qd", "Qi"
				}
				local thousands = math.floor((#int - 1) / 3)
				local suffix = ABBREVIATIONS[thousands]
				if suffix then
					return tonumber(string.format("%.2f", num / (10 ^ (3 * thousands)))) .. suffix
				end
				return service.FormatNumber(num / (10 ^ (3 * #ABBREVIATIONS)), false, separator) .. ABBREVIATIONS[#ABBREVIATIONS]
			end

			int = int:reverse()
			local newInt = ""
			local counter = 1
			for i = 1, #int do
				if counter > 3 then
					newInt ..= separator
					counter = 1
				end
				newInt ..= int:sub(i, i)
				counter += 1
			end

			return `{(if num < 0 then "-" else "")}{newInt:reverse()}{if dec then `.{dec}` else ""}`
		end;

		OwnsAsset = function(...)
			return service.CheckAssetOwnership(...)
		end;

		GetProductInfo = function(assetId, infoType)
			assetId = tonumber(assetId) or 0
			infoType = infoType or Enum.InfoType.Asset

			if assetId > 0 then
				local cache = assetInfoCache[`{assetId}-{infoType}`]

				if not cache then
					cache = {
						results = {
							Created = false;
						};
						lastUpdated = os.clock();
					}
					assetInfoCache[`{assetId}-{infoType}`] = cache
				end

				local canUpdateCache = not cache.lastUpdated or os.clock()-cache.lastUpdated > 120

				if canUpdateCache then
					local suc,info = pcall(service.MarketplaceService.GetProductInfo, service.MarketplaceService, assetId, infoType)

					if suc and type(info) == "table" then
						info.Created = true
						cache.results = info
					else
						cache.results.Created = false
					end
				end

				return service.CloneTable(cache.results)
			end
		end;

		CheckPassOwnership = function(userId, gamepassId)
			userId = if type(userId) == "userdata" then userId.UserId else tonumber(userId)
			gamepassId = tonumber(gamepassId)

			local cacheIndex = `{userId}-{gamepassId}`
			local currentCache = passOwnershipCache[cacheIndex]

			if currentCache and currentCache.owned then
				return true
			elseif (currentCache and (os.time()-currentCache.lastUpdated > 60)) or not currentCache then
				local cacheTab = {
					owned = (currentCache and currentCache.owned) or false;
					lastUpdated = os.time();
				}
				passOwnershipCache[cacheIndex] = cacheTab

				local suc,ers = pcall(function()
					return service.MarketplaceService:UserOwnsGamePassAsync(userId, gamepassId)
				end)

				if suc then
					cacheTab.owned = toBoolean(ers)
					return toBoolean(ers)
				else
					return cacheTab.owned
				end
			elseif currentCache then
				return currentCache.owned
			end
		end;

		CheckAssetOwnership = function(player, assetId)
			if type(player) == "number" then
				player = service.Players:GetPlayerByUserId(player)
			end

			local cacheIndex = `{player.UserId}-{assetId}`
			local currentCache = assetOwnershipCache[cacheIndex]

			if currentCache and currentCache.owned then
				return true
			elseif (currentCache and (os.time()-currentCache.lastUpdated > 60)) or not currentCache then
				local cacheTab = {
					owned = (currentCache and currentCache.owned) or false;
					lastUpdated = os.time();
				}
				passOwnershipCache[cacheIndex] = cacheTab

				local suc,ers = pcall(function()
					return service.MarketplaceService:PlayerOwnsAsset(player, assetId)
				end)

				if suc then
					cacheTab.owned = toBoolean(ers)
				end

				return cacheTab.owned
			elseif currentCache then
				return currentCache.owned
			end
		end;

		GetGroupInfo = function(groupId)
			groupId = tonumber(groupId) or 0

			if groupId > 0 then
				local existingCache = groupInfoCache[groupId]
				local canUpdate = not existingCache or os.time()-existingCache.lastUpdated > 120

				if canUpdate then
					existingCache = {
						results = (existingCache and existingCache.results) or {};
						lastUpdated = os.time();
					}
					groupInfoCache[groupId] = existingCache

					local suc,info = pcall(service.GroupService.GetGroupInfoAsync, service.GroupService, groupId)

					if suc and type(info) == "table" then
						existingCache.results = info
					else
						existingCache.results.Failed = true
					end
				end

				return service.CloneTable(existingCache.results)
			end
		end;

		GetGroupCreatorId = function(groupId)
			groupId = tonumber(groupId) or 0

			if groupId > 0 then
				local groupInfo = service.GetGroupInfo(groupId)

				if groupInfo and groupInfo.Owner then
					return groupInfo.Owner.Id
				end
			end

			return 0
		end,

		MaxLen = function(message, length)
			if string.len(message) > length then
				return `{string.sub(message, 1, length)}...`
			else
				return message
			end
		end;

		Yield = function()
			local event = service.New("BindableEvent");
			return {
				Release = function(...) event:Fire(...) end;
				Wait = function(...) return event.Event:Wait(...) end;
				Destroy = function() event:Destroy() end;
				Event = event;
			}
		end;

		StartLoop = function(name,delay,func,noYield)
			local tab = {
				Name = name;
				Delay = delay;
				Function = func;
				Running = true;
			}

			local index = `{name} - {game:GetService("HttpService"):GenerateGUID(false)}`

			local function kill()
				tab.Running = true
				if RunningLoops[index] == tab then
					RunningLoops[index] = nil
				end
			end

			local function loop()
				if tonumber(delay) then
					repeat
						func()
						wait(tonumber(delay))
					until RunningLoops[index] ~= tab or not tab.Running
					kill()
				elseif delay == "Heartbeat" then
					repeat
						func()
						service.RunService.Heartbeat:wait()
					until RunningLoops[index] ~= tab or not tab.Running
					kill()
				elseif delay == "RenderStepped" then
					repeat
						func()
						service.RunService.RenderStepped:wait()
					until RunningLoops[index] ~= tab or not tab.Running
					kill()
				elseif delay == "Stepped" then
					repeat
						func()
						service.RunService.Stepped:wait()
					until RunningLoops[index] ~= tab or not tab.Running
					kill()
				else
					tab.Running = false
				end
			end

			tab.Kill = kill
			RunningLoops[index] = tab


			if noYield then
				service.TrackTask(`Thread: Loop: {name}`, loop, false)
			else
				service.TrackTask(`Loop: {name}`, loop, false)
			end

			--[[local task = service.Threads.RunTask(`LOOP:{name}`, loop)

			if not noYield then
				task.Finished:wait()
				kill()
			end--]]

			--[[if noYield then
				Routine(loop)
			else
				loop()
			end--]]

			return tab
		end;
		StopLoop = function(name)
			for ind,loop in RunningLoops do
				if name == loop.Function or name == loop.Name then
					loop.Running = false
				end
			end
		end;
		IsLooped = function(name)
			for cat,loop in RunningLoops do
				if name == loop.Function or name == loop.Name then
					return loop.Running
				end
			end
			return false
		end;
		Immutable = function(...)
			local co = coroutine.wrap(function(...) while true do coroutine.yield(...) end end)
			co(...)
			return co
		end;
		ReadOnly = function(tabl, excluded, killOnError, noChecks)
			local doChecks = (not noChecks) and service.RunService:IsClient()
			if main.Core and main.Core.DebugMode then 
				doChecks = false
			end
			local player = doChecks and service.Players.LocalPlayer
			local kick = player and player.Kick
			local settings, getMeta, get, pc, resume, create = getfenv().settings, getmetatable, getfenv, pcall, coroutine.resume, coroutine.create
			local unique = doChecks and getMeta(get())
			local checkFor = doChecks and {
				secret500 = true;
				getrawmetatable = true;
				setreadonly = true;
				full_access = true;
				elysianexecute = true;
				decompile = true;
				make_writable = true;
				hookmetamethod = true;
				hookfunction = true;
			}

			return service.NewProxy {
				__index = function(tab, ind)
					local ind = (type(ind) ~= "table" and typeof(ind) ~= "userdata") and ind or "Potentially dangerous index"

					local topEnv = doChecks and get and get(2)
					local setRan = doChecks and pcall(settings)
					if doChecks and (setRan or (get ~= getfenv or getMeta ~= getmetatable or pc ~= pcall) or (not topEnv or type(topEnv) ~= "table" or getMeta(topEnv) ~= unique)) then
						ErrorHandler("ReadError", "Tampering with Client [read rt0001]", `[{ind} {topEnv} {topEnv and getMeta(topEnv)}]\n{debug.traceback()}`)
						--elseif doChecks and (function() local ran,err = pc(function() for i in next,checkFor do if topEnv[i] then return true end end return false end) if not ran or ran and err then return true end end)() then
							-- ErrorHandler("ReadError", "Tampering with Client [read rt0002]", `[{ind} {topEnv} {topEnv and getMeta(topEnv)}]\n{debug.traceback()}`)
					elseif tabl[ind]~=nil and type(tabl[ind]) == "table" and not (excluded and (excluded[ind] or excluded[tabl[ind]])) then
						return service.ReadOnly(tabl[ind], excluded, killOnError, noChecks)
					else
						return tabl[ind]
					end
				end;

				__newindex = function(tab,ind,new)
					local ind = (type(ind) ~= "table" and typeof(ind) ~= "userdata") and ind or "Potentially dangerous index"

					local topEnv = doChecks and get and get(2)
					local setRan = doChecks and pcall(settings)
					if doChecks and (setRan or (get ~= getfenv or getMeta ~= getmetatable or pc ~= pcall) or (not topEnv or type(topEnv) ~= "table" or getMeta(topEnv) ~= unique)) then
						ErrorHandler("ReadError", "Tampering with Client [write wt0003]", `[{ind} {topEnv} {topEnv and getMeta(topEnv)}]\n{debug.traceback()}`)
						--elseif doChecks and (function() local ran,err = pc(function() for i in next,checkFor do if topEnv[i] then return true end end return false end) if not ran or ran and err then return true end end)() then
							-- ErrorHandler("ReadError", "Tampering with Client [write wt0004]", `[{ind} {topEnv} {topEnv and getMeta(topEnv)}]\n{debug.traceback()}`)
					elseif not (excluded and (excluded[ind] or excluded[tabl[ind]])) then
						if killOnError then
							ErrorHandler("ReadError", "Tampering with Client [write wt0005]", `[{ind} {topEnv} {topEnv and getMeta(topEnv)}]\n{debug.traceback()}`)
						end

						warn(`Something attempted to set index {ind} in a read-only table.`)
					else
						rawset(tabl, ind, new)
					end
				end;

				__metatable = if main.Core and main.Core.DebugMode then unique else "ReadOnly_Table"; -- Allow ReadOnly table's metadata to be modified if DebugMode is enabled
			}
		end;
		Wait = function(mode)
			if not mode or mode == "Stepped" then
				service.RunService.Stepped:wait()
			elseif mode == "Heartbeat" then
				service.RunService.Heartbeat:wait()
			elseif mode and tonumber(mode) then
				wait(tonumber(mode))
			end
		end;
		OrigRawEqual = rawequal;
		HasItem = function(obj, prop) return pcall(function() return obj[prop] end) end;
		IsDestroyed = function(object)
			if type(object) == "userdata" and service.HasItem(object, "Parent") then
				if object.Parent == nil then
					local ran,err = pcall(function() object.Parent = game object.Parent = nil end)
					if not ran then
						if err and string.match(err, "^The Parent property of (.*) is locked, current parent: NULL,") then
							return true
						else
							return false
						end
					end
				end
			end
			return false
		end;
		OutfitCache = {},
		UnallowedCache = {},
		Insert = function(id, rawModel)
			if service.UnallowedCache and service.UnallowedCache[id] then return end
			local model = service.InsertService:LoadAsset(id)
			if not rawModel and model:IsA("Model") and model.Name == "Model" then
				local asset = model:GetChildren()[1]
				asset.Parent = model.Parent
				model:Destroy()
				return asset
			end
			return model
		end,
		SecureAccessory = function(plr, itemId)
			if not plr.Character then return end

			local function reject()
				service.UnallowedCache[tonumber(itemId)] = true
				error("Item not supported")
			end

			local success, item = pcall(function() return service.Insert(tonumber(itemId)) end)
			if not success then return reject() end
			if not item then return reject() end
			if not item:IsA("Accoutrement") then return reject() end
			if not item:FindFirstChild("Handle") then return reject() end
			if #item:GetDescendants() > 250 then return reject() end
			item.Name = "CustomAdonisAccessory"
			item:SetAttribute("AssetId", itemId)

			-- No classes except those in whitelistedClasses are allowed
			local whitelistedClasses = {"Accoutrement", "BasePart", "SpecialMesh", "Attachment", "Weld", "WeldConstraint", "Motor6D", "Folder", "ValueBase", "ParticleEmitter", "Sparkles", "Fire"}
			local blacklistedClasses = {"LuaSourceContainer", "Model", "Tool", "Hopperbin"} -- extra security
			
			for i,v in item:GetDescendants() do
				if v:IsA("BasePart") then
					v.CanCollide = false
				end
			end
			
			-- If a blacklisted class is found, cancel the command
			for i,v in item:GetDescendants() do
				local blacklisted = false
				for _,x in blacklistedClasses do
					if v:IsA(x) then
						blacklisted = true
						break
					end
				end
				if blacklisted then
					return reject()
				end
			end
			
			-- If a non-whitelisted class is found, delete it
			for i,v in item:GetDescendants() do 
				local allowed = false
				for _,x in whitelistedClasses do
					if v:IsA(x) then
						allowed = true
						break
					end
				end
				if not allowed then
					v:Destroy()
				end
			end

			plr.Character.Humanoid:AddAccessory(item)
		end,
		GetPlayers = function() return service.Players:GetPlayers() end;
		IsAdonisObject = function(obj) for i,v in CreatedItems do if v == obj then return true end end end;
		GetAdonisObjects = function() return CreatedItems end;
	}

	service = setmetatable({
		Variables = function() return ServiceVariables end;
		Routine = Routine;
		Running = true;
		Pcall = Pcall;
		cPcall = cPcall;
		Threads = Threads;
		DataModel = game;
		WrapService = WrapService;
		EventService = EventService;
		ThreadService = ThreadService;
		HelperService = HelperService;
		MarketPlace = game:GetService("MarketplaceService");
		GamepassService = game:GetService("GamePassService");
		ChatService = game:GetService("Chat");
		Gamepasses = game:GetService("GamePassService");
		Delete = function(obj,num) game:GetService("Debris"):AddItem(obj,(num or 0)) pcall(obj.Destroy, obj) end;
		RbxEvent = function(signal, func) local event = signal:Connect(func) table.insert(RbxEvents, event) return event end;
		SelfEvent = function(signal, func) local rbxevent = service.RbxEvent(signal, function(...) func(...) end) end;
		DelRbxEvent = function(signal) for i,v in RbxEvents do if v == signal then v:Disconnect() table.remove(RbxEvents, i) end end end;
		SanitizeString = function(str) str = service.Trim(str) local new = "" for i = 1,#str do if string.sub(str,i,i) ~= "\n" and string.sub(str,i,i) ~= "\0" then new = new..string.sub(str,i,i) end end return new end;
    Trim = function(str) return string.match(str,"^%s*(.-)%s*$") end;
		Localize = function(obj, readOnly) local Localize = service.Localize local ReadOnly = service.ReadOnly if type(obj) == "table" then local newTab = {} for i in obj do newTab[i] = Localize(obj[i], readOnly) end return (readOnly and ReadOnly(newTab)) or newTab else return obj end end;
		RawEqual = function(obj1, obj2) return service.UnWrap(obj1) == service.UnWrap(obj2) end;
		CheckProperty = function(obj,prop) return pcall(function() return obj[prop] end) end;
		NewWaiter = function() local event = service.New("BindableEvent") return {Wait = event.wait; Finish = event.Fire} end;
	},{
		__index = function(tab, index)
			local found = (fenceSpecific and fenceSpecific[index]) or Wrapper[index] or Events[index] or Helpers[index]

			if found then
				return found
			else
				local ran, serv = pcall(function()
					local gameservice = game:GetService(index)
					return (client ~= nil and service.Wrap(gameservice, true)) or gameservice
				end)

				if ran and serv then
					service[index] = serv
					return serv
				end
			end
		end;
		__tostring = "Service";
		__metatable = if main.Core and main.Core.DebugMode then nil else "Service";
	})

	WrapService = Wrapper.Wrap(WrapService)
	HelperService = Wrapper.Wrap(HelperService)
	ThreadService = Wrapper.Wrap(ThreadService)
	EventService = Wrapper.Wrap(EventService)

	service.WrapService = WrapService
	service.HelperService = HelperService
	service.ThreadService = ThreadService
	service.EventService = EventService
	service.GoodSignal = require(script.Parent.Shared.GoodSignal)

	if client ~= nil then
		for i,val in service do
			if type(val) == "userdata" then
				service[i] = service.Wrap(val, true)
			end
		end
	end

	for i,v in Wrapper do
		if type(v) == "function" then
			WrapService:SetSpecial(i, function(ignore, ...) return v(...) end)
		else
			WrapService:SetSpecial(i, v)
		end
	end

	for i,v in Helpers do
		if type(v) == "function" then
			HelperService:SetSpecial(i, function(ignore, ...) return v(...) end)
		else
			HelperService:SetSpecial(i, v)
		end
	end

	for i,v in Threads do
		if type(v) == "function" then
			ThreadService:SetSpecial(i, function(ignore, ...) return v(...) end)
		else
			ThreadService:SetSpecial(i, v)
		end
	end

	for i,v in Events do
		if type(v) == "function" then
			EventService:SetSpecial(i, function(ignore, ...) return v(...) end)
		else
			EventService:SetSpecial(i, v)
		end
	end

	for name, service in {WrapService = WrapService, EventService = EventService, ThreadService = ThreadService, HelperService = HelperService} do
		service:SetSpecial("ClassName", name)
		service:SetSpecial("ToString", name)
		service:SetSpecial("IsA", function(i, check) return check == name end)
	end

	if service.RunService:IsClient() then
		task.spawn(xpcall, function()
			local translator = service.LocalizationService:GetTranslatorForPlayerAsync(service.Players.LocalPlayer)

			translator:GetPropertyChangedSignal("LocaleId"):Connect(function()
				changedLocale = translator.LocaleId
			end)
		end, warn)
	end

	return service
end
