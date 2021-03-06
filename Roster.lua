local _, FS = ...
local Roster = FS:RegisterModule("Roster", "AceTimer-3.0")
local LGIST = LibStub:GetLibrary("LibGroupInSpecT-1.1")

-------------------------------------------------------------------------------
-- Roster config
--------------------------------------------------------------------------------

local roster_config = {
	title = {
		type = "description",
		name = "|cff64b4ffRoster tracker",
		fontSize = "large",
		order = 0
	},
	desc = {
		type = "description",
		name = "Tracks spec and talents from allied units.\n",
		fontSize = "medium",
		order = 1
	},
	ref = {
		type = "header",
		name = "Module reference",
		order = 1000
	},
	docs = FS.Config:MakeDoc("Public API", 2000, {
		{":Iterate ( sorted , limit ) -> [ unit ]", "Returns an iterator over the group members.\nIf sorted is given and you are in a raid group, units are sorted by role."},
		{":GetUnit ( guid ) -> unit", "Returns the unitid for a given GUID, if known."},
		{":GetInfo ( guid ) -> InfoTable", "Returns talents and glyphs information for a player. See LibGroupInSpec_T for more information."}
	}, "FS.Roster"),
	events = FS.Config:MakeDoc("Emitted events", 3000, {
		{"_JOINED ( guid , unit )", "Emitted when a new unit has joined the group."},
		{"_UPDATE ( guid , info , info )", "Emitted when talents info are updated for a unit."},
		{"_LEFT ( guid )", "Emitted when a unit has left the group."},
	}, "FS_ROSTER")
}

--------------------------------------------------------------------------------

function Roster:OnInitialize()
	FS.Config:Register("Roster tracker", roster_config)
	self.group = {}
	LGIST.RegisterCallback(self, "GroupInSpecT_Update", "RosterUpdate")
	LGIST.RegisterCallback(self, "GroupInSpecT_Remove", "RosterRemove")
end

function Roster:OnEnable()
end

function Roster:OnDisable()
end

--------------------------------------------------------------------------------

do
	local role_order = {
		["tank"] = 1,
		["TANK"] = 1,
		["melee"] = 2,
		["DAMAGER"] = 3,
		["ranged"] = 4,
		["HEALER"] = 5,
		["healer"] = 5,
		["NONE"] = 6
	}

	local function solo_iterator()
		local done = false
		return function()
			if not done then
				done = true
				return "player", 1
			end
		end
	end

	local function party_iterator()
		local i = -1
		return function()
			i = i + 1
			if i < GetNumGroupMembers() then
				return i == 0 and "player" or ("party" .. i), i + 1
			end
		end
	end

	local function raid_iterator(limit, sorted)
		local order

		if type(limit) ~= "number" then
			limit = 40
		end

		if sorted then
			order = {}
			local roles = {}
			local indices = {}

			for unit, idx in Roster:Iterate(limit) do
				table.insert(order, unit)
				local info = Roster:GetInfo(UnitGUID(unit))
				roles[unit] = info and (info.spec_role_detailed or info.spec_role) or UnitGroupRolesAssigned(unit)
				indices[unit] = idx
			end

			table.sort(order, function(a, b)
				if roles[a] ~= roles[b] then
					return role_order[roles[a]] < role_order[roles[b]]
				else
					return indices[a] < indices[b]
				end
			end)
		end

		local i = 0
		return function()
			i = i + 1
			local unit

			if i > limit or i > GetNumGroupMembers() then
				return
			elseif order then
				unit = order[i]
			else
				unit = "raid" .. i
			end

			if UnitIsUnit("player", unit) then
				return "player", i
			else
				return unit, i
			end
		end
	end

	function Roster:Iterate(limit, sorted)
		if not IsInGroup() then
			return solo_iterator()
		elseif not IsInRaid() then
			return party_iterator()
		else
			return raid_iterator(limit, sorted)
		end
	end
end

--------------------------------------------------------------------------------

function Roster:GetUnit(guid)
	return LGIST:GuidToUnit(guid)
end

function Roster:GetInfo(guid)
	return LGIST:GetCachedInfo(guid)
end

--------------------------------------------------------------------------------

function Roster:RosterUpdate(_, guid, unit, info)
	if not self.group[guid] then
		self:SendMessage("FS_ROSTER_JOINED", guid, unit)
		self.group[guid] = true
	end
	self:SendMessage("FS_ROSTER_UPDATE", guid, unit, info)
end

function Roster:RosterRemove(_, guid)
	self.group[guid] = nil
	self:SendMessage("FS_ROSTER_LEFT", guid)
end
