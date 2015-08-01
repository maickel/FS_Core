local _, FS = ...
local Hud = FS:RegisterModule("Hud")
local Map

-- Math aliases
local sin, cos, atan2, abs = math.sin, math.cos, math.atan2, math.abs
local pi_2 = math.pi / 2

--------------------------------------------------------------------------------
-- HUD Frame

local hud
do
	hud = CreateFrame("Frame", "FSHud", UIParent)
	hud:Hide()
end

--------------------------------------------------------------------------------
-- Hud config

local hud_defaults = {
	profile = {
		enable = true,
		fps = 120,
		alpha = 1,
		scale = 10,
		offset_x = 0,
		offset_y = 0,
		smoothing = true,
		smoothing_click = true,
		fade = true
	}
}

local hud_config = {
	title = {
		type = "description",
		name = "|cff64b4ffHead-up display (HUD)",
		fontSize = "large",
		order = 0
	},
	desc = {
		type = "description",
		name = "Visual radar-like display over the whole screen used to show various boss abilities area of effect.\n",
		fontSize = "medium",
		order = 1
	},
	enable = {
		type = "toggle",
		name = "Enable",
		width = "full",
		get = function()
			return Hud.settings.enable
		end,
		set = function(_, value)
			Hud.settings.enable = value
			if value then
				Hud:Enable()
				if Hud.num_objs > 0 then
					Hud:Show()
				end
			else
				Hud:Disable()
			end
		end,
		order = 5
	},
	spacing_9 = {
		type = "description",
		name = "\n",
		order = 9
	},
	offset_x = {
		type = "range",
		name = "Offset X",
		min = -10000, max = 10000,
		softMin = -960, softMax = 960,
		bigStep = 1,
		get = function()
			return Hud.settings.offset_x
		end,
		set = function(_, value)
			Hud.settings.offset_x = value
			hud:SetPoint("CENTER", UIParent, "CENTER", value, Hud.settings.offset_y)
		end,
		order = 20
	},
	offset_y = {
		type = "range",
		name = "Offset Y",
		min = -10000, max = 10000,
		softMin = -540, softMax = 540,
		bigStep = 1,
		get = function()
			return Hud.settings.offset_y
		end,
		set = function(_, value)
			Hud.settings.offset_y = value
			hud:SetPoint("CENTER", UIParent, "CENTER", Hud.settings.offset_x, value)
		end,
		order = 21
	},
	fps = {
		type = "range",
		name = "Refresh rate",
		desc = "Number of refresh per seconds. Reducing this value can greatly reduce CPU usage. It will never be faster than your in-game FPS.",
		min = 10,
		max = 120,
		bigStep = 5,
		get = function()
			return Hud.settings.fps
		end,
		set = function(_, value)
			Hud.settings.fps = value
		end,
		order = 30
	},
	scale = {
		type = "range",
		name = "Scale",
		desc = "Number of pixels corresponding to 1 yard. You should keep the default 10 px/yd in most cases.",
		min = 2,
		max = 50,
		bigStep = 1,
		get = function()
			return Hud.settings.scale
		end,
		set = function(_, value)
			Hud.settings.scale = value
			Hud:SetZoom(value)
		end,
		order = 35
	},
	spacing_59 = {
		type = "description",
		name = "\n\n",
		order = 59
	},
	smooth = {
		type = "toggle",
		name = "Enable rotation smoothing",
		desc = "Enable smooth rotation when your character abruptly changes orientation",
		get = function()
			return Hud.settings.smoothing
		end,
		set = function(_, value)
			Hud.settings.smoothing = value
		end,
		order = 60
	},
	smooth_click = {
		type = "toggle",
		name = "Smooth right-click rotation",
		desc = "Smooth rotation even when done manually by right-clicking on the game world",
		get = function()
			return Hud.settings.smoothing_click
		end,
		set = function(_, value)
			Hud.settings.smoothing_click = value
		end,
		disabled = function()
			return not Hud.settings.smoothing
		end,
		order = 61
	},
	fade = {
		type = "toggle",
		name = "Enable fade-in-out animations",
		desc = "Enable animations on objects creation and removal",
		get = function()
			return Hud.settings.fade
		end,
		set = function(_, value)
			Hud.settings.fade = value
		end,
		order = 62
	},
	spacing_89 = {
		type = "description",
		name = "\n",
		order = 89
	},
	test = {
		type = "execute",
		name = "Test",
		func = function()
			local x, y = UnitPosition("player")
			
			local s1 = Hud:CreateStaticPoint(x+15, y+15):SetColor(0.8, 0, 0.8, 1)
			local s2 = Hud:CreateStaticPoint(x+30, y):SetColor(0, 0.8, 0.8, 1)
			local s3 = Hud:CreateShadowPoint("player"):SetColor(0.8, 0.8, 0, 1)

			local a1 = Hud:DrawArea(s1, 15)
			local a2 = Hud:DrawTarget(s2, 10):Fade(false)
			local a3 = Hud:DrawTimer(s3, 15, 10):SetColor(0.8, 0.8, 0, 0.5)
			local a4 = Hud:DrawRadius(s3, 25)
			
			function a2:OnUpdate()
				self:SetColor(abs(sin(GetTime())), abs(sin(GetTime() / 2)), abs(sin(GetTime() / 3)), 0.8)
			end
			
			function a3:OnDone()
				a3:Remove()
				a4:Remove()
			end
			
			Hud:DrawLine("player", s1, 128)
			Hud:DrawLine("player", s2)
			Hud:DrawLine(s1, s2, 256)

			function a1:OnUpdate()
			   self.radius = 25 + math.sin(GetTime() * 5)
			end
		end,
		order = 100,
	},
	clear = {
		type = "execute",
		name = "Clear",
		func = function()
			Hud:Clear()
		end,
		order = 101,
	},
}

