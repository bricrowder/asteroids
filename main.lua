
function love.load()

	-- get the window data for later use
	gamedata = {}
	gamedata.w, gamedata.h, gamedata.fl = love.window.getMode();
	gamedata.state = "game"									-- the state of the game: menu, game, over, 

	-- setup the relative mode for the mouse
	love.mouse.setRelativeMode(true)

	-- PLAYER DATA
	player = {}
	player.pos = {x = gamedata.w/2, y = gamedata.h-100}		-- initial position of player
	player.speed = 250										-- the movement speed of the player
	player.rad = 10											-- the size of the player in a circle radius
	player.firerate = 0.25									-- the fire rate of the player
	player.fireflag = true									-- the fire flag - if the player can shoot
	player.firetimer = 0									-- the timer for the fire rate
	player.firepower = 3									-- the power cost of shooting
	player.lives = 3										-- the number of player lives
	player.state = "inv"									-- the player state:  inv & orm
	player.staterate = 1									-- how long the player is in "inv" state
	player.statetimer = 0									-- the timer for the state rate
	player.power = 100										-- the power that the player has
	player.powerrate = 1									-- the power increase multiplyer
	player.score = 0										-- the players score
	player.radarflag = false								-- if the radar is on or not
	player.radarpower = 1									-- the cost of the radar
	player.radartimer = 0									-- the timer that checks the radar rate/power
	player.radarrate = 0.25									-- how often the radar draws power

	-- ENEMY DATA - will be copied into tables as required
	enemy_data = {}
	enemy_data.img = love.graphics.newImage("a01.png")		-- the asteroid
	enemy_data.spawnrate = 1								-- the spawn rate of the enemies
	enemy_data.spawnflag = true								-- the spawn flag - if an enemy should be spawned
	enemy_data.spawntimer = 0								-- the time for the spawn rate
	enemy_data.speedmin = 100								-- the minimum speed of the enemy
	enemy_data.speedmax = 200								-- the maximum speed of the enemy
	enemy_data.rotmin = -5									-- the minimum speed of rotation (deg)
	enemy_data.rotmax = 5									-- the maximum speed of rotation (deg)
	enemy_data.radbase = enemy_data.img:getWidth()/2		-- the base radius of the enemy
	-- THIS NEEDS FIXING
	enemy_data.radmin = 1									-- the minimum size of the enemy in circle radius - factor
	enemy_data.radmax = 1									-- the maximum size of the enemy in circle radius - factor
	-- 
	enemy_data.score = 1									-- the score basis for the enemy (which will multiply by the rad

	-- ENEMY TABLE
	enemies = {}
	
	-- BULLET DATA - will be copied into bullet tables are required
	bullet_data = {}
	bullet_data.speed = 500									-- speed of the bullet
	bullet_data.rad = 5										-- the size of the bullet in a circle radius
	
	-- PLAYER BULLETS TABLE
	pbullets = {}
	
	-- TEXT DATA
	text_data = {}
	text_data.speed = 100
	text_data.life = 0.5
	
	-- TEXT TABLE
	text = {}
	
	-- POWERUP DATA
	powerup_data = {}
	powerup_data.speed = 100								-- the speed of the powerups movement
	powerup_data.rad = 10									-- the radius of the powerup collision detection
	powerup_data.rate = 50									-- the rate (out of 100) that a power will be dropped
	powerup_data.direction = 1								-- the direction that the powerup travels
	
	-- EXPLOSION DATA
	exp_data = {}
	exp_data.speedmin = 50									-- the speed of the explosion - controls how fast the drawn stuff moves...
	exp_data.speedmax = 100									-- the speed of the explosion - controls how fast the drawn stuff moves...
	exp_data.life = 1										-- the life in time of the explosion
	
	-- EXPLOSION TABLE
	explosions = {}
	
	-- POWERUP TABLE
	powerups = {}
	
	bar = love.graphics.newImage("blankbar.png")
	
	-- SHADERS
	shader_passthru = love.graphics.newShader[[
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
			vec4 pixel = Texel(texture, texture_coords);
			return pixel;
		}
	]]
	
	shader_BW = love.graphics.newShader[[
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
			vec4 pixel = Texel(texture, texture_coords);
			number average = (pixel.r + pixel.g + pixel.b) / 3.0;
			pixel.r = average;
			pixel.b = average;
			pixel.g = average;
			return pixel;
		}
	]]
	
	shader_rotatecolour_totaltime = 0						-- timer variable for rotatecolour	
	shader_rotatecolour = love.graphics.newShader[[
		extern number t;
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
			return vec4((1.0+sin(t))/2.0, abs(cos(t)), abs(sin(t)), 1.0);
		}
	]]	
	
	shader_redgrad_progress = love.graphics.newShader[[	
		extern number p;
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){						
			if (texture_coords.x*100 < p)
				return vec4(texture_coords.x,0.0,0.0,1.0);
			else
				return vec4(0.0);
		}
	]]
	
	shader_greenCRT_totaltime = 0
	shader_greenCRT = love.graphics.newShader[[
		extern number t;
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
			vec4 pixel = Texel(texture, texture_coords);
			number x = 0.5 + 0.5 * fract(sin(dot(texture_coords, vec2(12.9898, 78.233)))* 43758.5453);
			pixel.r = 0.0;
			pixel.b = 0.0;
			if (t>=texture_coords.y && t<texture_coords.y+0.1) pixel.g = 0.5*pixel.g;
			pixel.g += x;
			return pixel;
		}
	]]
	--if (t>=texture_coords.x && t<texture_coords.x+0.06) pixel.g = 0.5;
	shader_dark = love.graphics.newShader[[
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
			vec4 pixel = Texel(texture, texture_coords);
			number average = (pixel.r + pixel.g + pixel.b) / 3.0;
			pixel.r = pixel.r - 0.90*pixel.r;
			pixel.g = pixel.g - 0.90*pixel.g;
			pixel.b = pixel.b - 0.90*pixel.b;
			return pixel;
		}
	]]
	shader_explosion = love.graphics.newShader[[
		extern number t;
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
			return vec4(t/2, t/2, t/4, 1.0 );
		}
	]]
	
	shader_noise = love.graphics.newShader[[
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
			number x = 0.5 + 0.5 * fract(sin(dot(texture_coords, vec2(12.9898, 78.233)))* 43758.5453);
			vec4 pixel = Texel(texture, texture_coords);
			pixel = vec4(x, x, x, pixel.a); 
			return pixel;
		}	
	]]	
	
