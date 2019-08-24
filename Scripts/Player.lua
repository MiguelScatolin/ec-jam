Player = {}
Player.__index = Player

function Player.new()	
	local player = {
		position = {x = 380, y = 280, x_speed = 0, y_speed = 0},
		skills = {},
		sprite = {image = love.graphics.newImage('Graphics/Character/Sprite.png'), quads = {}},
		dialog_sprite = love.graphics.newImage('Graphics/Character/Dialog.png'),
		animation_timer = 0,
		animation = 1,
		jump_timer = 0,
		animations = {
			{1,2,3,4,5, framerate=0.1},
			{6,7,8,9,10,11,12,13,14,15},
			{16},
			{17},
			{18},
			{19},
			{20}
		},
		invert_sprite = true
	}
		
	for i = 1,20 do
		player.sprite.quads[i] = love.graphics.newQuad(40*(i-1),0,40,80,800,80)
	end
		
	setmetatable(player, Player)
	
	return player
end

function Player:update_position(dt)
	self.next_coord = {}
	
	self:check_movement(dt)
	
	self:check_gravity(dt)
	
	self:check_collision(dt)
	
	self:check_jump(dt)
	
	self:check_controls(dt)
	
	self.position.x = self.next_coord.x
	self.position.y = self.next_coord.y
	self.next_coord = nil
	
	self.animation_timer = (self.animation_timer + 60*dt)
	if self.animation_timer >= 1000 then self.animation_timer = self.animation_timer - 1000 end
end

function Player:check_movement(dt)
	local x_speed = self.position.x_speed
	if love.keyboard.isDown('d') then
		x_speed = math.min(x_speed + 120*dt, 10)
	elseif love.keyboard.isDown('a') then
		x_speed = math.max(x_speed - 120*dt, -10)
	elseif x_speed ~= 0 then
		local multiplier = 1
		if x_speed > 0 then
			multiplier = -1
		end
		x_speed = x_speed + 120*dt*multiplier
		if x_speed > -1 and x_speed < 1 then
			x_speed = 0
		end
	end
	
	self.animation = 2
	if x_speed > 0 then
		self.invert_sprite = true
	elseif x_speed < 0 then
		self.invert_sprite = false
	else
		self.animation = 1
	end
	
	self.position.x_speed = x_speed
	self.next_coord.x = self.position.x + x_speed*dt*17
end

function Player:check_gravity(dt)
	local fall_speed = 20
	if love.keyboard.isDown('s') then
		fall_speed = 30
		local y_speed = math.min(self.position.y_speed + 120*dt, fall_speed)
	end
	local y_speed = math.min(self.position.y_speed + 120*dt, fall_speed)

	if love.keyboard.isDown('w') then
		y_speed = y_speed - 60*dt
	end
	
	self.position.y_speed = y_speed
	self.next_coord.y = self.position.y + y_speed*17*dt
end

function Player:check_collision(dt)
	local next_x = self.next_coord.x
	local next_y = self.next_coord.y	
	local map = GameController.world.current_map
	
	local min_x = math.floor((self.position.x+5)/20) + 1
	local max_x = math.ceil((self.position.x-5)/20) + 2
	local min_y = math.floor((self.position.y+5)/20) + 1
	local max_y = math.ceil((self.position.y)/20) + 4
	local next_min_y = math.floor((self.next_coord.y+5)/20) + 1
	local next_max_y = math.ceil((self.next_coord.y)/20) + 4
	
	self.on_floor = false
	
	for i = min_x, max_x do
		if self.position.y_speed > 0 or self.on_platform then
			if map[next_max_y][i] == 1 then
				if self.next_coord.y > 20*(max_y - 4) then self.on_floor = true end
				self.next_coord.y = math.min(self.next_coord.y, 20*(max_y - 4))
			elseif map[next_max_y][i] == 2 and self.position.y <= 20*(max_y - 4) then
				if self.next_coord.y > 20*(max_y - 4) then self.on_floor = true end
				self.next_coord.y = math.min(self.next_coord.y, 20*(max_y - 4))
			end
		elseif self.position.y_speed < 0 or self.on_platform then
			if map[next_min_y][i] == 1 then
				if self.next_coord.y < 20*(min_y-1)+5 then self.position.y_speed = 0 end
				self.next_coord.y = math.max(self.next_coord.y, 20*(min_y-1)-5)
			end
		end
	end
	
	self.on_platform = false
	
	if self.position.y_speed > 0 then
		local feet_pos = self.position.y + 80
		local px = self.position.x
		for index, obj in ipairs(GameController.world.current_map.objects) do
			
			if feet_pos <= obj.y and self.next_coord.y + 80 > obj.y and px > obj.x - 35 and px < obj.x + obj.width*20 - 5 then
				self.on_floor = true
				self.on_platform = index
				self.next_coord.y = obj.y - 80
			end
		end
	end
	
	min_x = math.floor((self.next_coord.x)/20) + 1
	max_x = math.ceil((self.next_coord.x)/20) + 2
	
	for i=min_y, max_y do
		if self.position.x_speed > 0 then
			if map[i][max_x] == 1 then
				self.next_coord.x = math.min(self.next_coord.x, 20*(max_x -3))
			end
		elseif self.position.x_speed < 0 then
			if map[i][min_x] == 1 then
				self.next_coord.x = math.max(self.next_coord.x, 20*min_x)
			end
		end
	end
	
	if not self.on_floor then
		if self.position.y_speed < -5 then
			self.animation = 3
		elseif self.position.y_speed > 5 then
			self.animation = 7
		else
			self.animation = 5
		end
	end
end

function Player:check_jump(dt)
	if self.on_floor and self.jump_timer > 0 then
		self.position.y_speed = -30
	end
	
	self.jump_timer = math.max(GameController.player.jump_timer - dt, 0)
end

function Player:check_controls(dt)
	GameController.player.forward = nil
	GameController.player.rewind = nil
	
	if love.keyboard.isDown('right') and GameController.world.timer < 1 then
		GameController.player.forward = true
	elseif love.keyboard.isDown('left') and GameController.world.timer > 0 then
		GameController.player.rewind = true
	end
end

function Player:draw()
	local x = self.position.x
	local y = self.position.y
	local s_x = 1
	local current = self.animations[self.animation]
	local framerate = current.framerate or 1
	local frame = math.floor(self.animation_timer*framerate)%(#current) + 1
	
	if self.invert_sprite then
		x = x + 40
		s_x = -1
	end
	View.draw(self.sprite.image,self.sprite.quads[current[frame]],x,y,0,s_x,1)
end