--------------------------------------------------------------------------------
-- Module initialization

function Hud:OnInitialize()
	Map = FS:GetModule("Map")
	
	-- Create config database
	self.db = FS.db:RegisterNamespace("HUD", hud_defaults)
	self.settings = self.db.profile
	
	-- Config enable state
	self:SetEnabledState(self.settings.enable)
	
	-- Set HUD global settings
	hud:SetAlpha(self.settings.alpha)
	self:SetZoom(self.settings.scale)
	
	-- Points
	self.points = {}
	
	-- Object currently drawn on the HUD
	self.objects = {}
	self.num_objs = 0
	
	-- Track right click on the game world and disable rotation smoothing
	self.right_click = false
	hooksecurefunc(_G, "TurnOrActionStart", function() self.right_click = true end)
	hooksecurefunc(_G, "TurnOrActionStop", function() self.right_click = false end)
	
	FS:GetModule("Config"):Register("Head-up display", hud_config)
end

function Hud:OnEnable()
	-- Refresh raid points if the group roster changes
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "RefreshRaidPoints")
	
	-- Clear the HUD on ENCOUNTER_END
	-- This prevents bogus modules or encounters to keep the HUD open
	self:RegisterEvent("ENCOUNTER_END", "Clear")
end

function Hud:OnDisable()
	-- Clear all active objects on disable
	self:Clear()
end

--------------------------------------------------------------------------------
-- Object frame pool

do
	local pool = {}
	
	local function normalize(frame, use_tex)
		frame:SetFrameStrata("BACKGROUND")
		frame:SetAlpha(1)
		frame:ClearAllPoints()
		
		frame.tex:SetAllPoints()
		frame.tex:SetDrawLayer("ARTWORK")
		frame.tex:SetBlendMode("BLEND")
		frame.tex:SetTexCoord(0, 1, 0, 1)
		
		if use_tex then
			frame.tex:Show()
		else
			frame.tex:Hide()
		end
		
		frame:Show()
		return frame
	end
	
	-- Recycle an old frame or allocate a new one
	function Hud:AllocObjFrame(use_tex)
		if #pool > 0 then
			return normalize(table.remove(pool), use_tex)
		else
			local frame = CreateFrame("Frame", nil, hud)
			frame.tex = frame:CreateTexture(nil, "ARTWORK")
			return normalize(frame, use_tex)
		end
	end
	
	-- Put the given frame back in the pool
	function Hud:ReleaseObjFrame(frame)
		frame:Hide()
		table.insert(pool, frame)
	end
