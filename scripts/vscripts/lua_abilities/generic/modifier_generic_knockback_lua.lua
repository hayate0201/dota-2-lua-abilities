modifier_generic_knockback_lua = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_generic_knockback_lua:IsHidden()
	return true
end

function modifier_generic_knockback_lua:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_generic_knockback_lua:OnCreated( kv )
	if IsServer() then
		-- creation data (default)
			-- kv.distance (0)
			-- kv.height (-1)
			-- kv.duration (0)
			-- kv.damage (nil)
			-- kv.direction_x, kv.direction_y, kv.direction_z (xy:-forward vector, z:0)
			-- kv.IsStun (false)
			-- kv.IsFlail (true)
			-- kv.IsPurgable() // later 
			-- kv.IsMultiple() // later

		-- references
		self.distance = kv.distance or 0
		self.height = kv.height or -1
		self.duration = kv.duration or 0
		self.damage = kv.damage or 0
		if kv.direction_x and kv.direction_y then
			self.direction = Vector(kv.direction_x,kv.direction_y,0):Normalized()
		else
			self.direction = -(self:GetParent():GetForwardVector())
		end
		self.stun = kv.IsStun or false
		self.flail = kv.IsFlail or true

		-- load data
		self.origin = self:GetParent():GetOrigin()
		self.hVelocity = self.distance/self.duration

		-- vertical motion model
		self.gravity = -self.height/(self.duration*self.duration*0.125)
		self.vVelocity = (-0.5)*self.gravity*self.duration

		-- check duration
		if self.duration == 0 then
			self:Destroy()
		end

		-- apply motion controllers
		if self:ApplyHorizontalMotionController() == false then 
			self:Destroy()
		end
		if self.height>=0 then
			if self:ApplyVerticalMotionController() == false then 
				self:Destroy()
			end
		end

		-- tell client of activity
		if self.flail then
			self:SetStackCount( 1 )
		elseif self.stun then
			self:SetStackCount( 2 )
		end
	else
		self.anim = self:GetStackCount()
		self:SetStackCount( 0 )
	end
end

function modifier_generic_knockback_lua:OnRefresh( kv )
	if not IsServer() then return end
end

function modifier_generic_knockback_lua:OnDestroy( kv )
	if not IsServer() then return end
	self:GetParent():InterruptMotionControllers( true )
end

--------------------------------------------------------------------------------
-- Motion effects
function modifier_generic_knockback_lua:UpdateHorizontalMotion( me, dt )
	local parent = self:GetParent()
	
	-- set position
	local target = self.direction*self.distance*(dt/self.duration)

	-- change position
	parent:SetOrigin( parent:GetOrigin() + target )
end

function modifier_generic_knockback_lua:OnHorizontalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end

function modifier_generic_knockback_lua:UpdateVerticalMotion( me, dt )
	-- set time
	local time = dt/self.duration

	-- set relative position
	local target = self.hVelocity*time
	self.hVelocity = self.hVelocity - (self.gravity*time)

	-- change height
	parent:SetOrigin( parent:GetOrigin() + Vector( 0, 0, target ) )
end

function modifier_generic_knockback_lua:OnVerticalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_generic_knockback_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}

	return funcs
end

function modifier_generic_knockback_lua:GetOverrideAnimation( params )
	if self.anim==1 then
		return ACT_DOTA_FLAIL
	elseif self.anim==2 then
		return ACT_DOTA_STUNNED
	end
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_generic_knockback_lua:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = self.stun,
	}

	return state
end