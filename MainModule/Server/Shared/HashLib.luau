--!native
--!optimize 2
--!strict
--[[
	Description: SHA256 digest hash
	Author: XoifailTheGod
	Date: 2024
	Link: https://devforum.roblox.com/t/fastest-sha256-module/3180016
]]

local MODULO = 2^32
local BYTE, DWORD = 1, 4

local CONSTANTS = buffer.create(64 * DWORD) do -- CONSTANTS = k
	local RoundConstants = {
		0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
		0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
		0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
		0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
		0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
		0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
		0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
		0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
	}

	for Index, Constant in ipairs(RoundConstants) do
		local BufferOffset = (Index - 1) * DWORD
		buffer.writeu32(CONSTANTS, BufferOffset, Constant)
	end
end

local HASH_VALUES = buffer.create(8 * DWORD) do -- HASH_VALUES = h0-h7
	buffer.writeu32(HASH_VALUES, 0,	0x6a09e667)
	buffer.writeu32(HASH_VALUES, 4, 0xbb67ae85)
	buffer.writeu32(HASH_VALUES, 8,	0x3c6ef372)
	buffer.writeu32(HASH_VALUES, 12, 0xa54ff53a)
	buffer.writeu32(HASH_VALUES, 16, 0x510e527f)
	buffer.writeu32(HASH_VALUES, 20, 0x9b05688c)
	buffer.writeu32(HASH_VALUES, 24, 0x1f83d9ab)
	buffer.writeu32(HASH_VALUES, 28, 0x5be0cd19)
end

local function ProcessNumber(Input: number, Length: number): buffer
	local OutputBuffer = buffer.create(Length)

	for Index = Length - 1, 0, -1 do
		local Remainder = Input % 256
		buffer.writeu8(OutputBuffer, Index, Remainder)
		Input = bit32.rshift(Input, 8)
	end

	return OutputBuffer
end

local function PreProcess(Content: buffer): (buffer, number)
	local ContentLength = buffer.len(Content)
	local Padding = (64 - ((ContentLength + 9) % 64)) % 64

	local NewContentLength = ContentLength + 1 + Padding + 8
	local NewContent = buffer.create(NewContentLength)
	buffer.copy(NewContent, 0, Content)
	buffer.writeu8(NewContent, ContentLength, 128)
	local Length8 = ContentLength * 8
	for Index = 7, 0, -1 do
		local Remainder = Length8 % 256
		buffer.writeu8(NewContent, Index + ContentLength + 1 + Padding, Remainder)
		Length8 = (Length8 - Remainder) / 256
	end

	return NewContent, NewContentLength
end

local Offsets = buffer.create(256)
local function DigestBlock(Blocks: buffer, Offset: number, A: number, B: number, C: number, D: number, E: number, F: number, G: number, H: number)
	for BlockIndex = 0, 60, 4 do
		local BlockBufferIndex = Offset + BlockIndex
		local Word = bit32.byteswap(buffer.readu32(Blocks, BlockBufferIndex))

		buffer.writeu32(Offsets, BlockIndex, Word)
	end

	for Index = 16 * 4, 63 * 4, 4 do
		local Sub15 = buffer.readu32(Offsets, Index - (15 * 4))
		local Sub2 = buffer.readu32(Offsets, Index - (2 * 4))

		local Sub16 = buffer.readu32(Offsets, Index - (16 * 4))
		local Sub7 = buffer.readu32(Offsets, Index - (7 * 4))

		local S0 = bit32.bxor(bit32.rrotate(Sub15, 7), bit32.rrotate(Sub15, 18), bit32.rshift(Sub15, 3))
		local S1 = bit32.bxor(bit32.rrotate(Sub2, 17), bit32.rrotate(Sub2, 19), bit32.rshift(Sub2, 10))

		buffer.writeu32(Offsets, Index, (Sub16 + S0 + Sub7 + S1))
	end

	local OldA, OldB, OldC, OldD, OldE, OldF, OldG, OldH = A, B, C, D, E, F, G, H

	for BufferIndex = 0, 63 * 4, 4 do
		local S1 = bit32.bxor(bit32.rrotate(E, 6), bit32.rrotate(E, 11), bit32.rrotate(E, 25))
		local Ch = bit32.bxor(bit32.band(E, F), bit32.band(bit32.bnot(E), G))
		local Temp1 = H + S1 + Ch + buffer.readu32(CONSTANTS, BufferIndex) + buffer.readu32(Offsets, BufferIndex)
		local S0 = bit32.bxor(bit32.rrotate(A, 2), bit32.rrotate(A, 13), bit32.rrotate(A, 22))
		local Maj = bit32.bxor(bit32.band(A, B), bit32.band(A, C), bit32.band(B, C))
		local Temp2 = S0 + Maj

		H = G
		G = F
		F = E
		E = D + Temp1
		D = C
		C = B
		B = A
		A = Temp1 + Temp2
	end

	return (A + OldA) % MODULO, (B + OldB) % MODULO, (C + OldC) % MODULO, (D + OldD) % MODULO, (E + OldE) % MODULO, (F + OldF) % MODULO, (G + OldG) % MODULO, (H + OldH) % MODULO
end

local HashValues = buffer.create(32)
local FormatString = string.rep("%08x", 8)
local function SHA256(Message: buffer | string, Salt: (buffer | string)?): string
	Message = type(Message) == "string" and buffer.fromstring(Message) or Message
	Salt = type(Salt) == "string" and buffer.fromstring(Salt) or Salt

	if Salt and buffer.len(Salt) > 0 then
		local MessageWithSalt = buffer.create(buffer.len(Message) + buffer.len(Salt))

		buffer.copy(MessageWithSalt, 0, Message)
		buffer.copy(MessageWithSalt, buffer.len(Message), Salt)

		Message = MessageWithSalt
	end

	local A, B, C, D = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
	local E, F, G, H = 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

	local ProcessedMessage, Length = PreProcess(Message)
	for Index = 0, Length - 1, 64 do
		A, B, C, D, E, F, G, H = DigestBlock(ProcessedMessage, Index, A, B, C, D, E, F, G, H)
	end

	return string.format(FormatString, A, B, C, D, E, F, G, H)
end

return {
	SHA256 = SHA256
}