end

--------------------------------------------------------------------------------
-- Points

do
	-- Construct a point
	function Hud:CreatePoint(name)
		-- Generate a random name if anonymous
		if not name then
			name = tostring(GetTime()) + tostring(math.random())
		end
		
		-- If the point is already defined, return the old one
		-- This behaviour is intended to be exceptional, a point should not
		-- be created multiple times under normal circumstances
		if self.points[name] then
			self:Printf("Detected name conflict on point creation ('%s')", name)
			return self.points[name]
		end
		
		local point = { __point = true }
		
		point.name = name
		self.points[name] = point
		
		point.frame = Hud:AllocObjFrame(true)
		point.tex = point.frame.tex
		
		point.frame:SetSize(16, 16)
		point.tex:SetTexture("Interface\\AddOns\\FS_Core\\media\\blip")
		point.tex:SetVertexColor(1, 1, 1, 0)
		point.tex:SetDrawLayer("OVERLAY")
		
		point.x = 0
		point.y = 0
		point.world_x = 0
		point.world_y = 0
		
		point.attached = {}
		point.num_attached = 0
		
		-- Define the corresponding unit for this point
		function point:SetUnit(unit)
			self.unit = unit
			self:RefreshUnit()
			return self
		end
		
		-- Change the point color
		function point:SetColor(r, g, b, a)
			self.tex:SetVertexColor(r, g, b, a or 1)
			return self
		end
		
		-- Define the always_visible flag
		-- An always_visible point is shown event if no show_all_points objects
		-- are currently present
		function point:AlwaysVisible(state)
			self.always_visible = state
			return self
		end
		
		-- Update the point position and properties
		function point:Update()
			-- Ensure unit still exists
			if self.unit and not UnitExists(self.unit) then
				self:Remove()
				return
			end
				
			-- Fetch point position
			local x, y = self:Position()
			if not x then return end
			
			-- Set world x and y coordinates
			self.world_x = x
			self.world_y = y
			
			-- Project point
			x, y = Hud:Project(x, y)
			
			-- Save screen coordinates
			self.x = x
			self.y = y
			
			-- Decide if the point is visible or not
			if self.num_attached > 0 -- If the point has an attached object
			or self.always_visible   -- If the point is always_visible
			or Hud.show_all_points   -- If at least one object requests all points to be visible
			or Hud.force then        -- If the HUD is in forced mode
				if self.hidden then
					-- Show the point if currently hidden
					self.hidden = false
					self.frame:Show()
				end
				-- Place the point
				self.frame:SetPoint("CENTER", hud, "CENTER", x, y)
			elseif not self.hidden then
				-- Hide the wrapper frame to keep point color intact
				self.hidden = true
				self.frame:Hide()
				return
			end
			
			-- Unit point specifics
			if self.unit then
				-- Hide the point if the unit is dead
				if UnitIsDeadOrGhost(self.unit) then
					if not self.unit_ghost then
						self.tex:SetVertexColor(1, 1, 1, 0)
						self.unit_ghost = true
					end
					return
				elseif self.unit_ghost then
					self.unit_ghost = false
					
					-- Reset the unit class, this will cause the color to be reset 
					self.unit_class = nil
				end
				
				-- Ensure the point color reflect the unit class
				local class = UnitClass(self.unit)
				if not self.unit_ghost and self.unit_class ~= class then
					self.tex:SetVertexColor(FS:GetClassColor(self.unit, true))
					self.unit_class = class
				end
			end
		end
		
		-- Ensure the unit association of this point is correct
		function point:RefreshUnit()
			if self.unit then
				-- Check that "raidX" is still the same player
				local guid = UnitGUID(self.unit)
				if guid ~= self.name then
					-- Attempt to find the new raid unit corresponding to the player
					for _, unit in FS:IterateGroup() do
						if UnitGUID(unit) == self.name then
							-- Update the unit id
							self.unit = unit
							return
						end
					end
					
					-- This player is no longer in the raid
					-- Remove the point
					self:Remove()
				end
			end
		end
		
		-- Attach an object to this point
		-- The object will be :Remove()'ed when this point is removed
		function point:AttachObject(obj)
			if not self.attached[obj] then
				self.attached[obj] = true
				point.num_attached = point.num_attached + 1
			end
		end
		
		-- Remove the point and any attached objects
		local removed = false
		function point:Remove()
			-- Impossible to remove player point
			if self.unit == "player" then return end
			
			-- Ensure the function is not called two times
			if removed then return end
			removed = true
			
			-- Release frame
			Hud:ReleaseObjFrame(self.frame)
			
			-- Point itself
			Hud.points[self.name] = nil
			
			-- Remove attached objects
			local do_ghost = false
			for obj in pairs(self.attached) do
				if obj.fade then do_ghost = true end
				obj:Remove()
			end
			
			if do_ghost then
				local ghost_start = GetTime()
				local ticker
				ticker = C_Timer.NewTicker(0.033, function()
					point.x, point.y = Hud:Project(point.world_x, point.world_y)
					if GetTime() - ghost_start > 0.5 then
						ticker:Cancel()
						ticker = nil
					end
				end)
			end
			
			-- Remove handler
			if self.OnRemove then
				self:OnRemove()
			end
		end
		
		-- Detach an object
		function point:DetachObject(obj)
			-- Do not remove object once the point deletion process has started
			if removed then return end
			if self.attached[obj] then
				self.attached[obj] = nil
				point.num_attached = point.num_attached - 1
			end
		end
		
		-- Unit distance to this point
		function point:UnitDistance(unit)
			local x, y = UnitPosition(unit)
			if not x then return end
			return Map:GetDistance(self.world_x, self.world_y, x, y)
		end
		
		-- Return the cached world position for this point
		function point:FastPosition()
			return self.world_x, self.world_y
		end
		
		return point
	end
	
	-- Create a static point
	function Hud:CreateStaticPoint(x, y, ...)
		local pt = self:CreatePoint(...)
		function pt:Position() return x, y end
		return pt
	end
	
	-- Create a shadow point
	function Hud:CreateShadowPoint(pt, ...)
		-- Shadow points are actually half object
		-- Since we usually attach them to unit point, refresh them now
		self:RefreshRaidPoints()
		
		-- Get the reference point
		local ref = self:GetPoint(pt)
		if not ref then
			self:Printf("Shadow point creation failed: unable to get the reference point ('%s')", pt)
			return
		end
		
		local shadow = self:CreatePoint(...)
		shadow.ref = ref
		
		-- Mirror reference point
		function shadow:Position()
			return ref:Position()
		end
		
		-- Consider the shadow point as an object attached to the reference point
		-- This will cause the shadow point to be removed if the reference point is removed
		ref:AttachObject(shadow)
		
		-- Detach the shadow point from the reference point on removal
		-- This prevent a memory leak by keeping the object alive
		function shadow:OnRemove()
			return ref:DetachObject(self)
		end
		
		return shadow
	end
	
	-- Iterates over all points
	function Hud:IteratePoints()
		return pairs(self.points)
	end
	
	-- Return a point
	function Hud:GetPoint(name)
		-- Y U NO HAZ NAME ?
		if not name then
			self:Print("Attempted to get a point with a nil name")
			return
		end
		
		-- We actually got a point, return it
		if name.__point then return name end
		
		-- Fetch by name
		local pt = self.points[name]
		
		if pt then
			return pt
		elseif UnitExists(name) then
			-- Requested a unit point, lookup by GUID
			return self:GetPoint(UnitGUID(name))
		elseif select(2, name:gsub("%-", "", 2)) == 1 then
			-- No point found, but the name has one "-" in it. This may be the case
			-- with cross-realm units. Try again without the server name.
			return self:GetPoint(name:match("^[^-]+"))
		end
		
		-- No point matches
		-- Returning nothing
	end
	
	-- Remove a point
	function Hud:RemovePoint(name)
		local pt = self:GetPoint(name)
		if pt then
			pt:Remove()
		end
	end
