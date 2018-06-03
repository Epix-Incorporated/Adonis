--[[// 
	
	https://github.com/Rerumu/Rerumu-Parser
	
\\]]--


local Encode, Decode, Extract;

local SetMeta	= setmetatable;
local Tostring	= tostring;
local Tonumber	= tonumber;
local Concat	= table.concat;
local Gsub, Sub	= string.gsub, string.sub;
local Match		= string.match;
local Type		= typeof;

local Beat					= game:GetService("RunService").Heartbeat
local C3, V3, CF, Ray, Bri	= Color3.new, Vector3.new, CFrame.new, Ray.new, BrickColor.new; -- Yell at me for this lengthy definition later.
local U2, U, V2, Inew		= UDim2.new, UDim.new, Vector2.new, Instance.new;
local Pcall					= pcall; -- Because I don't think listing everything individually would work, a bit of performance with memoization would help right?
local Index					= function(Ins, Prop) return Ins[Prop]; end;
local Properties			= setmetatable({}, {
	__index	= function(self, ClassName) -- It's not neat to have to do many checks so I decided on this.
		local Got	= {};

		self[ClassName]	= Got;

		return Got;
	end;
	__call = function(self, Instance, Property) -- Much neater to have both things here.
		local Found	= self[Instance.ClassName][Property];
		local R
		
		if (Found == nil) then
			Found, R	= Pcall(Index, Instance, Property);

			self[Instance.ClassName][Property]	= Found;

			return (Found and R) or nil;
		end;

		if Found then
			return Instance[Property];
		end;
	end;
}); -- Handles memoization of instance properties for performance boosts past 1st use.

local PropertiesStored	= { -- Was too lazy to list so you have fun.
	'ClassName', 'Name';	-- Name of properties, for obvious reasons you will always need a ClassName property (creating instance).
};

local EFormat, DFormat	= {}, {};
local Backs = {
	{'\b', '\\b'};
	{'\t', '\\t'};
	{'\n', '\\n'};
	{'\f', '\\f'};
	{'\r', '\\r'};
	{'"', '\\"'};
	{'\\', '\\\\'};
};

for Idx = 1, #Backs do
	local Pair	= Backs[Idx];

	EFormat[Pair[1]]	= Pair[2];
	DFormat[Pair[2]]	= Pair[1];
end;

Backs	= nil;

local __tMemoize	= {
	__index	= function(self, String)
		local Res	= Match(self[1], String);

		self[2]	= Res;

		return Res;
	end;
};

local function SafeString(String, EncStr)
	if EncStr then
		return (Gsub(String, '[\b\t\n\f\r\\"]', EFormat));
	else
		return (Gsub(String, '\\.', DFormat));
	end;
end;

function Extract(Data)
	local Mem	= SetMeta({Data}, __tMemoize);

	if Mem['^%[.-%]$'] then -- Things are decoded here, feel free to add.
		return Decode(Mem[2]);
	elseif Mem['^"(.-)"$'] then
		return SafeString(Mem[2]);
	elseif Mem['^true$'] then
		return true;
	elseif Mem['^false$'] then
		return false;
	elseif (Mem['^I(%[.-%])$']) then
		local InstData	= Decode(Mem[2]);
		local Inst		= Inew(InstData.ClassName);
		local Children	= InstData.Children;

		InstData.ClassName	= nil;
		InstData.Children	= nil;

		for Name, Value in next, InstData do
			Inst[Name]	= Value;
		end;

		if Children then
			for _, Child in next, Children do
				Child.Parent	= Inst;
			end;
		end;

		return Inst;
	elseif (Mem['^B%[(%d+)%]$']) then
		return Bri(Mem[2]);
	elseif (Mem['^R%[(.+)%]$']) then
		local A, B, C, X, Y, Z	= Match(Mem[2], '(.+),(.+),(.+),(.+),(.+),(.+)');

		return Ray(V3(A, B, C), V3(X, Y, Z));
	elseif (Mem['^CF%[(.+)%]$']) then
		return CF(Match(Mem[2], '(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+)'));
	elseif (Mem['^V3%[(.+)%]$']) then
		return V3(Match(Mem[2], '(.+),(.+),(.+)'));
	elseif (Mem['^V2%[(.+)%]$']) then
		return V2(Match(Mem[2], '(.+),(.+)'));
	elseif (Mem['^C3%[(.+)%]$']) then
		return C3(Match(Mem[2], '(.+),(.+),(.+)'));
	elseif (Mem['^U2%[(.+)%]$']) then
		return U2(Match(Mem[2], '(.+),(.+),(.+),(.+)'));
	elseif (Mem['^U%[(.+)%]$']) then
		return U(Match(Mem[2], '(.+),(.+)'));
	else
		return Tonumber(Data);
	end;