end


function love.keypressed(key)
	-- the player quit action via the escape key, also gives the mouse back
	if key == "escape" then
		love.mouse.setRelativeMode(false)
		love.event.quit()
	end
	
	-- the player has the radar on or not
	if key == "tab" then
		if player.radarflag == true then 
			player.radarflag = false
			player.radartimer = 0
		else
			if player.power - player.radarpower > 0 then player.radarflag = true end
		end
	end
end

function love.update(dt)

	if gamedata.state == "game" then
		-- pass shader variables
		shader_rotatecolour_totaltime = shader_rotatecolour_totaltime + dt*10
		shader_rotatecolour:send("t",shader_rotatecolour_totaltime)
		shader_greenCRT_totaltime = shader_greenCRT_totaltime + dt/2
		if shader_greenCRT_totaltime > 1 then shader_greenCRT_totaltime = 0 end
		shader_greenCRT:send("t",shader_greenCRT_totaltime)
		
	
		-- check for player movement - left & right
		if love.keyboard.isDown("a", "A") then
			player.pos.x = player.pos.x - player.speed * dt
			if player.pos.x - player.rad < 0 then player.pos.x = player.rad end
		end
		if love.keyboard.isDown("d", "D") then
			player.pos.x = player.pos.x + player.speed * dt
			if player.pos.x + player.rad > gamedata.w then player.pos.x = gamedata.w - player.rad end
		end

		-- the player has hit the space bar
		if love.keyboard.isDown("space") and player.fireflag == true and player.power - player.firepower > 0 then
			player.fireflag = false
			player.firetimer = 0
			player.power = player.power - player.firepower
			
			-- add a bullet to the bullet list and set the position, direction, etc.
			local bd = {}
			bd.speed = bullet_data.speed
			bd.rad = bullet_data.rad
			bd.pos = {x = player.pos.x, y = player.pos.y}
			bd.direction = -1		
			table.insert(pbullets, bd)
			bd = nil
		end
		
		-- update the radar power timer
		if player.radarflag == true then
			if player.power <= 0 then 
				player.radarflag = false
			else
				player.radartimer = player.radartimer + dt
				if player.radartimer >= player.radarrate then
					player.radartimer = 0
					player.power = player.power - player.radarpower
				end
			end
		end
		
		-- the player fire rate timer update
		if player.fireflag == false then
			player.firetimer = player.firetimer + dt
			if player.firetimer >= player.firerate then player.fireflag = true end
		end
		
		-- the player state timer
		if player.state == "inv" then
			player.statetimer = player.statetimer + dt
			if player.statetimer > player.staterate then player.state = "norm" end
		end
		
		-- the player power rate increase
		player.power = player.power + dt * player.powerrate
		if player.power > 100 then player.power = 100 end 
		
		-- send the power rate to the shader
		shader_redgrad_progress:send("p",player.power)
		
		-- update the player bullet positions, remove if out of screen
		local i = 1
		while i <= #pbullets do
			local removed = 0
			pbullets[i].pos.y = pbullets[i].pos.y + pbullets[i].speed * dt * pbullets[i].direction
			if pbullets[i].pos.y < 0 - pbullets[i].rad then 
				table.remove(pbullets,i) 
				removed = 1
			end
			if removed == 0 then i = i + 1 end
		end
		
		-- update enemy spawner
		if enemy_data.spawnflag == true then
			enemy_data.spawnflag = false
			enemy_data.spawntimer = 0
			
			-- add an emeny to the enemy table using the randomized data from min/max values from the enemy_data table
			local e = {}
			e.speed = love.math.random(enemy_data.speedmin, enemy_data.speedmax)
			e.radfactor = love.math.random(enemy_data.radmin, enemy_data.radmax)
			e.rad = e.radfactor * enemy_data.radbase
			e.pos = {x = love.math.random(e.rad, gamedata.w-e.rad), y = e.rad*-1}
			e.imgposoffset = {w = enemy_data.img:getWidth() * e.radfactor / 2, h = enemy_data.img:getHeight() * e.radfactor / 2}
			e.rot = love.math.random(enemy_data.rotmin, enemy_data.rotmax)
			e.currot = 0
			e.direction = 1
			e.score = e.rad * enemy_data.score
			table.insert(enemies,e)
			e = nil
		end
		
		-- updated enemy spawn timer
		if enemy_data.spawnflag == false then
			enemy_data.spawntimer = enemy_data.spawntimer + dt
			if enemy_data.spawntimer > enemy_data.spawnrate then enemy_data.spawnflag = true end
		end
		
		-- update enemy positions/rotations
		i = 1
		while i <= #enemies do
			local removed = 0
			enemies[i].pos.y = enemies[i].pos.y + enemies[i].speed * dt * enemies[i].direction
			enemies[i].currot = enemies[i].currot + enemies[i].rot
			if enemies[i].currot >= 360 then enemies[i].currot = 0 end
			if enemies[i].currot < 0 then enemies[i].currot = 360 end
			
			if enemies[i].pos.y > gamedata.h + enemies[i].rad then 
				table.remove(enemies,i)
				removed = 1
			end
			if removed == 0 then i = i + 1 end
		end	
		
		-- update explosion positions
		i = 1
		while i <= #explosions do
			local removed = 0
			explosions[i].lifetimer = explosions[i].lifetimer + dt
			if explosions[i].lifetimer > exp_data.life then
				table.remove(explosions,i)
				removed = 1
			else
				-- make the circle bigger, move the points 
				explosions[i].circlerad = explosions[i].circlerad + exp_data.speedmin/2 * dt
				for j = 1, 100 do
					explosions[i].points[j].pos.x = explosions[i].points[j].pos.x + math.sin(math.rad(explosions[i].points[j].direction)) * dt * explosions[i].points[j].speed
					explosions[i].points[j].pos.y = explosions[i].points[j].pos.y + math.cos(math.rad(explosions[i].points[j].direction)) * dt * explosions[i].points[j].speed
				end
			end
			if removed == 0 then i = i + 1 end
		end
		
		-- check for bullet/enemy collisions - circle intersects
		i = 1
		while i <= #pbullets do
			local removed = 0

			local j
			
			for j = 1, #enemies do
				local dx = pbullets[i].pos.x - enemies[j].pos.x
				local dy = pbullets[i].pos.y - enemies[j].pos.y
				local h1 = pbullets[i].rad - enemies[j].rad
				local h2 = pbullets[i].rad + enemies[j].rad
				
				-- use pythag to check hypotenuse lengths 
				if math.abs(h1) <= math.sqrt(math.pow(dx,2) + math.pow(dy,2)) and math.sqrt(math.pow(dx,2) + math.pow(dy,2)) <= math.abs(h2) then
					-- add to text table
					local t = {}
					t.pos = {x = enemies[j].pos.x, y = enemies[j].pos.y}
					t.text = enemies[j].score
					t.speed = text_data.speed
					t.lifetimer = 0
					table.insert(text, t)
					t = nil
					-- add the the player score
					player.score = player.score + enemies[j].score
					-- add to the powerup table
					if (love.math.random(1,100) > powerup_data.rate) then
						local p = {}
						p.pos = {x = enemies[j].pos.x, y = enemies[j].pos.y}
						p.speed = powerup_data.speed
						p.rad = powerup_data.rad
						p.direction = powerup_data.direction
						p.value = 10
						table.insert(powerups,p)
						p = nil
					end
					-- add to the explosion table
					local e = {}
					e.pos = {x = enemies[j].pos.x, y = enemies[j].pos.y}
					e.lifetimer = 0
					e.circlerad = 0
					e.points = {}
					local k = 1
					for k = 1, 100 do
						e.points[k] = {}
						e.points[k].direction = love.math.random(0,359)
						e.points[k].speed = love.math.random(exp_data.speedmin,exp_data.speedmax)
						e.points[k].pos = {x = enemies[j].pos.x, y = enemies[j].pos.y}
					end
					table.insert(explosions, e)
					e = nil
					-- now remove the enemy
					table.remove(enemies,j)
					removed = 1
					break
				end
			end		
			if removed == 1 then
				table.remove(pbullets,i)
			else
				i = i + 1
			end		
		end	
		
		if player.state == "norm" then
			-- check for enemy/player collisions - circle intersects
			for i = 1, #enemies do
				local dx = enemies[i].pos.x - player.pos.x
				local dy = enemies[i].pos.y - player.pos.y
				local h1 = enemies[i].rad - player.rad
				local h2 = enemies[i].rad + player.rad
				
				-- use pythag to check hypotenuse lengths 
				if math.abs(h1) <= math.sqrt(math.pow(dx,2) + math.pow(dy,2)) and math.sqrt(math.pow(dx,2) + math.pow(dy,2)) <= math.abs(h2) then
					table.remove(enemies,i)
					player.lives = player.lives - 1
					player.state = "inv"
					player.statetimer = 0
					if player.lives == 0 then gamedata.state = "over" end
					break
				end
			end
			
			-- check for player/powerup collisionos - circle intersects			
			for i = 1, #powerups do
				local dx = powerups[i].pos.x - player.pos.x
				local dy = powerups[i].pos.y - player.pos.y
				local h1 = powerups[i].rad - player.rad
				local h2 = powerups[i].rad + player.rad
				
				-- use pythag to check hypotenuse lengths 
				if math.abs(h1) <= math.sqrt(math.pow(dx,2) + math.pow(dy,2)) and math.sqrt(math.pow(dx,2) + math.pow(dy,2)) <= math.abs(h2) then
					player.power = player.power + powerups[i].value
					if player.power > 100 then player.power = 100 end
					table.remove(powerups,i)
					break
				end
			end
			
		end
		
		
		-- update the text table/timers
		i = 1
		while i <= #text do
			local removed = 0
			text[i].pos.y = text[i].pos.y - text[i].speed * dt
			text[i].lifetimer = text[i].lifetimer + dt
			if text[i].lifetimer > text_data.life then
				table.remove(text, i)
				removed = 1
			end
			if removed == 0 then i = i + 1 end
		end
		
		i = 1
		while i <= #powerups do
			local removed = 0
			powerups[i].pos.y = powerups[i].pos.y + powerups[i].speed * dt
			if powerups[i].pos.y > gamedata.h + powerups[i].rad then 
				table.remove(powerups,i)
				removed = 1
			end
			if removed == 0 then i = i + 1 end 
		end
		
	elseif gamedata.state == "menu" then
		-- do nothing right now
	elseif gamedata.state == "over" then
		-- reset the game
		if love.keyboard.isDown("return") then
			gamedata.state = "game"
			player.state = "inv"
			player.lives = 3
			player.power = 100
			player.powerrate = 1
			player.score = 0
			pbullets = {}
			enemies = {}
		end
	end