end

-- Automatically create points for raid units
do
	-- Create point for a specific unit
	local function create_raid_point(unit)
		if not Hud:GetPoint(unit) and not UnitIsUnit(unit, "player") then
			local unit_name = UnitName(unit)
			-- Ensure unit name is currently available
			if unit_name and unit_name ~= UNKNOWNOBJECT then
				local pt = Hud:CreatePoint(UnitGUID(unit), unit_name, unit)
				pt:SetUnit(unit)
				function pt:Position()
					return UnitPosition(self.unit)
				end
			end
		end
	end
	
	-- Refresh all raid members points
	local player_pt
	function Hud:RefreshRaidPoints()
		-- Create the player point if not already done
		if not player_pt and UnitName("player") ~= UNKNOWNOBJECT then
			player_pt = Hud:CreatePoint(UnitGUID("player"), "player", UnitName("player"))
			player_pt:SetUnit("player")
			function player_pt:Position()
				return UnitPosition("player")
			end
		
			-- The player point is always visible
			player_pt:AlwaysVisible(true)
			
			-- The player point should be drawn over everything else
			player_pt.frame:SetFrameStrata("HIGH")
		end
		
		-- Refresh units of all raid points
		for n, pt in self:IteratePoints() do
			pt:RefreshUnit()
		end
		
		-- Find unit currently available without associated raid points
		for _, unit in FS:IterateGroup() do
			local pt = self:GetPoint(UnitGUID(unit))
			if not pt or pt.unit ~= unit then
				-- We got a point, but that is a bad one
				if pt then pt:Remove() end
				create_raid_point(unit)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Visibility and updates

