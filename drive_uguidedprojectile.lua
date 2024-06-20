
AddCSLuaFile()

--
--
-- You use this to drive ut99_fighterjet sent properly. 
--
--

DEFINE_BASECLASS( "drive_base" )


drive.Register( "drive_uguidedprojectile",
{
	--
	-- Called on creation
	--
	Init = function( self ) -- controlled by ufighter weapon 

		

	end,

	--
	-- Calculates the view when driving the entity
	--
	CalcView = function( self, view ) -- controlled by ufighter weapon 

		

	end,

	SetupControls = function( self, cmd ) 
	
	-- print(cmd:KeyDown(IN_USE)) 
	-- if (cmd:KeyDown(IN_ATTACK)) then self.Player:GetActiveWeapon():PrimaryAttack() end 
	-- if (cmd:KeyDown(IN_ATTACK2)) then self.Player:GetActiveWeapon():SecondaryAttack() end 
	-- if cmd:KeyDown(IN_USE) then print("key down") self.Entity:Use() end
	-- none of them worked in my test 

	end,
	--
	-- Called before each move. You should use your entity and cmd to
	-- fill mv with information you need for your move.
	--
	StartMove = function( self, mv, cmd ) 
		-- if !self.Entity.GetFlightVelocity then return end 
		-- if isfunction(self.Entity.SetPredictable) then self.Entity:SetPredictable(true) end 
		-- attack controls 
		if ( mv:KeyPressed( IN_ATTACK ) ) then self.Player:GetActiveWeapon():PrimaryAttack() end	
		if ( mv:KeyPressed( IN_ATTACK2 ) ) then self.Player:GetActiveWeapon():SecondaryAttack() end	
		
		local projSpeed = self.Entity.flVelocity or 550 
		local turnStrength = self.Entity.flTurnStrength or 1500 
		local rollMagnitude = self.Entity.flRollMagnitude or 10 
		self.Speed = projSpeed 
		mv:SetMaxSpeed(projSpeed) 

		local deltaTime = FrameTime() 
		local currentVelocity = self.Entity:GetVelocity() 
		local guideRotation = mv:GetAngles() 
		local oldGuiderRotation = self.Entity:GetNWAngle("u_oldeyeangles",guideRotation) 
		-- local yawDifference = math.AngleDifference(guideRotation.y,self.Entity:GetAngles().y) 
		-- print("z angle:",self.Entity:GetAngles().z,"aim angle diff:",math.AngleDifference(guideRotation.y,oldGuiderRotation.y)) 
		-- print("pdiff of ent z angles and 0",math.AngleDifference(self.Entity:GetAngles().z,0), "yawDifference:",yawDifference) 
		-- local test1 = math.AngleDifference(self.Entity:GetAngles().z,0) 
		-- if (yawDifference > 10 and test1 > 10) or (yawDifference < -10 and test1 < -10) then 
			-- guideRotation.y = oldGuiderRotation.y 
		-- end 
		
		local deltaCorrection = false 
		if deltaCorrection then 
			local deltaYaw = (guideRotation.yaw % 360) - (oldGuiderRotation.yaw % 360)
			local deltaPitch = (guideRotation.pitch % 360) - (oldGuiderRotation.pitch % 360)

			if deltaPitch < -180 then
				deltaPitch = deltaPitch + 360
			elseif deltaPitch > 180 then
				deltaPitch = deltaPitch - 360
			end

			if deltaYaw < -180 then
				deltaYaw = deltaYaw + 360
			elseif deltaYaw > 180 then
				deltaYaw = deltaYaw - 360
			end

			local yawDiff = (self.Entity:GetAngles().yaw % 360) - (guideRotation.yaw % 360) - deltaYaw
		
			if deltaYaw < 0 then
				if ((yawDiff > 0 and yawDiff < 90) or yawDiff < -270) then
					guideRotation.yaw = guideRotation.yaw + deltaYaw
				end
			elseif (yawDiff < 0 and yawDiff > -90) or yawDiff > 270 then
				guideRotation.yaw = guideRotation.yaw + deltaYaw
			end

			guideRotation.pitch = guideRotation.pitch + deltaPitch
		end 
	
		self.Entity:SetNWAngle("u_oldeyeangles", guideRotation) 
	

		local oldRoll = self.Entity:GetAngles().roll
		local oldVelocity = currentVelocity
		local newVelocity = currentVelocity + guideRotation:Forward() * turnStrength * deltaTime
		newVelocity:Normalize()
		newVelocity = newVelocity * (projSpeed) 
		self.Velocity = newVelocity 
		-- mv:SetVelocity(newVelocity) 
		local newAngles = newVelocity:Angle()

		-- Roll warhead based on acceleration
		local xAxis, yAxis, zAxis = newAngles:Forward(), newAngles:Right(), newAngles:Up()
		local rollMag = rollMagnitude * yAxis:Dot(newVelocity - oldVelocity) / deltaTime

		if rollMag > 0 then 
			newAngles.roll = math.min(12000 / 65536 * 360, rollMag / 65536 * 360) 
		else 
			newAngles.roll = math.max(53535 / 65536 * 360, (65536 + rollMag) / 65536 * 360) 
		end 

		-- Smoothly change rotation
		if newAngles.roll > 180 then 
			if oldRoll < 180 then 
				oldRoll = oldRoll + 360 
			end 
		elseif oldRoll > 180 then 
			oldRoll = oldRoll - 360 
		end 

		local smoothRoll = math.min(1.0, 5.0 * deltaTime) 
		newAngles.roll = newAngles.roll * smoothRoll + oldRoll * (1 - smoothRoll) 
		-- if !oldanglesset then self.Entity:SetNWAngle("u_oldeyeangles",mv:GetOldAngles()) end 
		
		self.Angles = newAngles 
		-- mv:SetAngles(newAngles) 
		-- self.Entity:SetNWAngle("u_oldangles",newAngles) 
		-- mv:SetOldAngles(newAngles) 
		
		
	end,

	--
	-- Runs the actual move. On the client when there's
	-- prediction errors this can be run multiple times.
	-- You should try to only change mv.
	--
	Move = function( self, mv ) 
		
		
		PrintTable(self) 
		mv:SetAngles(self.Angles) 
		mv:SetVelocity(self.Velocity) 
		self.Entity:SetLocalVelocity( mv:GetVelocity() ) 
		self.Entity:SetAngles(mv:GetAngles()) 

	end,

	--
	-- The move is finished. Use mv to set the new positions
	-- on your entities/players.
	--
	FinishMove = function( self, mv ) 

		--
		-- Update our entity!
		--
		
		-- self.Entity:SetNetworkOrigin( mv:GetOrigin() ) 
		-- self.Player:SetNetworkOrigin(mv:GetOrigin()) 
		-- self.Entity:SetLocalVelocity( mv:GetVelocity() ) 
		-- self.Entity:SetAngles(mv:GetAngles()) 
		-- self.Entity:SetLocalAngularVelocity( mv:GetAngles() ) 
		
		-- print("finished move")

	end

}, "drive_base" )
