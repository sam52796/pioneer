-- Copyright © 2008-2026 Pioneer Developers. See AUTHORS.txt for details
-- Licensed under the terms of the GPL v3. See licenses/GPL-3.txt

local Engine = require 'Engine'
local Lang = require 'Lang'

local MissionLang = {}
MissionLang.__index = MissionLang

--- Resolve a token from the module resource, then module-common.
function MissionLang:get(token)
	local msg = self.module:get(token)
	if msg then return msg end

	return self.common:get(token)
end

--- Collect sorted numeric indices for PREFIX_n keys in module and common.
--- Only keys matching ^PREFIX_(%d+)$ are included (not PREFIX_FLUFFY_1, etc.).
function MissionLang:numberedIndices(prefix)
	local pattern = "^" .. prefix:gsub("(%W)", "%%%1") .. "_(%d+)$"
	local seen = {}
	local sorted = {}

	local function collect(resource)
		for key in pairs(resource) do
			if type(key) == "string" then
				local n = key:match(pattern)
				if n then
					n = tonumber(n)
					if not seen[n] then
						seen[n] = true
						sorted[#sorted + 1] = n
					end
				end
			end
		end
	end

	collect(self.module)
	collect(self.common)
	table.sort(sorted)
	return sorted
end

--- Number of PREFIX_n tokens (sparse indices from module and common).
function MissionLang:countNumbered(prefix)
	local count = 0
	for _, n in ipairs(self:numberedIndices(prefix)) do
		if self:get(prefix .. "_" .. n) then
			count = count + 1
		end
	end
	return count
end

--- Pick a random message from all PREFIX_n tokens (sparse indices).
function MissionLang:pickNumbered(prefix)
	local available = {}
	for _, n in ipairs(self:numberedIndices(prefix)) do
		local msg = self:get(prefix .. "_" .. n)
		if msg then
			available[#available + 1] = msg
		end
	end
	if #available == 0 then return nil end
	return available[Engine.rand:Integer(1, #available)]
end

--- Pick a random message from an explicit list of token names.
function MissionLang:pickFromKeys(keys)
	local available = {}
	for _, key in ipairs(keys) do
		local msg = self:get(key)
		if msg then available[#available + 1] = msg end
	end
	if #available == 0 then return nil end
	return available[Engine.rand:Integer(1, #available)]
end

---@param moduleResourceName string
function MissionLang.New(moduleResourceName)
	local self = setmetatable({}, MissionLang)
	self.module = Lang.GetResource(moduleResourceName)
	self.common = Lang.GetResource("module-common")
	return self
end

return MissionLang