function Hud:Show(force)
	if self.visible or not self:IsEnabled() then return end
	
	self.visible = true
	self.force = force
	
	-- Refresh raid points just in case
	self:RefreshRaidPoints()
	
	-- Update show all points setting
	self:UpdateShowAllPoints()
	
	-- Reset the rotation smoothing feature
	self:ResetRotationSmoothing()
	
	-- Create the update ticker
	-- TODO: use 0.035 for low CPU mode, but using the game framerate feel much better
	self.ticker = C_Timer.NewTicker(1 / self.settings.fps, function() self:OnUpdate() end)
	
	-- Delay the first update a bit to prevent side effects on Show() call
	C_Timer.After(0, function() self:OnUpdate() end)
	
	-- Display the master frame
	hud:SetSize(UIParent:GetSize())
	hud:SetPoint("CENTER", UIParent, "CENTER", self.settings.offset_x, self.settings.offset_y)
	hud:Show()
end

function Hud:Hide()
	if not self.visible then return end
	
	-- This the master frame
	self.visible = false
	hud:Hide()
	
	-- Stop the update ticker
	self.ticker:Cancel()
	
	-- Clear all points on hide
	self:Clear()
end

do
	-- Variables used for point projection
	-- Player position
	local px = 0
	local py = 0
	
	-- Sine and cosine of player facing angle
	local a, last_a = 0, 0
	local sin_a = 0
	local cos_a = 0
	
	-- Zoom factor
	local zoom = 10
	
	-- Set the zoom factor, 1yd is equal to this value in pixels
	function Hud:SetZoom(z)
		zoom = z
	end
	
	-- Get the HUD zoom factor
	function Hud:GetZoom()
		return zoom
	end
	
	-- Reset the last rotation angle to prevent rotation smoothing on show
	function Hud:ResetRotationSmoothing()
		last_a = GetPlayerFacing() + pi_2
	end
	
	-- Project a world point on the screen
	function Hud:Project(x, y)
		-- Delta relative to player position
		local dx = px - x
		local dy = py - y
		
		-- Rotate according to player facing direction
		local rx = dx * cos_a + dy * sin_a
		local ry = -dx * sin_a+ dy * cos_a
		
		-- Multiply by zoom factor
		return rx * zoom, ry * zoom
	end
	
	-- Safety helper to update points and objects
	local function obj_update(obj)
		-- Use pcall to prevent an external error to freeze the HUD
		if not pcall(obj.Update, obj) then
			-- If more than 5 failures are caused by this object, remove it
			obj._err_count = (obj._err_count or 0) + 1
			if obj._err_count > 5 then
				obj:Remove()
			end
		end
	end

	-- Update the HUD
	function Hud:OnUpdate()
		-- Nothing to draw, auto-hide
		if not self.force and self.num_objs == 0 then
			self:Hide()
			return
		end
		
		-- Fetch player position and facing for projection
		px, py = UnitPosition("player")
		a = GetPlayerFacing() + pi_2
		
		local ea
		if self.settings.smoothing and (not self.right_click or self.settings.smoothing_click) then
			local da = atan2(sin(a - last_a), cos(a - last_a))
			ea = (abs(da) < 0.1) and a or (last_a + (da / 3))
		else
			ea = a
		end
		
		last_a = ea
		cos_a = cos(ea)
		sin_a = sin(ea)
		
		-- Update all points
		for name, obj in self:IteratePoints() do
			obj_update(obj)
		end
		
		-- Update all objects
		for obj in Hud:IterateObjects() do
			obj_update(obj)
		end
	end