end;

function Encode(Table, Buff)
	local Result	= {};
	local Buff		= Buff or {};

	for Index, Value in next, Table do
		local Idx, Val	= '', 'null';
		local ValT		= Type(Value);

		if (Type(Index) == 'string') then
			Idx	= Concat{'"', SafeString(Index, true), '":'};
		end;

		if (ValT == 'number') or (ValT == 'boolean') then -- Things are encoded here; feel free to add.
			Val	= Tostring(Value);
		elseif (ValT == 'string') then
			Val	= Concat{'"', SafeString(Value, true), '"'};
		elseif (ValT == 'table') and (not Buff[Value]) then
			Buff[Value]	= true;

			Val	= Encode(Value, Buff);
		elseif (ValT == 'Instance') then
			local Child	= Value'GetChildren';
			local Props	= {};

			for _, Name in next, PropertiesStored do
				Props[Name]	= Properties(Value, Name);
			end;

			if (#Child ~= 0) then
				Props.Children	= Child;
			end;

			Val	= Concat{'I', Encode(Props)};
		elseif (ValT == 'BrickColor') then
			Val	= Concat{'B[', Value.Number, ']'};
		elseif (ValT == 'Ray') then
			local Ori, Dir	= Value.Origin, Value.Direction;

			Val	= Concat{'R[', Concat({Ori.X, Ori.Y, Ori.Z, Dir.X, Dir.Y, Dir.Z}, ','), ']'};
		elseif (ValT == 'CFrame') then
			Val	= Concat{'CF[', Concat({Value:components()}, ','), ']'};
		elseif (ValT == 'Vector3') then
			Val	= Concat{'V3[', Concat({Value.X, Value.Y, Value.Z}, ','), ']'};
		elseif (ValT == 'Vector2') then
			Val	= Concat{'V2[', Value.X, ',', Value.Y, ']'};
		elseif (ValT == 'Color3') then
			Val	= Concat{'C3[', Concat({Value.r, Value.g, Value.b}, ','), ']'};
		elseif (ValT == 'UDim2') then
			Val	= Concat{'U2[', Concat({Value.X.Scale, Value.X.Offset, Value.Y.Scale, Value.Y.Offset}, ','), ']'};
		elseif (ValT == 'UDim') then
			Val	= Concat{'U[', Value.Scale, ',', Value.Offset, ']'};
		end;

		Result[#Result + 1]	= (Idx .. Val);
	end;

	return Concat{'[', Concat(Result, ';'), ']'};
end;

function Decode(String)
	local Result	= {};
	local Tables	= 0;
	local Len		= #String;
	local Esc, Quo;
	local Layer;

	for Idx = 1, Len do
		local Char	= Sub(String, Idx, Idx);

		if Layer then
			Layer[#Layer + 1]	= Char;
		elseif (not Layer) and (Idx ~= 1) then
			Layer	= {Char};
		end;

		if (not Esc) then
			if (Char == '\\') then
				Esc	= true;
			elseif (Char == '"') then
				Quo	= (not Quo);
			elseif ((not Quo) and (Char == ';') and (Tables == 1)) or (Idx == Len) then
				local Lay	= Concat(Layer);
				local Index	= Match(Gsub(Lay, '\\"', ''), '^".-":.+$');

				if Index then
					Index	= false;

					for Idz = 2, #Layer do
						local Char	= Layer[Idz];

						if (not Index) then
							if (Char == '"') then
								Index	= Idz - 1;

								break;
							else
								Index	= (Char == '\\');
							end;
						else
							Index	= false;
						end;
					end;

					Result[SafeString(Sub(Lay, 2, Index))]	= Extract(Sub(Lay, Index + 3, -2));
				else
					Result[#Result + 1]	= Extract(Sub(Lay, 1, -2));
				end;
				
				Layer	= nil;
			elseif (not Quo) then
				if (Char == '[') then
					Tables	= Tables + 1;
				elseif (Char == ']') then
					Tables	= Tables - 1;
				end;
			end;
		else
			Esc	= false;
		end
		
		if Idx%300 == 0 then
			Beat:wait()
		end
	end;

	return Result;
end;

function noTabEncode(obj, buff)
	if not obj then return obj end 
	return Encode({_PSEUDO_TAB = true, Stuff = obj}, buff)
end

function noTabDecode(str)
	if not str then return str end
	local ret = Decode(str)
	if ret and ret._PSEUDO_TAB then 
		return ret.Stuff
	else
		return ret
	end
end

return {Encode = noTabEncode, Decode = noTabDecode, RealEncode = Encode, RealDecode = Decode};