end


function love.draw()

	if gamedata.state == "game" then
		if player.state == "norm" then
			love.graphics.circle("fill", player.pos.x, player.pos.y, player.rad, 32)
		else
			love.graphics.circle("line", player.pos.x, player.pos.y, player.rad, 32)
		end
				
		love.graphics.setShader(shader_rotatecolour)
		for i = 1, #pbullets do
			love.graphics.circle("fill",pbullets[i].pos.x, pbullets[i].pos.y, pbullets[i].rad, 32)
		end
		
		if player.radarflag == true then
			love.graphics.setShader(shader_greenCRT)
		else
			love.graphics.setShader(shader_passthru)
		end
		for i = 1, #enemies do
			love.graphics.draw(enemy_data.img, enemies[i].pos.x, enemies[i].pos.y, math.rad(enemies[i].currot), enemies[i].radfactor, enemies[i].radfactor, enemies[i].imgposoffset.w, enemies[i].imgposoffset.h)
			--love.graphics.circle("line",enemies[i].pos.x, enemies[i].pos.y, enemies[i].rad, 32)
		end
		
		love.graphics.setShader(shader_explosion)
		for i = 1, #explosions do
			shader_explosion:send("t", 1.0 - explosions[i].lifetimer)
			love.graphics.circle("line", explosions[i].pos.x, explosions[i].pos.y, explosions[i].circlerad, 32)
			for j = 1, 100 do
				love.graphics.points(explosions[i].points[j].pos.x, explosions[i].points[j].pos.y)
			end
		end
		
		love.graphics.setShader()
		for i = 1, #powerups do
			love.graphics.circle("line", powerups[i].pos.x, powerups[i].pos.y, powerups[i].rad, 32)
		end
		for i = 1, #text do
			love.graphics.print(text[i].text, text[i].pos.x, text[i].pos.y)
		end
		
		love.graphics.print("Lives: "..player.lives, 10, 10)
		love.graphics.print("Power: "..math.floor(player.power), 10, 30)
		love.graphics.print("Score: "..player.score, 10, 50)

		love.graphics.setShader(shader_redgrad_progress)
		love.graphics.draw(bar, 10, 70)
		love.graphics.setShader()
		love.graphics.setColor(255,255,255,255)
		love.graphics.rectangle("line",10,70,100,15)
		
		love.graphics.print("FPS: "..love.timer.getFPS(),10,90)
				
	elseif gamedata.state == "menu" then
	
	elseif gamedata.state == "over" then
		love.graphics.print("GAME OVER - SPACE to Continue",375,300)
	end
end