end

--------------------------------------------------------------------------------
-- Objects interface

local HudObject = {}

-- Helper function to get a point and register the object with it
function HudObject:UsePoint(name)
	local pt = Hud:GetPoint(name)
	if not pt then
		Hud:Printf("Failed to find a point required by a new object ('%s')", name or "nil")
		return
	end
	table.insert(self.attached, pt)
	pt:AttachObject(self)
	return pt
end

-- Set the obejct color
function HudObject:SetColor(...)
	self.tex:SetVertexColor(...)
	return self
end

-- Get the object color
function HudObject:GetColor()
	return self.tex:GetVertexColor()
end

-- Set the show_all_points flag of this object
-- If at least one such object is currently defined, all unit points will
-- be shown even if no objects are attached to them
function HudObject:ShowAllPoints(state)
	if state == nil then
		return self.show_all_points
	end
	
	self.show_all_points = state
	Hud:UpdateShowAllPoints()
	return self
end

-- Set fade flag
-- If this flag is set, the object will be animated with a fade-in-out
function HudObject:Fade(state)
	if state == nil then
		return self.fade
	end
	
	-- Prevent setting the fade flags if globally disabled
	if not Hud.settings.fade then return self end
	
	self.fade = state
	return self
end

-- Set a key for this object
function HudObject:Register(key, replace)
	if not key then return end
	
	-- If replace, remove objects with the same key
	if replace then
		Hud:RemoveObject(key)
	end
	
	-- Define the key for this object
	Hud.objects[self] = key
	
	return self
end

-- Remove the object by calling Hud:RemoveObject
function HudObject:Remove()
	-- Object itself given
	if not Hud.objects[self] or self._destroyed then return end
	self._destroyed = true
	
	-- Detach this object from every points it was attached to
	for i, pt in ipairs(self.attached) do
		pt:DetachObject(self)
	end
	
	local function do_remove()
		Hud.objects[self] = nil
		Hud.num_objs = Hud.num_objs - 1
		
		-- Release the wrapper frame of this object
		Hud:ReleaseObjFrame(self.frame)
	end
	
	-- Call the remove handler if defined
	if self.OnRemove then self:OnRemove() end
	
	-- Fade out animation
	if self.fade then
		if self.fade_in then
			self.fade_in:Cancel()
		end
		
		local start = GetTime()
		local ticker
		ticker = C_Timer.NewTicker(0.01, function()
			local pct = (GetTime() - start) / 0.20
			if pct > 1 then
				self.frame:SetAlpha(0)
				ticker:Cancel()
				ticker = nil
				do_remove()
			else
				self.frame:SetAlpha(1 - pct)
			end
		end)
	else
		do_remove()
	end
	
	-- Check if we still need to show all points
	if self.show_all_points then
		Hud:UpdateShowAllPoints()
	end
