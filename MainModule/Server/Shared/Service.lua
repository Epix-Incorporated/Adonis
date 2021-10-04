server = nil
client = nil
Pcall = nil
cPcall = nil
Routine = nil

local main
local ErrorHandler
local RealMethods = {}
local methods = setmetatable({},{
	__index = function(tab,index)
		return function(obj,...)
			local r,class = pcall(function() return obj.ClassName end)
			if r and class and obj[index] and type(obj[index]) == "function" then
				if not RealMethods[class] then
					RealMethods[class] = {}
				end

				if not RealMethods[class][index] then
					RealMethods[class][index] = obj[index]
				end

				if RealMethods[class][index] ~= obj[index] or pcall(function() return coroutine.create(obj[index]) end) then
					if ErrorHandler then
						ErrorHandler("MethodError", debug.traceback() .. " || Cached method doesn't match found method: "..tostring(index), "Method: "..tostring(index), index)
					end
				end

				return RealMethods[class][index](obj,...)
			end

			return obj[index](obj,...)
		end
	end;
	__metatable = "Methods";
})


return function(errorHandler, eventChecker, fenceSpecific)
	local _G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, time, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, elapsedTime, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay, spawn, task, tick =
		_G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, time, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, elapsedTime, require, table, type, task.wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, task.delay, task.defer, task, tick;

	main = server or client
	ErrorHandler = errorHandler

	server = nil
	client = nil

	local service;

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

	local Instance = {new = function(obj, parent) return service and client and service.Wrap(oldInstNew(obj, service.UnWrap(parent)), true) or oldInstNew(obj, parent) end}
	local Events, Threads, Wrapper, Helpers = {
		TrackTask = function(name, func, ...)
			local index = (main and main.Functions and main.Functions:GetRandom()) or math.random();
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
				data.Returns = {pcall(func, ...)}

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
				return newTask(name, func, ...)
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
			}

			function new:Trigger(self, ...)
				self.Event:Fire(...)
			end;

			function new:Delete(self)
				if not props.Temporary then
					TaskSchedulers[taskName] = nil;
				end

				new.Running = false;
				new.Event:Disconnect();
			end;

			new.Event = new.RunnerEvent.Event:Connect(function(...)
				for i,v in pairs(new.LinkedTasks) do
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
				for ind,waiter in pairs(WaitingEvents) do
					if waiter.Waiting and waiter.Timeout ~= 0 and time() - waiter.Last > waiter.Timeout then
						waiter:Remove()
					end
				end
			else
				for i,v in pairs(HookedEvents) do
					if #v == 0 then
						HookedEvents[i] = nil
					else
						for ind,waiter in pairs(WaitingEvents) do
							if waiter.Waiting and waiter.Timeout ~= 0 and time() - waiter.Last > waiter.Timeout then
								waiter:Remove()
							end
						end
					end
				end
			end
		end;

		ForEach = function(tab, func)
			for i,v in pairs(tab) do
				func(tab, i, v)
			end
		end;

		WrapEventArgs = function(tab)
			local Wrap = service.Wrap

			for i,v in pairs(tab) do
				if type(v) == "table" and v.__ISWRAPPED and v.__OBJECT then
					tab[i] = Wrap(v.__OBJECT)
				end
			end
			return tab
		end;

		UnWrapEventArgs = function(args)
			local UnWrap = service.UnWrap
			local Wrapped = service.Wrapped

			for i,v in pairs(args) do
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
				local Wrap = service.Wrap
				local UnWrap = service.UnWrap
				local Wrapped = service.Wrapped
				local WrapArgs = service.WrapEventArgs
				local UnWrapArgs = service.UnWrapEventArgs
				local event = Wrap(service.New("BindableEvent"), client)
				local hooks = {}

				event.Event:Connect(function(...)
					for i,v in pairs(hooks) do
						return v.Function(...)
					end
				end)

				event:SetSpecial("Wait", function(i, timeout)
					local special = math.random()
					local done = false
					local ret

					if timeout and type(timeout) == "number" and timeout > 0 then
						Routine(function()
							wait(timeout)
							if not done then
								UnWrap(event):Fire(special)
							end
						end)
					end

					repeat
						ret = {UnWrap(event.Event):Wait()}
					until ret[1] == 2 or ret[1] == special

					done = true

					if ret[1] == special then
						warn("Event waiter timed out [".. tostring(timeout) .."]")
						return nil
					else
						return unpack(WrapArgs(ret), 2)
					end
				end)

				event:SetSpecial("Fire", function(i, ...)
					local packedResult = table.pack(...)
					UnWrap(event):Fire(2, unpack(UnWrapArgs(packedResult), 1, packedResult.n))
				end)

				event:SetSpecial("ConnectOnce", function(i, func)
					local event2; event2 = event:Connect(function(...)
						event2:Disconnect()
						func(...)
					end)

					return event2
				end)

				event:SetSpecial("Connect", function(i, func)
					local special = math.random()
					local event2 = Wrap(UnWrap(event.Event):Connect(function(con, ...)
						local packedResult = table.pack(...)
						if con == 2 or con == special then
							func(unpack(WrapArgs(packedResult), 1, packedResult.n))
						end
					end), client)

					event2:SetSpecial("Fire", function(i, ...)
						local packedResult = table.pack(...)
						UnWrap(event):Fire(special, unpack(UnWrapArgs(packedResult), 1, packedResult.n))
					end)

					event2:SetSpecial("Wait", function(i, timeout)
						local ret

						repeat
							ret = {UnWrap(event.Event):Wait(timeout)}
						until ret[1] == 2 or ret[1] == special

						return unpack(WrapArgs(ret), 2)
					end)

					event2:SetSpecial("wait", event.Wait)
					event2:SetSpecial("disconnect", event2.Disconnect)

					return event2
				end)

				event:SetSpecial("fire", event.Fire)
				event:SetSpecial("wait", event.Wait)
				event:SetSpecial("connect", event.Connect)
				event:SetSpecial("connectOnce", event.ConnectOnce)
				event:SetSpecial("Event", service.Wrap(event.Event, client))
				event.Event:SetSpecial("Wait", event.Wait)
				event.Event:SetSpecial("wait", event.Wait)
				event.Event:SetSpecial("Connect", event.Connect)
				event.Event:SetSpecial("connect", event.Connect)

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
			for i,task in pairs(service.Threads.Tasks) do
				if not task.Thread or task:Status() == "dead" then
					task:Remove()
				end
			end
		end;

		NewTask = function(name,func,timeout)
			local pid = math.random()*os.time()/1000
			local index = pid..":"..tostring(func)
			local newTask; newTask = {
				PID = pid;
				Name = name;
				Index = index;
				Created = os.time();
				Changed = {};
				Timeout = timeout or 0;
				Running = false;
				Function = func;
				R_Status = "Idle";
				Finished = {};
				Function = function(...) newTask.R_Status = "Running" newTask.Running = true local ret = {func(...)} newTask.R_Status = "Finished" newTask.Running = false newTask.Remove() return unpack(ret) end;
				Remove = function() newTask.R_Status = "Removed" newTask.Running = false for i,v in pairs(service.Threads.Tasks) do if v == newTask then table.remove(service.Threads.Tasks,i) end end newTask.Changed:fire("Removed") newTask.Finished:fire() service.RemoveEvents(index.."_TASKCHANGED") service.RemoveEvents(index.."_TASKFINISHED") newTask.Thread = nil end;
				Thread = service.Threads.Create(function(...) return newTask.Function(...) end);
				Resume = function(...) newTask.R_Status = "Resumed" newTask.Running = true newTask.Changed:fire("Resumed") local rets = {service.Threads.Resume(newTask.Thread,...)} if not rets[1] then ErrorHandler("TaskError", rets[2]) newTask.Changed:fire("Errored",rets[2]) newTask.Remove() end return unpack(rets) end;
				Status = function() if newTask.Timeout ~= 0 and ((os.time() - newTask.Created) > newTask.Timeout) then newTask:Stop() return "timeout" else return service.Threads.Status(newTask.Thread) end end;
				Pause = function() newTask.R_Status = "Paused" newTask.Running = false service.Threads.Pause(newTask.Thread) newTask.Changed:fire("Paused") end;
				Stop = function() newTask.R_Status = "Stopping" service.Threads.Stop(newTask.Thread) newTask.Changed:fire("Stopped") newTask.Remove() end;
				Kill = function() newTask.R_Status = "Killing" service.Threads.End(newTask.Thread) newTask.Changed:fire("Killed") newTask.Remove() end;
			}

			function newTask.Changed:Connect(func)
				return service.Events[index.."_TASKCHANGED"]:Connect(func)
			end;

			function newTask.Changed:fire(...)
				service.Events[index.."_TASKCHANGED"]:fire(...)
			end

			function newTask.Finished:Connect(func)
				return service.Events[index.."_TASKFINISHED"]:Connect(func)
			end

			function newTask.Finished:wait()
				service.Events[index.."_TASKFINISHED"]:wait(0)
			end

			function newTask.Finished:fire(...)
				service.Events[index.."_TASKFINISHED"]:fire(...)
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
		Wrap = coroutine.wrap;
		Get = coroutine.running;
		New = function(func) local new = coroutine.create(func) table.insert(service.Threads.Threads,new) return new end;
		End = function(thread) repeat if thread and service.Threads.Status(thread) ~= "dead" then service.Threads.Stop(thread) service.Threads.Resume(thread) else thread = false break end until not thread or service.Threads.Status(thread) == "dead" end;
		Wrap = function(func,...) local new = service.Threads.New(func) service.Threads.Resume(func,...) return new end;
		Resume = function(thread,...) if thread and coroutine.status(thread) == "suspended" then return coroutine.resume(thread,...) end end;
		Remove = function(thread) service.Threads.Stop(thread) for ind,th in pairs(service.Threads.Threads) do if th == thread then table.remove(service.Threads.Threads,ind) end end end;
		StopAll = function() for ind,th in pairs(service.Threads.Threads) do service.Threads.Stop(th) table.remove(service.Threads.Threads,ind) end end; ResumeAll = function() for ind,th in pairs(service.Threads.Threads) do service.Threads.Resume(th) end end; GetAll = function() return service.Threads.Threads end;
	},{
		WrapIgnore = function(tab) return setmetatable(tab,{__metatable = "Ignore"}) end;
		CheckWrappers = function()
			for obj,wrap in pairs(Wrappers) do
				if service.IsDestroyed(obj) then
					Wrappers[obj] = nil
				end
			end
		end;
		Wrapped = function(object)
			return getmetatable(object) == "Adonis_Proxy"
		end;
		UnWrap = function(object)
			local OBJ_Type = typeof(object)

			if OBJ_Type == "Instance" then
				return object
			elseif OBJ_Type == "table" then
				local UnWrap = service.UnWrap
				local tab = {}
				for i, v in pairs(object) do
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
				for i,v in pairs(object) do
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

					IsRobloxLocked = main and main.Anti and function()
						return main.Anti.RLocked(object)
					end or function() end;

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
				newMeta.__metatable = "Adonis_Proxy"

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
			for i,v in pairs(tab) do
				new[i] = v
			end
			return new
		end;

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

		Unpack = function(tab,ind,limit)
			if (not limit and tab[ind or 1] ~= nil) or (limit and (ind or 1) <= limit) then
				return tab[ind or 1], service.Unpack(tab,(ind or 1)+1,limit)
			end
		end;

		AltUnpack = function(args,shift)
			if shift then shift = shift-1 end
			return args[1+(shift or 0)],args[2+(shift or 0)],args[3+(shift or 0)],args[4+(shift or 0)],args[5+(shift or 0)],args[6+(shift or 0)],args[7+(shift or 0)],args[8+(shift or 0)],args[9+(shift or 0)],args[10+(shift or 0)]
		end;

		ExtractLines = function(str)
			local strs = {}
			local new = ""
			for i=1,#str+1 do
				if string.byte(str:sub(i,i)) == 10 or i == #str+1 then
					table.insert(strs,new)
					new = ""
				else
					local char = str:sub(i,i)
					if string.byte(char) < 32 then
						char = ""
					end
					new = new..char
				end
			end
			return strs
		end;

		Filter = function(str,from,to)
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
					new = new.."\n"..newl
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

		BroadcastFilter = function(str,from)
			if not utf8.len(str) then
				return "Filter Error"
			end

			local new = ""
			local lines = service.ExtractLines(str)
			for i = 1,#lines do
				local ran,newl = pcall(function() return service.TextService:FilterStringAsync(lines[i],from.UserId):GetNonChatStringForBroadcastAsync() end)
				newl = (ran and newl) or lines[i] or ""
				if i > 1 then
					new = new.."\n"..newl
				else
					new = newl
				end
			end
			return new or "Filter Error"
		end;

		MetaFunc = function(func)
	    return service.NewProxy {
	        __call = function(tab,...)
	            local args = {pcall(func, ...)}
	            local success = args[1]
	            if not success then
	                warn(args[2])
	            else
	                return unpack(args, 2)
	            end
	        end
	    }
		end;

		NewProxy = function(meta)
			local newProxy = newproxy(true)
			local metatable = getmetatable(newProxy)
			metatable.__metatable = false
			for i,v in pairs(meta) do metatable[i] = v end
			return newProxy
		end;

		GetUserType = function(obj)
			local ran,err = pcall(function() local temp = obj[math.random()] end)
			if ran then
				return "Unknown"
			else
				return err:match("%S+$")
			end
		end;

		CountTable = function(tab)
			local num = 0
			for _ in pairs(tab) do num += 1 end
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
				service.TrackTask("Thread: QueueProcessor_"..tostring(key), service.ProcessQueue, queue, key);
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
									warn("Queue Timeout Reached for ".. tostring(key or "Unknown"))

									if func.Yield then
										func.Yield:Release(false, "Timeout Reached");
									end
								end
							end)
						end

						service.TrackTask("Thread: ".. tostring(key or "Unknown") .."_QueuedFunction", function()
							local r,e = pcall(func.Function);

							if not r then
								func.Error = e;
								warn("Queue Error: ".. tostring(key) .. ": ".. tostring(e))
							end

							func.Running = false;
							func.Finished = true

							if func.Yield then
								func.Yield:Release(r, e)
							end

							Yield:Release();
						end)

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
			for ind,data in pairs(LoopQueue) do
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

		New = function(class,data)
			local new = Instance.new(class)
			if data then
				if type(data) == "table" then
					local parent = data.Parent
					if service.Wrapped(parent) then parent = parent:GetObject() end
					data.Parent = nil

					for val,prop in pairs(data) do
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

			if new then
				table.insert(CreatedItems, new)
			end

			return new
		end;

		Iterate = function(tab,func)
			if tab and type(tab) == "table" then
				for ind,val in pairs(tab) do
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

		GetTime = function()
			return os.time();
		end;

		FormatTime = function(optTime, withDate)
			local formatString = withDate and "L LT" or "LT"
			local tim = DateTime.fromUnixTimestamp(optTime or service.GetTime())
			if service.RunService:IsServer() then
				return tim:FormatUniversalTime(formatString, "en-gb") -- Always show UTC in 24 hour format
			else
				local locale = service.Players.LocalPlayer.LocaleId
				local succes,err = pcall(function()
					return tim:FormatLocalTime(formatString, locale) -- Show in player's local timezone and format
				end)
				if err then
					return tim:FormatLocalTime(formatString, "en-gb") -- show UTC in 24 hour format because player's local timezone is not available in DateTimeLocaleConfigs
				end
			end
		end;

		OwnsAsset = function(p,id)
			return service.MarketPlace:PlayerOwnsAsset(p,id)
		end;

		MaxLen = function(message,length)
			if #message>length then
				return message:sub(1,length).."..."
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

			local index = tostring(name).." - "..main.Functions:GetRandom()

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
				service.TrackTask("Thread: Loop: ".. name, loop)
			else
				service.TrackTask("Loop: ".. name, loop)
			end

			--[[local task = service.Threads.RunTask("LOOP:"..name, loop)

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
			for ind,loop in pairs(RunningLoops) do
				if name == loop.Function or name == loop.Name then
					loop.Running = false
				end
			end
		end;
		FindClass = function(parent, class)
			for ind, child in pairs(parent:GetChildren()) do
				if child:IsA(class) then
					return child
				end
			end
		end;
		Immutable = function(...)
			local co = coroutine.wrap(function(...) while true do coroutine.yield(...) end end)
			co(...)
			return co
		end;
		ReadOnly = function(tabl, excluded, killOnError, noChecks)
			local doChecks = (not noChecks) and service.RunService:IsClient()
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
			}

			return service.NewProxy {
				__index = function(tab, ind)
					local topEnv = doChecks and get and get(2)
					local setRan = doChecks and pcall(settings)
					if doChecks and (setRan or (get ~= getfenv or getMeta ~= getmetatable or pc ~= pcall) or (not topEnv or type(topEnv) ~= "table" or getMeta(topEnv) ~= unique)) then
						ErrorHandler("ReadError", "Tampering with Client [read rt0001]", "["..tostring(ind).. " " .. tostring(topEnv) .. " " .. tostring(topEnv and getMeta(topEnv)).."]\n".. tostring(debug.traceback()))
						--elseif doChecks and (function() local ran,err = pc(function() for i in next,checkFor do if topEnv[i] then return true end end return false end) if not ran or ran and err then return true end end)() then
						--	ErrorHandler("ReadError", "Tampering with Client [read rt0002]", "["..tostring(ind).. " " .. tostring(topEnv) .. " " .. tostring(topEnv and getMeta(topEnv)).."]\n".. tostring(debug.traceback()))
					elseif tabl[ind]~=nil and type(tabl[ind]) == "table" and not (excluded and (excluded[ind] or excluded[tabl[ind]])) then
						return service.ReadOnly(tabl[ind], excluded, killOnError, noChecks)
					else
						return tabl[ind]
					end
				end;

				__newindex = function(tab,ind,new)
					local topEnv = doChecks and get and get(2)
					local setRan = doChecks and pcall(settings)
					if doChecks and (setRan or (get ~= getfenv or getMeta ~= getmetatable or pc ~= pcall) or (not topEnv or type(topEnv) ~= "table" or getMeta(topEnv) ~= unique)) then
						ErrorHandler("ReadError", "Tampering with Client [write wt0003]", "["..tostring(ind).. " " .. tostring(topEnv) .. " " .. tostring(topEnv and getMeta(topEnv)).."]\n".. tostring(debug.traceback()))
						--elseif doChecks and (function() local ran,err = pc(function() for i in next,checkFor do if topEnv[i] then return true end end return false end) if not ran or ran and err then return true end end)() then
						--	ErrorHandler("ReadError", "Tampering with Client [write wt0004]", "["..tostring(ind).. " " .. tostring(topEnv) .. " " .. tostring(topEnv and getMeta(topEnv)).."]\n".. tostring(debug.traceback()))
					elseif not (excluded and (excluded[ind] or excluded[tabl[ind]])) then
						if killOnError then
							ErrorHandler("ReadError", "Tampering with Client [write wt0005]", "["..tostring(ind).. " " .. tostring(topEnv) .. " " .. tostring(topEnv and getMeta(topEnv)).."]\n".. tostring(debug.traceback()))
						end

						warn("Something attempted to set index ".. tostring(ind) .." in a read-only table.")
					else
						rawset(tabl, ind, new)
					end
				end;

				__metatable = "ReadOnly_Table";
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
		ForEach = function(tab, func) for i,v in pairs(tab) do func(tab,i,v) end return tab end;
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
		Insert = function(id, rawModel)
			local model = service.InsertService:LoadAsset(id)
			if not rawModel and model:IsA("Model") and model.Name == "Model" then
				local asset = model:GetChildren()[1]
				asset.Parent = model.Parent
				model:Destroy()
				return asset
			end
			return model
		end;
		GetPlayers = function() return service.Players:GetPlayers() end;
		IsAdonisObject = function(obj) for i,v in pairs(CreatedItems) do if v == obj then return true end end end;
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
		DelRbxEvent = function(signal) for i,v in pairs(RbxEvents) do if v == signal then v:Disconnect() table.remove(RbxEvents, i) end end end;
		SanitizeString = function(str) str = service.Trim(str) local new = "" for i = 1,#str do if string.sub(str,i,i) ~= "\n" and string.sub(str,i,i) ~= "\0" then new = new..string.sub(str,i,i) end end return new end;
		Trim = function(str) return string.match(str,"^%s*(.-)%s*$") end;
		Round = function(num) return math.floor(num + 0.5) end;
		Localize = function(obj, readOnly) local Localize = service.Localize local ReadOnly = service.ReadOnly if type(obj) == "table" then local newTab = {} for i in pairs(obj) do newTab[i] = Localize(obj[i], readOnly) end return (readOnly and ReadOnly(newTab)) or newTab else return obj end end;
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
		__metatable = "Service";
	})

	WrapService = Wrapper.Wrap(WrapService)
	HelperService = Wrapper.Wrap(HelperService)
	ThreadService = Wrapper.Wrap(ThreadService)
	EventService = Wrapper.Wrap(EventService)

	service.WrapService = WrapService
	service.HelperService = HelperService
	service.ThreadService = ThreadService
	service.EventService = EventService

	if client ~= nil then
		for i,val in pairs(service) do
			if type(val) == "userdata" then
				service[i] = service.Wrap(val, true)
			end
		end
	end

	for i,v in pairs(Wrapper) do
		if type(v) == "function" then
			WrapService:SetSpecial(i, function(ignore, ...) return v(...) end)
		else
			WrapService:SetSpecial(i, v)
		end
	end

	for i,v in pairs(Helpers) do
		if type(v) == "function" then
			HelperService:SetSpecial(i, function(ignore, ...) return v(...) end)
		else
			HelperService:SetSpecial(i, v)
		end
	end

	for i,v in pairs(Threads) do
		if type(v) == "function" then
			ThreadService:SetSpecial(i, function(ignore, ...) return v(...) end)
		else
			ThreadService:SetSpecial(i, v)
		end
	end

	for i,v in pairs(Events) do
		if type(v) == "function" then
			EventService:SetSpecial(i, function(ignore, ...) return v(...) end)
		else
			EventService:SetSpecial(i, v)
		end
	end

	for name, service in pairs({WrapService = WrapService, EventService = EventService, ThreadService = ThreadService, HelperService = HelperService}) do
		service:SetSpecial("ClassName", name)
		service:SetSpecial("ToString", name)
		service:SetSpecial("IsA", function(i, check) return check == name end)
	end

	return service
end
