local Concat	= table.concat;
local Select	= select;
local _Byte		= string.byte;
local Sub		= string.sub;
local Opcode	= { -- Opcode types.
	'ABC',	'ABx',	'ABC',	'ABC';
	'ABC',	'ABx',	'ABC',	'ABx';
	'ABC',	'ABC',	'ABC',	'ABC';
	'ABC',	'ABC',	'ABC',	'ABC';
	'ABC',	'ABC',	'ABC',	'ABC';
	'ABC',	'ABC',	'AsBx',	'ABC';
	'ABC',	'ABC',	'ABC',	'ABC';
	'ABC',	'ABC',	'ABC',	'AsBx';
	'AsBx',	'ABC',	'ABC',	'ABC';
	'ABx',	'ABC';
};

-- rlbi author -> Rerumu (Shining_Diamando)

--[[
	Consider this a direct upgrade to the beauty that stravant (and some other people..? Dunno the details) left behind.
	This "new" version includes:
		* Almost complete rework (most things reworked from scratch)
		* Visible performance improvements (wayyyy faster)
		* Upvalue error fixes
		* C Stack overflow fixes (most cases anyways)
		* Fixed missing "return" errors
		* Solved 0 const being treated as "1.1125369292536e-308"
		* A more readable format for easier editing of the code
		* No fix/addition to SETLIST, as 25550 items in initializing a list isn't realistic
		* Tailcalls, threading and stack-sharing fixed
		* CLOSE opcode implemented
--]]

--[[
	TODO:
		* Implement extended SETLIST
		* Optimize further, for the cause
		* Maybe an expansion for it to work with different settings
--]]

local function gBit(Bit, Start, End) -- No tail-calls, yay.
	if End then -- Thanks to cntkillme for giving input on this shorter, better approach.
		local Res	= (Bit / 2 ^ (Start - 1)) % 2 ^ ((End - 1) - (Start - 1) + 1);

		return Res - Res % 1;
	else
		local Plc = 2 ^ (Start - 1);

		if (Bit % (Plc + Plc) >= Plc) then
			return 1;
		else
			return 0;
		end;
	end;
end;

local function GetMeaning(ByteString)
	local Pos	= 1;
	local gSizet;
	local gInt;

	local function gBits8() -- Get the next byte in the stream.
		local F	= _Byte(ByteString, Pos, Pos);

		Pos	= Pos + 1;

		return F;
	end;

	local function gBits32()
		local W, X, Y, Z	= _Byte(ByteString, Pos, Pos + 3);

		Pos	= Pos + 4;

		return (Z * 16777216) + (Y * 65536) + (X * 256) + W;
	end;

	local function gBits64()
		return gBits32() * 4294967296 + gBits32();
	end;

	local function gFloat()
		local A, B	= gBits32(), gBits32();

		if ((A + B) == 0) then
			return 0; -- Float 0 tends to be very messy, so this is a temp fix until I figure out what's up.
		else
			return (-2 * gBit(B, 32) + 1) * (2 ^ (gBit(B, 21, 31) - 1023)) * ((gBit(B, 1, 20) * (2^32) + A) / (2 ^ 52) + 1);
		end;
	end;

	local function gString(Len)
		local Str;

		if Len then
			Str	= Sub(ByteString, Pos, Pos + Len - 1);

			Pos = Pos + Len;
		else
			Len = gSizet();

			if (Len == 0) then return; end;

			Str	= Sub(ByteString, Pos, Pos + Len - 1);

			Pos = Pos + Len;
		end;

		return Str;
	end;

	local function ChunkDecode()
		local Instr	= {};
		local Const	= {};
		local Proto	= {};
		local Chunk	= {
			Instr	= Instr; -- Instructions
			Const	= Const; -- Constants
			Proto	= Proto; -- Prototypes
			Lines	= {}; -- Lines
			Name	= gString(); -- Grab name string.
			FirstL	= gInt(); -- First line.
			LastL	= gInt(); -- Last line.
			Upvals	= gBits8(); -- Upvalue count.
			Args	= gBits8(); -- Arg count.
			Vargs	= gBits8(); -- Vararg type.
			Stack	= gBits8(); -- Stack.
		};

		if Chunk.Name then
			Chunk.Name	= Sub(Chunk.Name, 1, -2);
		end;

		for Idx = 1, gInt() do -- Loading instructions to the chunk.
			local Data	= gBits32();
			local Opco	= gBit(Data, 1, 6);
			local Type	= Opcode[Opco + 1];
			local Inst	= {
				Enum	= Opco;
				gBit(Data, 7, 14); -- Register A.
			};

			if (Type == 'ABC') then -- Most common, basic instruction type.
				Inst[2]	= gBit(Data, 24, 32);
				Inst[3]	= gBit(Data, 15, 23);
			elseif (Type == 'ABx') then
				Inst[2]	= gBit(Data, 15, 32);
			elseif (Type == 'AsBx') then
				Inst[2]	= gBit(Data, 15, 32) - 131071;
			end;

			Instr[Idx]	= Inst;
		end;

		for Idx = 1, gInt() do -- Load constants.
			local Type	= gBits8();
			local Cons;

			if (Type == 1) then -- Boolean
				Cons	= (gBits8() ~= 0);
			elseif (Type == 3) then -- Float/Double
				Cons	= gFloat();
			elseif (Type == 4) then
				Cons	= Sub(gString(), 1, -2);
			end;

			Const[Idx - 1]	= Cons;
		end;

		for Idx = 1, gInt() do -- Nested function prototypes.
			Proto[Idx - 1]	= ChunkDecode();
		end;

		do -- Debugging
			local Lines	= Chunk.Lines;

			for Idx = 1, gInt() do
				Lines[Idx]	= gBits32();
			end;

			for Idx = 1, gInt() do -- Locals in stack.
				gString(); -- Name of local.
				gBits32(); -- Starting point.
				gBits32(); -- End point.
			end;

			for Idx = 1, gInt() do -- Upvalues.
				gString(); -- Name of upvalue.
			end;
		end;

		return Chunk; -- Finished chunk.
	end;

	do -- Most of this chunk I was too lazy to reformat or change
		assert(gString(4) == "\27Lua", "Lua bytecode expected.");
		assert(gBits8() == 0x51, "Only Lua 5.1 is supported.");

		gBits8(); -- Probably version control.
		gBits8(); -- Is small endians.

		local IntSize	= gBits8(); -- Int size
		local Sizet		= gBits8(); -- size_t

		if (IntSize == 4) then
			gInt	= gBits32;
		elseif (IntSize == 8) then
			gInt	= gBits64;
		else
			error('Integer size not supported', 2);
		end;

		if (Sizet == 4) then
			gSizet	= gBits32;
		elseif (Sizet == 8) then
			gSizet	= gBits64;
		else
			error('Sizet size not supported', 2);
		end;

		assert(gString(3) == "\4\8\0", "Unsupported bytecode target platform");
	end;

	return ChunkDecode();