end

-- Factory function
function Hud:CreateObject(proto, use_tex)
	-- Object usually require raid points to be available
	self:RefreshRaidPoints()
	
	local obj = setmetatable(proto or {}, { __index = HudObject })
	obj.__object = true
	
	self.objects[obj] = true
	self.num_objs = self.num_objs + 1
	
	obj.frame = self:AllocObjFrame(use_tex)
	obj.tex = obj.frame.tex
	obj.attached = {}
	obj.fade = Hud.settings.fade
	
	-- Fade in if not disabled
	C_Timer.After(0, function()
		if obj.fade then
			local created = GetTime()
			obj.frame:SetAlpha(0)
			obj.fade_in = C_Timer.NewTicker(0.01, function()
				local pct = (GetTime() - created) / 0.20
				if pct > 1 then
					obj.frame:SetAlpha(1)
					obj.fade_in:Cancel()
					obj.fade_in = nil
				else
					obj.frame:SetAlpha(pct)
				end
			end)
		end
	end)
	
	-- Show() may cause some weird side effects, call it on tick later
	C_Timer.After(0, function() Hud:Show() end)
	
	return obj
end

--------------------------------------------------------------------------------
-- Scene management

-- Remove an object from the scene
function Hud:RemoveObject(key)
	if key.__object then
		key:Remove()
		return
	else
		for o, k in self:IterateObjects() do
			if k == key then
				o:Remove()
			end
		end
	end
end
	
-- Iterates over all objects
function Hud:IterateObjects()
	return pairs(self.objects)
end

-- Check if at least one show_all_points object is present in the scene
function Hud:UpdateShowAllPoints()
	for obj in Hud:IterateObjects() do
		if obj.show_all_points then
			self.show_all_points = true
			return
		end
	end
	self.show_all_points = false
end

-- Clear the whole scene
function Hud:Clear()
	-- Remove all points unrelated to raid units
	-- This prevent bogus modules to keep invisible points on the scene forever
	for name, point in self:IteratePoints() do
		if not point.unit then
			point:Remove()
		end
	end
	
	-- Remove all objects
	for obj in self:IterateObjects() do
		obj:Remove()
	end
end

--------------------------------------------------------------------------------
-- API

-- Line
function Hud:DrawLine(from, to, width)
	local line = self:CreateObject({ width = width or 64 }, true)
	
	from = line:UsePoint(from)
	to = line:UsePoint(to)
	if not from or not to then return end
	
	line.tex:SetTexture("Interface\\AddOns\\FS_Core\\media\\line")
	line.tex:SetVertexColor(0.5, 0.5, 0.5, 1)
	line.tex:SetBlendMode("ADD")
	
	function line:Update()
		local sx, sy = from.x, from.y
		local ex, ey = to.x, to.y
		
		-- Determine dimensions and center point of line
		local dx, dy = ex - sx, ey - sy
		local cx, cy = (sx + ex) / 2, (sy + ey) / 2
		local w = self.width
		
		-- Normalize direction if necessary
		if dx < 0 then
			dx, dy = -dx, -dy;
		end
		
		-- Calculate actual length of line
		local l = (dx * dx + dy * dy) ^ 0.5
		
		-- Quick escape if it's zero length
		if l == 0 then
			self.frame:ClearAllPoints()
			self.frame:SetPoint("BOTTOMLEFT", hud, "CENTER", cx, cy)
			self.frame:SetPoint("TOPRIGHT",   hud, "CENTER", cx, cy)
			self.tex:SetTexCoord(0,0,0,0,0,0,0,0)
			return
		end
		
		-- Sin and Cosine of rotation, and combination (for later)
		local s, c = -dy / l, dx / l
		local sc = s * c
		
		-- Calculate bounding box size and texture coordinates
		local Bwid, Bhgt, BLx, BLy, TLx, TLy, TRx, TRy, BRx, BRy
		if dy >= 0 then
			Bwid = ((l * c) - (w * s)) / 2
			Bhgt = ((w * c) - (l * s)) / 2
			BLx, BLy, BRy = (w / l) * sc, s * s, (l / w) * sc
			BRx, TLx, TLy, TRx = 1 - BLy, BLy, 1 - BRy, 1 - BLx
			TRy = BRx;
		else
			Bwid = ((l * c) + (w * s)) / 2
			Bhgt = ((w * c) + (l * s)) / 2
			BLx, BLy, BRx = s * s, -(l / w) * sc, 1 + (w / l) * sc
			BRy, TLx, TLy, TRy = BLx, 1 - BRx, 1 - BLx, 1 - BLy
			TRx = TLy
		end
		
		self.frame:SetPoint("BOTTOMLEFT", hud, "CENTER", cx - Bwid, cy - Bhgt)
		self.frame:SetPoint("TOPRIGHT",   hud, "CENTER", cx + Bwid, cy + Bhgt)
		self.tex:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)
	end
	
	return line