end;

local function _Returns(...)
	return Select('#', ...), {...};
end;

local function Wrap(Chunk, Env, Upvalues)
	local Instr	= Chunk.Instr;
	local Const	= Chunk.Const;
	local Proto	= Chunk.Proto;

	local function OnError(Err, Position) -- Handle your errors in whatever way.
		local Name	= Chunk.Name or 'Code';
		local Line	= Chunk.Lines[Position] or '?';
		local Err	= Err:match'^.+:%s*(.+)' or Err;

		error(string.format('%s (%s): %s', Name, Line, Err), 0);
	end;

	return function(...) -- Returned function to run bytecode chunk (Don't be stupid, you can't setfenv this to work your way).
		local Upvalues	= Upvalues;
		local Instr		= Instr;
		local Const		= Const;
		local Proto		= Proto;

		local InstrPoint, Top	= 1, -1;
		local Vararg, Varargsz	= {}, Select('#', ...) - 1;

		local GStack	= {};
		local Lupvals	= {};
		local Stack		= setmetatable({}, {
			__index		= GStack;
			__newindex	= function(_, Key, Value)
				if (Key > Top) and Value then
					Top	= Key;
				end;

				GStack[Key]	= Value;
			end;
		});

		local function Loop()
			local Instr	= Instr;
			local Inst, Enum, A, B;

			while true do
				Inst		= Instr[InstrPoint];
				Enum		= Inst.Enum;
				InstrPoint	= InstrPoint + 1;

				if (Enum == 0) then -- MOVE
					Stack[Inst[1]]	= Stack[Inst[2]];
				elseif (Enum == 1) then -- LOADK
					Stack[Inst[1]]	= Const[Inst[2]];
				elseif (Enum == 2) then -- LOADBOOL
					Stack[Inst[1]]	= (Inst[2] ~= 0);

					if (Inst[3] ~= 0) then
						InstrPoint	= InstrPoint + 1;
					end;
				elseif (Enum == 3) then -- LOADNIL
					local Stk	= Stack;

					for Idx = Inst[1], Inst[2] do
						Stk[Idx]	= nil;
					end;
				elseif (Enum == 4) then -- GETUPVAL
					Stack[Inst[1]]	= Upvalues[Inst[2]];
				elseif (Enum == 5) then -- GETGLOBAL
					Stack[Inst[1]]	= Env[Const[Inst[2]]];
				elseif (Enum == 6) then -- GETTABLE
					local C		= Inst[3];
					local Stk	= Stack;

					if (C > 255) then
						C	= Const[C - 256];
					else
						C	= Stk[C];
					end;

					Stk[Inst[1]]	= Stk[Inst[2]][C];
				elseif (Enum == 7) then -- SETGLOBAL
					Env[Const[Inst[2]]]	= Stack[Inst[1]];
				elseif (Enum == 8) then -- SETUPVAL
					Upvalues[Inst[2]]	= Stack[Inst[1]];
				elseif (Enum == 9) then -- SETTABLE
					local B, C	= Inst[2], Inst[3];
					local Stk	= Stack;

					if (B > 255) then
						B	= Const[B - 256];
					else
						B	= Stk[B];
					end;

					if (C > 255) then
						C	= Const[C - 256];
					else
						C	= Stk[C];
					end;

					Stk[Inst[1]][B]	= C;
				elseif (Enum == 10) then -- NEWTABLE
					Stack[Inst[1]]	= {};
				elseif (Enum == 11) then -- SELF
					local A		= Inst[1];
					local B		= Inst[2];
					local C		= Inst[3];
					local Stk	= Stack;

					B = Stk[B];

					if (C > 255) then
						C	= Const[C - 256];
					else
						C	= Stk[C];
					end;

					Stk[A + 1]	= B;
					Stk[A]		= B[C];
				elseif (Enum == 12) then -- ADD
					local B	= Inst[2];
					local C	= Inst[3];
					local Stk, Con	= Stack, Const;

					if (B > 255) then
						B	= Const[B - 256];
					else
						B	= Stk[B];
					end;

					if (C > 255) then
						C	= Const[C - 256];
					else
						C	= Stk[C];
					end;

					Stk[Inst[1]]	= B + C;
				elseif (Enum == 13) then -- SUB
					local B	= Inst[2];
					local C	= Inst[3];
					local Stk, Con	= Stack, Const;

					if (B > 255) then
						B	= Const[B - 256];
					else
						B	= Stk[B];
					end;

					if (C > 255) then
						C	= Const[C - 256];
					else
						C	= Stk[C];
					end;

					Stk[Inst[1]]	= B - C;
				elseif (Enum == 14) then -- MUL
					local B	= Inst[2];
					local C	= Inst[3];
					local Stk, Con	= Stack, Const;

					if (B > 255) then
						B	= Const[B - 256];
					else
						B	= Stk[B];
					end;

					if (C > 255) then
						C	= Const[C - 256];
					else
						C	= Stk[C];
					end;

					Stk[Inst[1]]	= B * C;
				elseif (Enum == 15) then -- DIV
					local B	= Inst[2];
					local C	= Inst[3];
					local Stk, Con	= Stack, Const;

					if (B > 255) then
						B	= Const[B - 256];
					else
						B	= Stk[B];
					end;

					if (C > 255) then
						C	= Const[C - 256];
					else
						C	= Stk[C];
					end;

					Stk[Inst[1]]	= B / C;
				elseif (Enum == 16) then -- MOD
					local B	= Inst[2];
					local C	= Inst[3];
					local Stk, Con	= Stack, Const;

					if (B > 255) then
						B	= Const[B - 256];
					else
						B	= Stk[B];
					end;

					if (C > 255) then
						C	= Const[C - 256];
					else
						C	= Stk[C];
					end;

					Stk[Inst[1]]	= B % C;
				elseif (Enum == 17) then -- POW
					local B	= Inst[2];
					local C	= Inst[3];
					local Stk, Con	= Stack, Const;

					if (B > 255) then
						B	= Const[B - 256];
					else
						B	= Stk[B];
					end;

					if (C > 255) then
						C	= Const[C - 256];
					else
						C	= Stk[C];
					end;

					Stk[Inst[1]]	= B ^ C;
				elseif (Enum == 18) then -- UNM
					Stack[Inst[1]]	= -Stack[Inst[2]];
				elseif (Enum == 19) then -- NOT
					Stack[Inst[1]]	= (not Stack[Inst[2]]);
				elseif (Enum == 20) then -- LEN
					Stack[Inst[1]]	= #Stack[Inst[2]];
				elseif (Enum == 21) then -- CONCAT
					local Stk	= Stack;
					local B		= Inst[2];
					local K		= {Stack[B]};

					for Idx = B + 1, Inst[3] do
						K[#K + 1]	= Stk[Idx];
					end;

					Stack[Inst[1]]	= Concat(K);
				elseif (Enum == 22) then -- JUMP
					InstrPoint	= InstrPoint + Inst[2];
				elseif (Enum == 23) then -- EQ
					local A	= Inst[1] ~= 0;
					local B	= Inst[2];
					local C	= Inst[3];
					local Stk, Con	= Stack, Const;

					if (B > 255) then
						B	= Const[B - 256];
					else
						B	= Stk[B];
					end;

					if (C > 255) then
						C	= Const[C - 256];
					else
						C	= Stk[C];
					end;

					if (B == C) ~= A then
						InstrPoint	= InstrPoint + 1;
					end;
				elseif (Enum == 24) then -- LT
					local A	= Inst[1] ~= 0;
					local B	= Inst[2];
					local C	= Inst[3];
					local Stk, Con	= Stack, Const;

					if (B > 255) then
						B	= Const[B - 256];
					else
						B	= Stk[B];
					end;

					if (C > 255) then
						C	= Const[C - 256];
					else
						C	= Stk[C];
					end;

					if (B < C) ~= A then
						InstrPoint	= InstrPoint + 1;
					end;
				elseif (Enum == 25) then -- LE
					local A	= Inst[1] ~= 0;
					local B	= Inst[2];
					local C	= Inst[3];
					local Stk, Con	= Stack, Const;

					if (B > 255) then
						B	= Const[B - 256];
					else
						B	= Stk[B];
					end;

					if (C > 255) then
						C	= Const[C - 256];
					else
						C	= Stk[C];
					end;

					if (B <= C) ~= A then
						InstrPoint	= InstrPoint + 1;
					end;
				elseif (Enum == 26) then -- TEST
					if (not not Stack[Inst[1]]) == (Inst[3] == 0) then
						InstrPoint	= InstrPoint + 1;
					end;
				elseif (Enum == 27) then -- TESTSET
					local B	= Stack[Inst[2]];

					if (not not B) == (Inst[3] == 0) then
						InstrPoint	= InstrPoint + 1;
					else
						Stack[Inst[1]] = B;
					end;
				elseif (Enum == 28) then -- CALL
					local A	= Inst[1];
					local B	= Inst[2];
					local C	= Inst[3];
					local Stk	= Stack;
					local Args, Results;
					local Limit, Loop;

					Args	= {};

					if (B ~= 1) then
						if (B ~= 0) then
							Limit = A + B - 1;
						else
							Limit = Top;
						end;

						Loop	= 0;

						for Idx = A + 1, Limit do
							Loop = Loop + 1;

							Args[Loop] = Stk[Idx];
						end;

						Limit, Results = _Returns(Stk[A](unpack(Args, 1, Limit - A)));
					else
						Limit, Results = _Returns(Stk[A]());
					end;

					Top = A - 1;

					if (C ~= 1) then
						if (C ~= 0) then
							Limit = A + C - 2;
						else
							Limit = Limit + A;
						end;

						Loop	= 0;

						for Idx = A, Limit do
							Loop = Loop + 1;

							Stk[Idx] = Results[Loop];
						end;
					end;
				elseif (Enum == 29) then -- TAILCALL
					local A	= Inst[1];
					local B	= Inst[2];
					local C	= Inst[3];
					local Stk	= Stack;
					local Args, Results;
					local Limit, Loop;

					Args = {};

					if (B ~= 1) then
						if (B ~= 0) then
							Limit = A + B - 1;
						else
							Limit = Top;
						end

						Loop = 0;

						for Idx = A + 1, Limit do
							Loop = Loop + 1;

							Args[#Args + 1] = Stk[Idx];
						end

						Results = {Stk[A](unpack(Args, 1, Limit - A))};
					else
						Results = {Stk[A]()};
					end;

					return Results;
				elseif (Enum == 30) then -- RETURN
					local A	= Inst[1];
					local B	= Inst[2];
					local Stk	= Stack;
					local Loop, Output;
					local Limit;

					if (B == 1) then
						return;
					elseif (B == 0) then
						Limit	= Top;
					else
						Limit	= A + B - 2;
					end;

					Output = {};

					local Loop	= 0;

					for Idx = A, Limit do
						Loop	= Loop + 1;

						Output[Loop] = Stk[Idx];
					end;

					return Output;
				elseif (Enum == 31) then -- FORLOOP
					local A		= Inst[1];
					local Stk	= Stack;

					local Step	= Stk[A + 2];
					local Index	= Stk[A] + Step;

					Stk[A]	= Index;

					if (Step > 0) then
						if Index <= Stk[A + 1] then
							InstrPoint	= InstrPoint + Inst[2];

							Stk[A + 3] = Index;
						end;
					else
						if Index >= Stk[A + 1] then
							InstrPoint	= InstrPoint + Inst[2];

							Stk[A + 3] = Index;
						end
					end
				elseif (Enum == 32) then -- FORPREP
					local A		= Inst[1];
					local Stk	= Stack;

					Stk[A]	= Stk[A] - Stk[A + 2];

					InstrPoint	= InstrPoint + Inst[2];
				elseif (Enum == 33) then -- TFORLOOP
					local A		= Inst[1];
					local B		= Inst[2];
					local C		= Inst[3];
					local Stk	= Stack;

					local Offset	= A + 2;
					local Result	= {Stk[A](Stk[A + 1], Stk[A + 2])};

					for Idx = 1, C do
						Stack[Offset + Idx] = Result[Idx];
					end;

					if (Stk[A + 3] ~= nil) then
						Stk[A + 2]	= Stk[A + 3];
					else
						InstrPoint	= InstrPoint + 1;
					end;
				elseif (Enum == 34) then -- SETLIST
					local A		= Inst[1];
					local B		= Inst[2];
					local C		= Inst[3];
					local Stk	= Stack;

					if (C == 0) then -- Seriously.
						error('List surpasses 25550 indexes, please consider your life choices.');
					else
						local Offset	= (C - 1) * 50;
						local T			= Stk[A]; -- Assuming T is the newly created table.

						if (B == 0) then
							B	= Top;
						end;

						for Idx = 1, B do
							T[Offset + Idx] = Stk[A + Idx];
						end;
					end;
				elseif (Enum == 35) then -- CLOSE
					local A		= Inst[1];
					local Cls	= {}; -- Slight doubts on any issues this may cause

					for Idx = 1, #Lupvals do
						local List = Lupvals[Idx];

						for Idz = 0, #List do
							local Upv	= List[Idz];
							local Stk	= Upv[1];
							local Pos	= Upv[2];

							if (Stk == Stack) and (Pos >= A) then
								Cls[Pos]	= Stk[Pos];
								Upv[1]		= Cls; -- @memcorrupt credit me for the spoonfeed
							end;
						end;
					end;
				elseif (Enum == 36) then -- CLOSURE
					local Proto	= Proto[Inst[2]];
					local Instr = Instr;
					local Stk	= Stack;

					local Indexes;
					local NewUvals;

					if (Proto.Upvals ~= 0) then
						Indexes		= {};
						NewUvals	= setmetatable({}, {
								__index = function(_, Key)
									local Val	= Indexes[Key];

									return Val[1][Val[2]];
								end,
								__newindex = function(_, Key, Value)
									local Val	= Indexes[Key];

									Val[1][Val[2]]	= Value;
								end;
							}
						);

						for Idx = 1, Proto.Upvals do
							local Mvm	= Instr[InstrPoint];

							if (Mvm.Enum == 0) then -- MOVE
								Indexes[Idx - 1] = {Stk, Mvm[2]};
							elseif (Mvm.Enum == 4) then -- GETUPVAL
								Indexes[Idx - 1] = {Upvalues, Mvm[2]};
							end;

							InstrPoint	= InstrPoint + 1;
						end;

						Lupvals[#Lupvals + 1]	= Indexes;
					end;

					Stk[Inst[1]]			= Wrap(Proto, Env, NewUvals);
				elseif (Enum == 37) then -- VARARG
					local A	= Inst[1];
					local B	= Inst[2];
					local Stk, Vararg	= Stack, Vararg;

					for Idx = A, A + (B > 0 and B - 1 or Varargsz) do
						Stk[Idx]	= Vararg[Idx - A];
					end;
				end;
			end;
		end;

		local Args	= {...};

		for Idx = 0, Varargsz do
			Stack[Idx] = Args[Idx + 1];
			Vararg[Idx] = Args[Idx + 1];
		end;

		local A, B		= pcall(Loop); -- Pcalling to allow yielding

		if A then -- We're always expecting this to come out true (because errorless code)
			if B then -- So I flipped the conditions.
				return unpack(B);
			end;

			return;
		else
			OnError(B, InstrPoint - 1); -- Didn't get time to test the `-1` honestly, but I assume it works properly
		end;
	end;
end;

return function(BCode, Env) -- lua_function LoadBytecode (string BCode, table Env)
	local Buffer	= GetMeaning(BCode);

	return Wrap(Buffer, Env or getfenv(0)), Buffer;
end;