end

-- Circle
function Hud:DrawCircle(center, radius, tex)
	local circle = self:CreateObject({ radius = radius }, true)
	
	center = circle:UsePoint(center)
	if not center then return end
	
	circle.tex:SetTexture(tex or radius < 15 and "Interface\\AddOns\\FS_Core\\media\\radius_lg" or "Interface\\AddOns\\FS_Core\\media\\radius")
	circle.tex:SetBlendMode("ADD")
	circle.tex:SetVertexColor(0.8, 0.8, 0.8, 0.5)
	
	-- Check if a given unit is inside the circle
	function circle:UnitIsInside(unit)
		return not UnitIsDeadOrGhost(unit) and center:UnitDistance(unit) < self.radius
	end
	
	-- Get the list of units inside the circle
	function circle:UnitsInside(filter)
		local players = {}
		for _, unit in FS:IterateGroup() do
			if type(filter) ~= "function" or filter(unit) then
				if self:UnitIsInside(unit) then
					players[#players + 1] = unit
				end
			end
		end
		return players
	end
	
	function circle:Update()
		if self.OnUpdate then self:OnUpdate() end
		
		local size = self.radius * 2 * Hud:GetZoom()
		
		if self.Rotate then
			-- Rotation require a multiplier on size
			size = size * (2 ^ 0.5)
			self.tex:SetRotation(self:Rotate())
		end
		
		self.frame:SetSize(size, size)
		self.frame:SetPoint("CENTER", hud, "CENTER", center.x, center.y)
	end
	
	return circle
end

-- DrawRadius is actually a better name for DrawCircle
Hud.DrawRadius = Hud.DrawCircle

-- Area of Effect
function Hud:DrawArea(center, radius)
	return self:DrawCircle(center, radius, "Interface\\AddOns\\FS_Core\\media\\radar_circle")
end

-- Target reticle
function Hud:DrawTarget(center, radius)
	local target = self:DrawCircle(center, radius, "Interface\\AddOns\\FS_Core\\media\\alert_circle")
	if not target then return end
	
	function target:Rotate()
		return GetTime()
	end
	
	return target
end

-- Timer
function Hud:DrawTimer(center, radius, duration)
	local timer = self:DrawCircle(center, radius, "Interface\\AddOns\\FS_Core\\media\\timer")
	if not timer then return end
	
	-- Timer informations
	local start = GetTime()
	timer.pct = 0
	
	local done = false
	
	-- Hook the Update() function directly to let the OnUpdate() hook available for user code
	local circle_update = timer.Update
	function timer:Update()
		local dt = GetTime() - start
		if dt < duration then
			self.pct = dt / duration
		else
			self.pct = 1
		end
		
		if self.pct == 1 and not done then
			done = true
			if self.OnDone then
				self:OnDone()
			end
		end
		
		circle_update(timer)
	end
	
	function timer:Rotate()
		return math.pi * 2 * self.pct
	end
	
	return timer
end
