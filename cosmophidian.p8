pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--[[
sfx 30 flying
sfx 31 laser
sfx 32 dash 
sfx 33 shoot
sfx 34 successfull parry
sfx 35 pickup
sfx 36 low health
sfx 37 game start
sfx 38 death
sfx 39 enemy shooting sfx
sfx 40 enemy death sfx
sfx 41 enemy got hit sfx

]]


ship={}
null=function() end
background=2
void=0
outline=0
freeze_frame=0

function _init()
	start_menu()
	cam={x=0,y=0}
	cam2={x=0,y=0}
end



function start_game_over()
	_update60=game_over_draw
	_draw=game_over_update
	//list_enemies={}
	//list_projectiles={}
	add_animation(function ()
		//fadeout(20)
		for i=0,100 do
			fi=flr(fadout_amount/fadeout_args.fc)+1
			for n=1,fadeout_args.pn do
				pal(n,fades[n][fi],1)
			end
			yield()
			fadout_amount+=0.01
		end
		fadout_amount=0
		fi=flr(fadout_amount/fadeout_args.fc)+1
		for n=1,fadeout_args.pn do
			pal(n,fades[n][fi],1)
		end
		start_menu()
	end)
end

function game_over_draw()
	cls(background)
	draw_health_circle()
	
	screen_shake()
	camera(cam.x-64,cam.y-64)
	draw_stars()
	draw_all(list_projectiles)
	draw_all(list_particles)
	draw_all(list_enemies)
	
end

function game_over_update()
	tt+=1
	tt=tt%10000
	update_animations()
	//upd_ship()
	update_all_entities()
end




function start_menu()
	_update60=menu_update
	_draw=menu_draw
	game_starting=false
	list_particles={}
	list_enemies={}
	list_draw_objects={}
	list_projectiles={}
	list_stars={}
	play_btn_color=7
	shp=add_object({x=48,
		y=32,
		dx=0,
		dy=0,
		group=list_particles,
		update={function (self)
			self.x+=cos(t()/10)/10
			self.y=self.x/3+64+5*cos(self.x/300+t()/10)*(1+sin(t()/130))-45
		end}}
		,ship_d_o)
	poke(0x5f2d, 1)
	music(1,100,5)
	camera()
	cls(0)
	tt=0
	
end

function menu_draw()
	cls(2)

	draw_all(list_particles)
	pal(7,play_btn_color)
	spr(112,10,54,-2+tt/2,3)
	print("press ❎ to play",30,90,play_btn_color)
	line(-6+8*tt/2,55,-6+8*tt/2,70,play_btn_color)
	draw_all(list_draw_objects)
	//print(stat(0),0,0)
	//print(stat(1),0,20)
	//print(stat(2),0,40)
end

function menu_update()
	tt+=1
	tt=tt%10000
	update_animations()
	update_all_entities()
	update_all(list_draw_objects)
	if tt%4==0 then
	local snake_inner=8
	local snake_outer=8
	if tt<60 then
		snake_inner=12
		snake_outer=12
	end
	if tt%71==0 or tt%39==0 or tt%38==0then
		snake_outer=1
		snake_inner=1
	end
	add_object({
		group=list_particles,
		x=160,
		y=64,
		dx=-4,
		dy=0,
		c1=snake_inner,
		c2=snake_outer,
		collider_r=min(tt/5,15),
		draw=drw_debug,
		update={function (self)
			self.x-=3
			self.y=self.x/3+64+5*cos(self.x/300+t()/10)*(1+sin(t()/130))-20
		end, bh_tick_hp},
		sd_rate=1,
		hp=60}, template_basic_particle)
	end
	add_object({
		group=list_particles,
		x=shp.x,
		y=shp.y-1,
		dx=-2,
		dy=randb(-10,10)/20-0.2,
		c1=12,
		draw=drw_circle,
		sd_rate=1,
		hp=40+randb(0,20)}, template_basic_particle)
	--[[
	add_particle(
				shp.x,
				shp.y-2,
				-2,
 				-0.4+randb(-3,4)/5,
				50+randb(-3,4),12)
	shp.y+=sin(0.3+tt/100)*(1.1+sin(0.5+tt/1000))/15
	
	add_particle(
				256,
				120,
				-4,
 				-1+sin(tt/167)/10,
				min(10+3*tt,400),8)
				]]
	if btnp(❎) and not game_starting then
		game_starting=true
		add_animation(function ()
			sfx(37,3)
			play_btn_color=12
			for i=0,10 do
				yield()
			end
			play_btn_color=7
			for i=0,10 do
				yield()
			end
			end)
		add_animation(function ()
			for i=0,20 do
				shp.x-=i/100
				shp.y-=i/500
				yield()
			end
			for i=0,10 do
				shp.x-=0.5
				shp.y-=0.2
				yield()
			end
			for i=0,80 do
				shp.x+=1+i/10
				shp.y+=0.6-i/2000
				yield()
			end
			//fx_explode(shp)
			
			start_game()
		end)
	end
end



function _update60()
	end

function start_game()
	music(5,100,5)
	
	enemy_volume_max=30
	despawn_distance=150
	ship={x=64,y=64,dx=0,dy=0,
						ax=0,ay=0,
						hp=40,
						maxhp=40,
						regen=0.01,//0.02,
						collider_r=10,
						damage=2,
						inv_damage=5,
						angle=0.25,
						c1=12,
						invincible=0,
						speed=0,
						on_hit={fx_explode,oh_take_damage},
						on_pickup={oh_take_damage},
						laser_charge=20,
						laser_charge_max=40,
						laser_charge_threshold=15,
						nosex=0,
						nosey=0,
						acc=0.10,
						lacc=0.008,
						dcc=0.007,//0.005
						turning_d=0.1,
						maxspeed=1.8,
						scale=1,
						states={},

						dash_cost=2,
						laser_cost=0.2,
						}
	ship.states={
		turning=0,
 		flying=false,
		shooting=false,
		shooting_cd=0,
		shooting_cd_value=8,
		laser=false,
		parry=0,
		parry_cd=0,
		parry_cd_value=40,
	}
	tt=-1
	base_turning=0.02
	fly_turning=0.005
	shoot_turning=0.02
	laser_turning=0.003
	cam={x=0,y=0}
	laser={length=120,segments=9}
	list_stars={}
	list_enemies={}
	list_particles={}
	list_projectiles={}


	
	add_stars()

	_update60=game_update
	_draw=game_draw
end

	
function game_update()

	cam2.x+=(ship.x-cam2.x)/4
	cam2.y+=(ship.y-cam2.y)/4
	if freeze_frame >0 then
		freeze_frame=min(freeze_frame,50)
		shake_explode(0.01+0.2/freeze_frame)
		freeze_frame-=1
	else
		ship.laser_charge=min(ship.laser_charge,ship.laser_charge_max)
		ship.hp+=ship.regen
		ship.hp=min(ship.maxhp,ship.hp)
		if ship.invincible>0 then
			ship.invincible-=1
		end	
		tt+=1
		tt=tt%10000
		manage_enemy_spawning()
		update_animations()
		handle_input()
		upd_ship()
		update_all_entities()
		manage_collisions()
		manage_player_collisions()
		clear_collisions()
	end
	if (ship.hp/ship.maxhp)<=0.33 and tt%60==0 then
		sfx(36,3)
	end
	if ship.hp<=0 then
		sfx(38,3)
		start_game_over()
	end
end
health_circle_r=100
function 
	draw_health_circle()
	cls(void)

	--[[local x=tt%50/50
	//local current_r=100*(1-x)
	//circ(ship.x,ship.y,current_r,0)
	//local current_r=100*(1-x^3)
	//circ(ship.x,ship.y,current_r,7)]]
	
	local x=1-ship.hp/ship.maxhp
	local current_r=92*(1-x^1.25)
	if x==0 then
		current_r=120
	end
	

	if current_r!=health_circle_r then
	health_circle_r+=flr((current_r-health_circle_r)/2)
	end
	
	circfill(ship.x,ship.y,health_circle_r,background)
	//print(ceil((1-x)*100),ship.x+20,ship.y,7)
	//print("%",ship.x+40,ship.y,7)
end

function game_draw()
	cls(background)
	draw_health_circle()
	screen_shake()
	camera(cam.x-64,cam.y-64)
	draw_stars()
	//draw_particles()
	if freeze_frame >0 and ship.states.parry>0 then
		fillp(0b1011111111111111.1)
		circfill(ship.x,ship.y,5+150/freeze_frame,12)
		fillp()
	end
	draw_all(list_projectiles)
	draw_all(list_particles)
	draw_all(list_enemies)
	

	draw_ship()

	draw_ui()
	print("difficulty:",cam.x-64,cam.y-64)
	print(enemy_volume_max,cam.x-20,cam.y-64)

	//draw_collisions()
 	//clear_collisions()
	
	--[[
	print(#projectiles,cam.x-64,cam.y-10,7)
	print(#enemies,cam.x-64,cam.y-54,7)
	
	print(stat(7),cam.x-64,cam.y-64,7)
	print(ship.hp,ship.x,ship.y+10,15)
	print(ship.states.parry,ship.x+32,ship.y+32)
	]]--

	
	
	end
-->8
//ship update and input
//laser



function draw_ui()
	if(ship.laser_charge>0)then
	rectfill(cam.x-64,cam.y+64,cam.x-64+128*(ship.laser_charge)/ship.laser_charge_max,cam.y+60,12)
	end
	--[[
	local ri_y=34
	local l=30
	local laser_bar_color=12
	local hp_bar_color=8
	
	if ship.laser_charge>=ship.laser_charge_max then 
		if tt%16>8 then	
			laser_bar_color=7
		end
	else
	if ship.laser_charge>ship.laser_charge_threshold then 
		if tt%32>16 then	
			laser_bar_color=7
		end
	end
	end	

	
	if ship.hp<=0.45*ship.maxhp then 
		if tt%15>8 then	
		hp_bar_color=9
		end
	end
	//print(ship.hp,ship.x+10,ship.y)
	//print(ship.laser_charge,ship.x+10,ship.y+10)
	//rectfill(cam.x-64,cam.y-3+ri_y,cam.x-58,cam.y+24+ri_y,9)
	if ship.laser_charge>0 then
	//rectfill(cam.x-64,ri_y+cam.y+24-(ship.laser_charge/ship.laser_charge_max)*l,cam.x-58,ri_y+cam.y+24,laser_bar_color)
	end
	fillp()
	clip(0,128-4-(ship.laser_charge/ship.laser_charge_max)*l,128,128)
	pal(12,laser_bar_color)
	spr(162,cam.x-64+2,ri_y+cam.y-4,1,5)
	pal()
	clip()

	clip(4,0,(ship.hp/ship.maxhp)*l,128)
	pal(8,hp_bar_color)
	spr(212,cam.x-64+4,cam.y+54,4,1)
	pal()
	clip()
	spr(176,cam.x-64,ri_y+cam.y-10,2,5)
	spr(226,cam.x-48,ri_y+cam.y-10+24,3,2)
	]]--
end



function upd_ship()
	ship.states.parry_cd-=1
	ship.states.shooting_cd-=1

	ship.turning_d=base_turning
	
	if ship.states.shooting then
		ship.turning_d=shoot_turning
	end

	if ship.states.parry>0 then
		ship.states.parry-=1
		ship.states.laser=false
		ship.states.shooting=false
	end
	
	if ship.states.flying then
		//sfx(5)
		add_object({group=list_particles,
				x=ship.ass1x,
				y=ship.ass1y,
				dx=ship.dx-40*ship.acc*cos(ship.angle)+randb(-3,4)/5,
				dy=ship.dy-40*ship.acc*sin(ship.angle)+randb(-3,4)/5,
				hp=20,
				c1=12},
				template_basic_particle)

		ship.turning_d=fly_turning
		ship.ay=ship.acc*sin(ship.angle) 
		 ship.ax=ship.acc*cos(ship.angle) 
	end
	
	
	if ship.states.laser then
		//sfx(1)
		shake_gun(0.1)
		ship.turning_d=laser_turning
		fire_laser(
			ship.nosex,
			ship.nosey,
			ship.angle,
			laser.length,
			laser.segments)
	
		ship.ay-=ship.lacc*sin(ship.angle) 
		ship.ax-=ship.lacc*cos(ship.angle) 
	end
	
	if ship.states.shooting and ship.states.shooting_cd<0 then
		sfx(33,3)
		ship.states.shooting_cd=ship.states.shooting_cd_value
		add_object(
									{	group=list_projectiles,
										x=ship.nosex,
										y=ship.nosey,
										angle=ship.angle,
										dx=ship.dx,
										dy=ship.dy},
										template_bullet_ship)
		add_object({
			group=list_particles,
			hp=3,
			draw=function ()
				rspr(9,								//draw flash
					ship.nosex,
					ship.nosey,
					ship.angle,
					0,
					1.5)
			end
		},template_basic_particle)
	end

		
	
	ship.angle+=ship.turning_d*ship.states.turning
	local ac=cos(ship.angle)
	local as=sin(ship.angle)
	
	ship.speed=pifagor(ship.dx,ship.dy)
	
	ship.x+=ship.dx
	ship.y+=ship.dy
	ship.dx+=ship.ax
	ship.dy+=ship.ay
	ship.dx-=sgn(ship.dx)*ship.dcc
	ship.dy-=sgn(ship.dy)*ship.dcc

	local curvel=atan2(ship.dx,ship.dy)
	local cac =cos(curvel)
	local cas =sin(curvel)

	if pifagor(ship.dx,ship.dy)>ship.maxspeed 
		then
		ship.dx=ship.maxspeed*cac*0.97
		ship.dy=ship.maxspeed*cas*0.97
		end

	ship.nosex=ship.x+7*ac
	ship.nosey=ship.y+7*as
	ship.assx=ship.x-4*ac
	ship.assy=ship.y-4*as
	ship.ass1x=ship.x-4*cos(ship.angle+0.01)
	ship.ass1y=ship.y-4*sin(ship.angle+0.01)

	
	ship.ay=0 
	ship.ax=0
	
end




function draw_ship()
	if ship.states.parry>0 then
		//fillp(0b0111111111011111.1)-- or 0x33cc
		//circfill(ship.x,ship.y,10, 0xc)
		circ(ship.x,ship.y,ship.collider_r-1+tt/2%4,12)
		//fillp()
		//spr(10+t%3,ship.x-3,ship.y-3)
	end

	if ship.states.laser then 
		draw_laser(ship.nosex,
													ship.nosey,
													ship.angle,
													laser.length,
													false)
		rspr(2,ship.x,
									ship.y,
									ship.angle,
									1,
									ship.scale)
	else
		//spr(2,ship.x,ship.y)
		
		rspr(1,ship.x,
									ship.y,
									ship.angle,
									1,
									ship.scale)
	end
	
	
				

	//print(#list_particles,ship.x,ship.y+15)
end

function handle_input()
	ship.states.turning=0
	
	ship.states.shooting=false
	ship.states.laser=false
	if btn(⬅️) and not btn(➡️) then 
		ship.states.turning=1 
	end
	if btn(➡️) and not btn(⬅️) then
		ship.states.turning=-1
	end
	if btn(⬆️) and not btn(⬇️) then 
		if ship.states.flying ==false then 
			sfx(30,3)
		end
		ship.states.flying=true
		
	else
		ship.states.flying=false
	end
	if btn(⬇️) and ship.states.parry_cd <0 and (ship.laser_charge>ship.laser_cost or (ship.laser_charge>0 and ship.laser_charge-ship.laser_cost<=0))then
		sfx(31,3)
		ship.laser_charge-=ship.laser_cost
		ship.states.laser=true
	end
	
	if btn(🅾️) then
		local qwerty=ship.angle
		
		//FIXME parry
		if ship.states.parry_cd <0 and (ship.laser_charge>ship.dash_cost or (ship.laser_charge>0 and ship.laser_charge-ship.dash_cost<=0))then
			sfx(32,3)
			ship.laser_charge-=ship.dash_cost
			fx_explode(ship)
			local qq=ship.x
			local ww=ship.y
			local ee=ship.dx
			local rr=ship.dy
			add_object({group=list_particles,
			hp=10,
				draw=function ()
				line(qq,ww,qq+20*ee,ww+rr*20,12)
			end},template_basic_particle)
			add_animation(function ()
				ship.x+=20*ship.dx
				ship.y+=20*ship.dy
				for i=0,8 do
				//ship.dx+=1*cos(ship.angle)
				//ship.dy+=1*sin(ship.angle)
				yield()
				end
			end)
		ship.states.parry=10
		ship.states.parry_cd=ship.states.parry_cd_value
		end
	end
	if btn(❎) then
		ship.states.shooting=true
	end
end


//laser






function fire_laser(x1,y1,a,l,l1)
	local ca=cos(a) 
	local sa=sin(a)
	local x2=x1+l*ca
	local y2=y1+l*sa
	local hx=(x2-x1)/l1
	local hy=(y2-y1)/l1
	for i=0,l1 do
		
		local a={}
		a.x=x1+hx*i
		a.y=y1+hy*i
		a.collider_r=5
		a.damage=3
		a.inv_damage=5
		a.c=7
		a.on_hit={}
		a.on_death={}
		a.invincible=0
		
		add_friend_projectile_collider(a)
	end	
end




function draw_laser(x,y,a,l,part)
	ca=cos(a) sa=sin(a)
	x1=x+l*ca
	y1=y+l*sa
	//line(x,y,x1,y1,1)
	decay_line(x,y,x1,y1,80,4,2,12,false)
	decay_line(x,y,x1,y1,80,3,1,10,part)
	decay_line(x,y,x1,y1,80,2,2,7,false)
	
	
				
end







-->8
//manage collisions
cr_dimensions=12 //or 13
cr_border=3
cr_cell=128/(cr_dimensions-2*cr_border)

collision_regions={}

player_collisions={}



for i=1,cr_dimensions do
	collision_regions[i]={}
	for j=1,cr_dimensions do
		collision_regions[i][j]={}
		collision_regions[i][j].enemies={}
		collision_regions[i][j].fprojectile={}
	end
end

function cr_get_region(a)
	local i=1+cr_border+flr((a.x-cam.x+64)*(cr_dimensions)/(128+2*cr_border*cr_cell))
	local j=1+cr_border+flr((a.y-cam.y+64)*(cr_dimensions)/(128+2*cr_border*cr_cell))
	return i,j
end

function cr_is_on_screen(a)
	return a.x-cam.x+64>0-cr_cell
				and a.x-cam.x+64<128+cr_cell*cr_border
				and a.y-cam.y+64>0-cr_cell*cr_border
				and a.y-cam.y+64<128+cr_cell*cr_border
end

function cr_is_near_player(a)
		return a.x>ship.x-25
				and a.x<ship.x+25
				and a.y>ship.y-25
				and a.y<ship.y+25

end

function add_enemy_collider(e)
	if cr_is_on_screen(e) then
			local i,j=cr_get_region(e)
			add(collision_regions[i][j].enemies,e)
		end
end

function add_enemy_projectile_collider(p)
	if cr_is_near_player(p) then
	add(player_collisions,p)
	end
end

function add_friend_projectile_collider(p)
	if cr_is_on_screen(p) then
			local i,j=cr_get_region(p)
			add(collision_regions[i][j].fprojectile,p)
		end
end

function clear_collisions()
	for i=1,cr_dimensions do
		for j=1,cr_dimensions do
			collision_regions[i][j].enemies={}
 			collision_regions[i][j].fprojectile={}
			collision_regions[i][j].is_colliding=false
		end
	end
	player_collisions={}
end

function collide_in_region(p,i,j)
	for e in all(collision_regions[i][j].enemies) do
		if collide(p,e)and p.invincible==0 and e.invincible==0 then
			collision_regions[i][j].is_colliding=true
			for f in all(p.on_hit) do
				f(p,e)
			end
			for f in all(e.on_hit) do
				f(e,p)
			end
		end
	end
end
	

function manage_player_collisions()
	for p in all(player_collisions) do
		if collide(p,ship) then 
			if ship.states.parry>0 then
				if p.is_parriable and 
						p.invincible==0 then
							for op in all(p.on_parry) do
								op(p,ship)
							end
						end
					else
				if ship.invincible==0 then
					for oh in all(p.on_hit) do
						oh(p,ship)
					end
	
					if p.is_pickup==true then
						for op in all(ship.on_pickup) do
								op(ship,p)
						end
					else
						for oh in all(ship.on_hit) do
							oh(ship,p)
						end
					end
				end
			end
		end
	end
end
		

function manage_collisions()
	for i=2,cr_dimensions-1 do
		for j=2,cr_dimensions-1 do
			for p in all(collision_regions[i][j].fprojectile) do
				collide_in_region(p,i,j)
				collide_in_region(p,i+1,j)
				collide_in_region(p,i-1,j)
				collide_in_region(p,i,j+1)
				collide_in_region(p,i,j-1)
				collide_in_region(p,i-1,j-1)
				collide_in_region(p,i+1,j-1)
				collide_in_region(p,i+1,j+1)
				collide_in_region(p,i-1,j+1)
			end
		end
	end
	i=1
		for j=2,cr_dimensions-1 do
			for p in all(collision_regions[i][j].fprojectile) do
				collide_in_region(p,i,j)
				collide_in_region(p,i+1,j)
				collide_in_region(p,i,j+1)
				collide_in_region(p,i,j-1)
			end
		end
	i=cr_dimensions
		for j=2,cr_dimensions-1 do
			for p in all(collision_regions[i][j].fprojectile) do
				collide_in_region(p,i,j)
				collide_in_region(p,i,j+1)
				collide_in_region(p,i-1,j)
				collide_in_region(p,i,j-1)
			end
		end
	j=1
		for i=2,cr_dimensions-1 do
				for p in all(collision_regions[i][j].fprojectile) do
				collide_in_region(p,i,j)
				collide_in_region(p,i+1,j)
				collide_in_region(p,i-1,j)
				collide_in_region(p,i,j+1)
			end
		end
	j=cr_dimensions
		for i=2,cr_dimensions-1 do
			for p in all(collision_regions[i][j].fprojectile) do
				collide_in_region(p,i,j)
				collide_in_region(p,i-1,j)
				collide_in_region(p,i+1,j)
				collide_in_region(p,i,j-1)
			end
		end
end

--[[
function draw_collisions()
	local h=(cr_border*2*cr_cell+128)/(cr_dimensions)
	
	for p in all(player_collisions) do
		circ(p.x,p.y,p.collider_r+1,0)	
		print(p.damage,p.x,p.y+5,0)		
		
	end
		circ(ship.x,ship.y,ship.collider_r,0)			
		circ(ship.x,ship.y,2,0)			
		
	for i=1,cr_dimensions do
		for j=1,cr_dimensions do
			for p in all(collision_regions[i][j].fprojectile) do
				circ(p.x,p.y,p.collider_r,0)			
			end
			for p in all(collision_regions[i][j].enemies) do
				circ(p.x,p.y,p.collider_r,9)			
			end
		rect(cam.x+(i-1)*h-64-cr_cell*cr_border,
							cam.y+(j-1)*h-64-cr_cell*cr_border,
							cam.x+(i)*h-64-cr_cell*cr_border,
							cam.y+(j)*h-64-cr_cell*cr_border,
							0)
		//print(#collision_regions[i][j].fprojectile,
		--					cam.x+(i-1)*h-64,
		--					cam.y+(j-1)*h-64,7)
		--print(#collision_regions[i][j].enemies,
		--					cam.x+(i-1)*h-64+10,
		--					cam.y+(j-1)*h-64,7)			
		if collision_regions[i][j].is_colliding 
		 then
			rect(cam.x+(i-1)*h-64-25-cr_cell*cr_border,
							cam.y+(j-1)*h-64-25-cr_cell*cr_border,
							cam.x+(i)*h-64+25-cr_cell*cr_border,
							cam.y+(j)*h-64+25-cr_cell*cr_border,
							10)
			print(i,cam.x+10,cam.y-10,15)
			end
		end
	end
end
]]
-->8

function get_available_enemy_volume(list)
	local enemy_volume_current=0
	for e in all(list) do
		enemy_volume_current+=e.volume
	end
	return enemy_volume_max-enemy_volume_current
end


function manage_enemy_spawning()
	if(tt%100==0) then
	
	cram_enemy({group=list_enemies,
		volume=60,
		c1=13,
		c2=8,
		c3=13,
		speed=1.9,
		hp=80,
		l=20,
		volume_added=10,
		snake_width=5},
		template_snake)
	cram_enemy({group=list_enemies,
			volume=7,
			c1=7,
			spr=4,
			c2=1,
			speed=1.3,
			volume_added=0.5,
			collider_r=8,
			draw=drw_enemy_rsprite,
			on_hit={fx_dissolve,oh_take_damage},
			update={bh_face_towards_ship,bh_shoot_at_player, bh_hitbox}},
		template_enemy)
	
	cram_enemy({group=list_enemies,
			volume_added=4,
			volume=3,
			scale=0.7,
			speed=1.9},
		template_enemy_fish)
		
	end
end

function get_enemy_spawn_location()


	local a={x=randb(-30,30),y=randb(-30,30)}
	if a.x>0 then a.x+=75 else a.x-=75 end
	if a.y>0 then a.y+=75 else a.y-=75 end
	a.x+=ship.x
	a.y+=ship.y
	a.angle=randb(-10,10)
	return a
end

function cram_enemy(args,template)
	if get_table_combination(args,template).volume<=
	get_available_enemy_volume(get_table_combination(args,template).group)
	then
		add_object(get_table_combination(get_enemy_spawn_location(),args),template)
	end
end
-->8
//enemies and snakes
//stars, particles and projectiles
function add_stars()
	for i=0,0 do
		local star={}
		star.x=randb(0,256)
		star.y=randb(0,256)
		star.d=randb(50,70)/100
		star.c=13
		star.move=randb(1,3)
		add(list_stars,star)
		end
	for i=0,30 do
		local star={}
		star.x=randb(0,256)
		star.y=randb(0,256)
		star.d=randb(5,20)/100
		star.c=1
		star.move=randb(1,3)
		add(list_stars,star)
		end
	
end



function draw_stars()
	for i in all(list_stars) do
		local x=i.x+cam.x*i.d
		local y=i.y+cam.y*i.d
		if x>cam.x+128 then i.x-=256 end
		if x<cam.x-128 then i.x+=256 end
		if y>cam.y+128 then i.y-=256 end
		if y<cam.y-128 then i.y+=256 end
		pset(flr(x*2)/2,flr(y),i.c)
		circfill(flr(x*2)/2,flr(y*2)/2,0.5/i.d,i.c)
	end
end

function draw_all(p)
	for a in all(p) do
		a.draw(a)
	end
end

function update_all(p)
	for a in all(p) do
		for upd in all(a.update) do
			upd(a)
		end
	end
end


function table_clone(org)
 local t={}
 	for key, value in pairs(org) do
  	t[key] = value
		end
	return t
end

function table_merge(a,b)
 for key, value in pairs(b) do
  a[key] = value
	end
end

function get_table_combination(extencion,base)
	local tbl=table_clone(base)
	table_merge(tbl,extencion)
	return tbl
end
//test this








function update_all_entities()
	for a in all(list_enemies) do
		update_entity(a)
	end
	for a in all(list_projectiles) do
		update_entity(a)
	end
	for a in all(list_particles) do
		update_entity(a)
	end
end

function update_entity(self)
	if bh_remove_if_far_away(self,despawn_distance) then
		for u in all(self.update) do
			u(self)
		end
		if self.invincible>0 then
			self.invincible-=1
		end
		if self.hp<=0 then
			for f in all(self.on_death) do
				f(self)
			end
		end
	end	
end

-->8



list_animations={}
list_draw_objects={}


function add_object(args,template)
	local new_obj=template
	local parents={template}
	
	while(new_obj.parent) do
		add(parents,new_obj.parent)
		new_obj=new_obj.parent
	end

	
	for i=#parents,1,-1 do 
		new_obj=get_table_combination(parents[i],new_obj)
	end

	new_obj=get_table_combination(args,new_obj)
	new_obj.seed=randb(-100,100)
	add(new_obj.group,new_obj)
	return new_obj
end

function clone_object(args,obj)
	local new_obj=table_clone(obj)
	table_merge(new_obj,args)
	del(obj.group,obj)
	add(new_obj.group,new_obj)
	return new_obj
end

function remove_object(obj)
	obj.invincible=1
	del(obj.group,obj)
end



function add_animation(new_anim)
	add(list_animations,cocreate(new_anim))
end

function update_animations()
	if #list_animations>0 then 
		for anim in all(list_animations) do 
			if costatus(anim) != 'dead' then
				coresume(anim)
			else 
				del(list_animations,anim)
			end
		end
	end
end

function clear_animations()
	list_animations={}
end
-->8
//behaviour

//have a hitbox
//can be invincible
//can die
function bh_remove_if_far_away(self,distance)
	local d=300
	if distance then
		d=distance
	end
	if(self.remove_if_far) then
		if abs(pifagor(self.x-ship.x,self.y-ship.y))>d
		then
			remove_object(self)
			return false
		end
	end
	return true
end


function bh_update_dead_snake(self)
	local death_period=3
	if(tt%death_period==0)then
		fx_explode_snake(self.segments[1],8)//red explosion
		if(rnd(10)>7)then od_drop_pellets(self.segments[1])end
		del(self.segments,self.segments[1])
	end
	if #self.segments==0 then
		remove_object(self)
	end
end

function bh_update_snake(self)
	if self.segments==nil then
		self.segments={}
		self.segments2={}
		ff=function(segment,other)
			oh_take_damage(self,other)
		end
		for i=0,self.l do
			local segment={}
			segment.seed=randb(-100,100)
			segment.on_hit={ff,oh_knockback_other}
			segment.x=self.x
			segment.angle=0
			segment.hp_pellets=1
			segment.laser_pellets=0
			segment.speed=1
			segment.damage=4
			segment.inv_damage=20
			segment.is_parriable=false
			segment.y=self.y+10+i*10
			segment.dx=0
			segment.invincible=0
			segment.dy=0
			segment.collider_r=min(self.l-i+1,self.snake_width)
			if i%2==0 then
				segment.c1=self.c1
			else
				segment.c1=self.c3
			end
			add(self.segments,segment)
			add(self.segments2,segment)
		end
		//tail color
		self.segments[#self.segments].c1=self.c2
		self.segments[#self.segments-1].c1=self.c2
		self.segments[#self.segments-2].c1=self.c2
		//head
		self.segments[1].on_hit={}
		//self.segments[2].collider_r=self.snake_width*0.8
	end

	local dist=pifagor(-self.x+ship.x,-self.y+ship.y)
	//self.speed=2.5-2*3^(-dist/30)
	if(dist>=100) then 
		
		self.speed=ship.maxspeed*2
		self.turning_d=0.01
	else
	self.speed=1.6
	self.turning_d=0.003
	end

	local period=4
	for i=2,#self.segments do 
		add_enemy_collider(self.segments[i])
		add_enemy_projectile_collider(self.segments[i])
	end
	if (tt%period==0) then
		self.segments2[1]={
			x=self.x,
			y=self.y}
		for i=2,#self.segments do
			self.segments2[i]={
				x=self.segments[i].x,
				y=self.segments[i].y
			}
		end
	else
		self.segments[1].x=self.x
		self.segments[1].y=self.y
		for i=2,#self.segments do
			self.segments[i].x=self.segments2[i].x+(tt%period)*(self.segments2[i-1].x-self.segments2[i].x)/period
			self.segments[i].y=self.segments2[i].y+(tt%period)*(self.segments2[i-1].y-self.segments2[i].y)/period
		end
	end
end

function bh_hitbox(self)
	if self.group==list_enemies then
		add_enemy_collider(self)
		add_enemy_projectile_collider(self)
	else
		if self.friendly==true then
			add_friend_projectile_collider(self)
		else
			add_enemy_projectile_collider(self)
		end
	end
end

function bh_tick_hp(self)
	self.hp-=1
end

function bh_slow_down(self)
	local rate=0.95
	if self.sd_rate then
		rate=self.sd_rate
	end
	self.dx*=self.sd_rate
	self.dy*=self.sd_rate
	if abs(self.dx)<0.05 then
		self.dx=0
	end
	if abs(self.dy)<0.05 then
		self.dy=0
	end
end

function bh_fish_towards_ship(a)
	a.a=atan2(-a.x+ship.x,-a.y+ship.y)+sin(a.seed/60+tt/150)/5
	local as=sin(a.a)
	local ac=cos(a.a)
	a.angle=atan2(ac,as)
	a.x+=ac*a.speed
	a.y+=as*a.speed
end

function bh_fly_towards_ship(a)
	a.a=atan2(-a.x+ship.x,-a.y+ship.y)
	local as=sin(a.a)
	local ac=cos(a.a)
	a.angle=atan2(ac,as)
	a.x+=ac*a.speed
	a.y+=as*a.speed
end

function bh_snake_towards_ship(self)


	td=self.turning_d

	local as=sin(self.angle)
	local ac=cos(self.angle)
	local ff=(-self.x+ship.x)*as-(-self.y+ship.y)*ac
	if(ff>0) then
			self.angle+=td
		else
			self.angle-=td
		end
	local angle=self.angle+sin(self.seed/100+tt/150)/10
	self.x+=cos(angle)*self.speed
	self.y+=sin(angle)*self.speed
end

function bh_face_towards_ship(self)
	local td=0.003
	if self.turning_d then
		td=self.turning_d
	end
	local as=sin(self.angle)
	local ac=cos(self.angle)
	local ff=(-self.x+ship.x)*as-(-self.y+ship.y)*ac
	if(ff>0) then
			self.angle+=0.003
		else
			self.angle-=0.003
		end
	local angle=self.angle+sin(self.seed/100+tt/150)/10
end

function bh_fly_straight(a)
	a.x+=a.dx+cos(a.angle)*a.speed
	a.y+=a.dy+sin(a.angle)*a.speed
end

function bh_update_pellet(self)
	add_enemy_projectile_collider(self)
	
	if not btn(❎) then
		local a=atan2(-self.x+ship.x,-self.y+ship.y)
		local dist=pifagor(-self.x+ship.x,-self.y+ship.y)
		local as=sin(a)
		local ac=cos(a)
		self.dx=ac*self.speed*30*3^(-dist/100)
		self.dy=as*self.speed*30*3^(-dist/100)
	end

	
end

function bh_shoot_at_player(a)
	offset=randb(0,100)/100
	ang=atan2(-a.x+ship.x,
		-a.y+ship.y)
	if tt%60==0 or (tt+5)%60==0 or (tt+10)%60==0 then
	for i=0,0 do
		sfx(39,3)
	add_object(
		{
		group=list_projectiles,
		friendly=false,
		hp=240,
		speed=0.1,
		x=a.x,
		y=a.y,
		radia=7,
		seed=i/3,
		speed=1,//+randb(-2,2)/20,
		c1=7,
		c2=outline,
		angle=ang,
		dx=0,
		dy=0,
		damage=2,
		on_death={fx_dissolve,remove_object}},
		template_bullet)
		end
	end	
end

function oh_take_damage(self,other)
	if self.invincible==0 then
		self.hp-=other.damage
		self.invincible+=other.inv_damage
	end
end

function oh_if_ship_then_die(self,other)
	if other==ship then
		del(self.group,self)
		fx_explode(self)
	end

end

function oh_knockback_other(self,other)
	local ang=atan2(-self.x+other.x,-self.y+other.y)
	other.dx=cos(ang)*2
	other.dy=sin(ang)*2
end
function oh_knockback_self(self,other)
	local ang=atan2(-self.x+other.x,-self.y+other.y)
	self.dx=-cos(ang)*3
	self.dy=-sin(ang)*3
end

function drw_dead_snake(self)
	circfill(self.segments[1].x,
		self.segments[1].y,
		self.segments[1].collider_r,
		self.segments[1].c1)
  	circfill(self.segments[1].x,
	  	self.segments[1].y,
	  	self.segments[1].collider_r/2,
			8)	//red insides
	for i=2,#self.segments do
	 	circfill(self.segments[i].x+randb(-2,2),
		 	self.segments[i].y+randb(-2,2),
		 	self.segments[i].collider_r,
			self.segments[i].c1)
	 end
end

function drw_snake(self)
	if self.segments then
		local border_color=outline
		if self.invincible>0 then
			border_color=self.c2
		end
		circfill(self.x,self.y,self.segments[1].collider_r+2,border_color)
		for i=2,#self.segments do
			circfill(self.segments[i].x,self.segments[i].y,self.segments[i].collider_r+2,border_color)
		end
		
		for i=2,#self.segments do
			circfill(self.segments[i].x,self.segments[i].y,self.segments[i].collider_r,self.segments[i].c1)
		end
		//for i=2,#self.segments do
		//	line(self.segments[i-1].x,self.segments[i-1].y,self.segments[i].x,self.segments[i].y,7)
		//end

	
		pal(1,self.c1)
		pal(12,self.c2)
		rspr(7,	self.x,self.y,self.angle,0,1)
		print(self.hp,self.x+20,self.y+20)
		pal()
	end
end

function drw_debug(self)
	//print(self.damage,self.x,self.y+10)
	circfill(self.x,self.y,
						self.collider_r+1,
						self.c2)
	circfill(self.x,self.y,
						self.collider_r-1,
						self.c1)
	//print(self.hp,self.x+10,
	//					self.y,0)
	if self.invincible and 
				self.invincible>0 then
				fillp(0b0011011011001001.1)
				
				circfill(self.x,self.y,
						self.collider_r-1,
						2)
				fillp()
		end
	end

function drw_circle(self)
	circfill(self.x,self.y,self.hp/15,self.c1)
	end

function drw_rsprite(self)
	rspr(self.spr,self.x,self.y,self.angle,self.c2,self.scale)
	//print(self.hp,self.x,self.y+20)
	end
function drw_enemy_rsprite(self)
	circfill(self.x,self.y,self.collider_r+1,outline)
	drw_rsprite(self)
	//print(self.hp,self.x,self.y+20)
	end

function drw_spr(self)
	for pp in all(self.pals) do 
		pal(pp[1],pp[2])
	end
	spr(self.spr,self.x-3,self.y-3)
	pal()
	//circ(self.x,self.y,self.collider_r,7)
	//pset(self.x,self.y,0)
	end

function drw_text(self)
	print(self.text,self.x,self.y,self.c1)
end

function drw_square(self)
	//circfill(self.x,self.y,self.hp/15,self.c1)
	rectfill(self.x+self.hp/30,
		self.y+self.hp/30,
		self.x-self.hp/30,
		self.y-self.hp/30,
		self.c1)
	end

function fx_explode_snake(a,c)
	shake_explode(0.07)
	if(cr_is_on_screen(a))then
		for i=0,4 do
		add_object(
			{group=list_particles,
			x=a.x,
			y=a.y,
			dx=randb(-20,21)/10,
			dy=randb(-20,21)/10,
			hp=40,
			draw=drw_circle,
			c1=c},
			template_basic_particle)
		end
	end
end
fades={
	{1,1,1,1,0,0,0,0},
	{2,2,2,1,1,0,0,0},
	{3,3,4,5,2,1,1,0},
	{4,4,2,2,1,1,1,0},
	{5,5,2,2,1,1,1,0},
	{6,6,13,5,2,1,1,0},
	{7,7,6,13,5,2,1,0},
	{8,8,9,4,5,2,1,0},
	{9,9,4,5,2,1,1,0},
	{10,15,9,4,5,2,1,0},
	{11,11,3,4,5,2,1,0},
	{12,12,13,5,5,2,1,0},
	{13,13,5,5,2,1,1,0},
	{14,9,9,4,5,2,1,0},
	{15,14,9,4,5,2,1,0}}
fadout_amount=0
fadeout_args={fn=8,pn=15}
fadeout_args.fc=1/fadeout_args.fn
function fadeout(frames)
	local fi=flr(fadout_amount/fadeout_args.fc)+1
	for i=0,frames do
		fi=flr(fadout_amount/fadeout_args.fc)+1
		for n=1,fadeout_args.pn do
			pal(n,fades[n][fi],1)
		end
		fadout_amount+=1/frames
		  yield();
	end
end
function fpal(c1,c2,arg)
	pal(c1,fades[c2][flr(fadout_amount/fadeout_args.fc)+1],arg)
end
	
function fx_explode(a)
	shake_explode(0.1)
	if(cr_is_on_screen(a))then
		for i=0,3 do
			add_object({group=list_particles,
				x=a.x,
			y=a.y,
			dx=a.dx+randb(-4,5)/2,
			dy=a.dy+randb(-4,5)/2,
			hp=60,
			sd_rate=0.8,
			collider_r=10,
			draw=drw_circle,
			c1=2},
			template_basic_particle)
		end
		for i=0,4 do
			add_object({group=list_particles,
			x=a.x,
			y=a.y,
			dx=a.dx+randb(-4,5)/6,
			dy=a.dy+randb(-4,5)/6,
			hp=40,
			sd_rate=0.95,
			draw=drw_circle,
			c1=randb(8,12)},
			template_basic_particle)
		end
		add_object({group=list_particles,
		x=a.x,
		y=a.y,
		dx=a.dx,
		dy=a.dy,
		hp=5,
		collider_r=6,
		draw=drw_debug,
		c1=7,
		c2=7},
		template_basic_particle)
	end
end

function fx_dissolve(a)
	if(cr_is_on_screen(a))then
		for i=0,5 do
		add_object({group=list_particles,
			x=a.x,
			y=a.y,
			dx=a.dx+randb(-4,5)/20,
			dy=a.dy+randb(-4,5)/20,
			hp=40,
			c1=a.c1},
			template_basic_particle)
		end
	end
end

function fx_ff(self)
	freeze_frame+=10
end

function op_deflect1(self,other)
	local ac=cos(self.angle)
	local as=sin(self.angle)
	local len=pifagor(other.x-self.x,other.y-self.y)
	local ff=(other.x-self.x)/len*ac+(other.y-self.y)/len*as
	if (ff>0)then
		self.c1=9
		self.angle=0.5+self.angle
	else 
		self.c1=14
	end 
	self.friendly=true
	self.hp+=80
	self.c1=7
	self.damage+=20
	add_object({group=list_particles,x=self.x,y=self.y,text=ff},template_text)
end

function op_deflect_bullet(self,other)
	self.angle=0.5+self.angle
	self.friendly=true
	self.hp+=80
	self.damage+=10
	self.c1=7
	self.invincible=10
end

function od_die_snake(self)
	self.update={bh_update_dead_snake}
	self.draw=drw_dead_snake
	self.on_death={}
end

function od_raise_enemy_volume(self)
	enemy_volume_max+=self.volume_added
end

function od_drop_pellets(self)
	for i=1,self.hp_pellets do
		add_object({group=list_particles,
			x=self.x,
			y=self.y,
			dx=self.dx+randb(-4,5)/4,
			dy=self.dy+randb(-4,5)/4},
			template_pellet_hp)
		end

		for i=1,self.laser_pellets do
			add_object({group=list_particles,
				x=self.x,
				y=self.y,
				dx=self.dx+randb(-4,5)/4,
				dy=self.dy+randb(-4,5)/4},
				template_pellet_laser)
			end
end

function od_raise_laser_charge(self)
	ship.laser_charge+=self.laser_charge
end

template_empty={
	x=0,
	y=0,
	dx=0,
	dy=0,
	speed=0,
	angle=0,
	scale=1,
	volume=0,
	collider_r=10,
	invincible=0,
	turning_d=0,
	sd_rate=0.95,
	spr=0,
	group={},
	sp=0,
	c1=0,
	c2=0,
	c3=0,
	hp=20,
	volume_added=0,
	laser_pellets=0,
	hp_pellets=0,
	damage=0,
	inv_damage=10,
	is_parriable=false,
	friendly=false,
	
    draw=drw_debug,
    on_hit={},
	on_pickup={},
	on_death={},
	on_parry={}
}




template_basic_particle={
	parent=template_empty,
	c1=7,
	sd_rate=0.95,
	update={bh_fly_straight,bh_tick_hp,bh_slow_down},
    draw=drw_circle,
	on_death={remove_object}
}

template_pellet={
	parent=template_basic_particle,
	damage=0,
	inv_damage=0,
	sd_rate=0.98,
	hp=500,
	speed=0.1,
	collider_r=10,
	spr=12,
	draw=drw_spr,
	on_hit={remove_object},
	is_pickup=true,
	friendly=false,
	update={bh_fly_straight,bh_tick_hp,bh_slow_down,bh_update_pellet},
}

template_pellet_hp={
	parent=template_pellet,
	pals={{2,outline}},
	spr=13,
	damage=-3,
	c1=9,
	c2=7,
	on_hit={function ()sfx(35,3)end,remove_object}
}

template_pellet_laser={
	parent=template_pellet,
	pals={{9,12},{2,outline}},
	spr=13,
	c1=12,
	c2=7,
	damage=0,
	on_hit={function ()sfx(35,3)end,remove_object,function(self)  ship.laser_charge+=3 end}
}




template_text={
	parent=template_empty,
	c1=7,
	hp=50,
	text="no text",
	update={bh_tick_hp},
    draw=drw_text,
	on_death={remove_object}
}

template_enemy={
	parent=template_empty,
	hp_pellets=1,
	laser_pellets=1,
	remove_if_far=true,
	speed=0.1,
	scale=1,
	volume=2,
	collider_r=5,
	group=list_enemies,
	sp=2,
	c1=4,
	c2=background,
	hp=10,
	damage=2,
	is_parriable=true,
    draw=drw_debug,
	update={bh_hitbox},
	on_hit={oh_take_damage},
	on_death={function() sfx(40,3) end;remove_object,od_raise_enemy_volume,od_drop_pellets},
	on_parry={}
	}


template_snake={
	parent=template_empty,
	speed=1,
	volume=2,
	collider_r=5,
	turning_d=0.001,
	sp=2,
	c1=10,
	c2=8,
	c3=0,
	snake_width=9,
	sd_rate=0.95,
	hp=80,
	l=3,
	damage=8,
	inv_damage=20,
	laser_pellets=5,
	is_parriable=true,
	update={bh_snake_towards_ship,bh_slow_down,bh_hitbox,bh_update_snake},
    draw=drw_snake,
    on_hit={oh_take_damage},
	on_death={fx_explode,od_die_snake,od_raise_enemy_volume,od_drop_pellets},
	on_parry={function(self) self.invincible=20 sfx(40,3)end,oh_knockback_self,fx_ff,fx_ff}
	}


template_enemy_fish=
	{
		parent=template_enemy,
		hp_pellets=2,
		laser_pellets=2,
		hp=5,
		c1=0,
		c2=1,
		spr=3,
		speed=1.8,
		collider_r=3,
		turning_d=0.5,
		scale=0.5,
		damage=3,
		volume=1,
		volume_added=0.5,
		update={bh_fish_towards_ship,bh_hitbox},
		on_hit={oh_take_damage,fx_dissolve,oh_if_ship_then_die,function() sfx(41,3)end},
		on_death={function() sfx(40,3)end,fx_explode,remove_object,od_raise_enemy_volume,od_drop_pellets},
		draw=drw_enemy_rsprite,
		on_parry={oh_knockback_self}
	}

	template_bullet={
		parent=template_empty,
		group=list_projectiles,
		collider_r=3,
		damage=2,
		hp=80,
		c1=12,
		c2=background,
		speed=4,
		
		is_parriable=true,
		draw=drw_debug,
		update={bh_fly_straight,bh_hitbox,bh_tick_hp},
		on_hit={remove_object},
		on_death={fx_explode,remove_object},
		on_parry={op_deflect_bullet,function ()sfx(34,3)end,fx_ff,fx_ff}
		}		

template_bullet_ship={
	parent=template_bullet,
	collider_r=3,
	damage=4,
	hp=80,
	c1=12,
	c2=outline,
	speed=3,
	is_parriable=false,
	friendly=true,
	draw=drw_debug,
	update={bh_fly_straight,bh_hitbox,bh_tick_hp},
    on_hit={remove_object},
	on_death={fx_dissolve,remove_object},
	on_parry={}
	}
	

	
ship_d_o={
	parent=template_empty,
	c1=4,					
	draw=function(self)
		spr(16+32*flr(1.5+(1.4*sin(tt/250))),self.x-10,self.y-8,6,2)
	end
		}




-->8
//rspr, screenshake
//collide, square, pifagor
//randb

function rspr(sp,x,y,a,t,scale)
	ca=cos(-a+0.25) sa=sin(-a+0.25)
	local sp_x=sp%16*8
	local sp_y=flr(sp/16)*8
	local pix=0
	local kx=0 ky=0
	for ix=-3,4 do
		for iy=-3,4 do
			pix=sget(sp_x+3+ix,sp_y+3+iy)
			if(pix~=t)then
				kx=x+ix ky=y+iy
		 	pset(x+(ix*ca+iy*sa)*scale,
		 		y+(iy*ca-ix*sa)*scale,
		 		pix)
		 	pset(x+0.5+(ix*ca+iy*sa)*scale,
		 		y+0.5+(iy*ca-ix*sa)*scale,
		 		pix)
			pset(x-0.5+(ix*ca+iy*sa)*scale,
		 		y-0.5+(iy*ca-ix*sa)*scale,
		 		pix)
			end
		end
	end
end

offset_g=0
offset_e=0
offset=0

function shake_gun(a)
	offset_g=a
end

function shake_explode(a)
	offset_e=a
end

function screen_shake()
	offset=offset_g+offset_e
	local fade=0.95
	local offset_x=16-rnd(32)
	local offset_y=16-rnd(32)
	
	offset_x*=offset
	offset_y*=offset

	cam.x=flr(cam2.x+offset_x)
	cam.y=flr(cam2.y+offset_y)
	
	offset_e*=fade
	offset_g*=fade
	if offset_g<0.0 then
		offset_g=0
		end
	if offset_e<0.0 then
		offset_e=0
		end
end

function collide_p(b1,b2)
	return abs(abs(square(b1.x-b2.x))+
				abs(square(b1.y-b2.y)))
				<abs(square(b1.collider_r))
end

function collide(b1,b2)
	return abs(abs(square(b1.x-b2.x))+
				abs(square(b1.y-b2.y)))
				<abs(square(b1.collider_r+b2.collider_r))
end

function square(a)
return a*a
end

function pifagor(x,y)
	return sqrt(x*x+y*y)
end

function randb(l,h) --exclusive
    return flr(rnd(h-l))+l
end//rspr, screenshake
//collide, square, pifagor
//randb

function decay_line(x1,y1,x2,y2,l,d1,d2,c,part)
	hx=(x2-x1)/l
	hy=(y2-y1)/l
	hd=(d2-d1)/l
	for i=0,l do
		circfill(x1+hx*i+randb(-3,2),y1+hy*i+randb(-3,2),d1+hd*i,c)
	end
end



__gfx__
00000000111aa11111177111111dd11111888811000000000000000000c00c000007700000000000006c000000076c0000000000002220000000000000000000
00000000111aa11111177111111dd1111188881100000000000000000111111007777770000000000c000000000000c000a0a000022222000000000000000000
00700700111aa1111117711111dddd11118dd811000cc000000aa00011c11c110777777000070000c00000000000000c00a0a000222722200000000000000000
0007700011aaaa11117aa71111dddd1111dddd11000cc000000aa0001cc11cc17777777700777000600000077000000c00a0a000227992200000000000000000
0007700011aaaa11117aa711111dd111111dd11100cccc0000adda001c1111c17777777777777770700000067000000600000000222922200000000000000000
0070070011aaaa1111aaaa11111dd111111dd1110cccccc00adddda01111111107777770000000000000000cc00000000a000a00022222000000000000000000
000000001aaaaaa11aaaaaa111dddd1111dddd110000000000000000111111110777777000000000000000c0060000000aaaaa00002220000000000000000000
000000001aaaaaa11aaaaaa111d11d1111d11d110000000000000000011111100007700000000000000cc60000cc000000000000000000000000000000000000
00000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaa0aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaaa0007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaaa0077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaa0000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000aaaaaeaeaa0000aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaaaaaeeeaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaaaaeaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000aaaaaaaaaaaa000000000000aaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaa0000000000000000000000aaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaaa0077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaa00000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaeaeaa000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaaaaeeeaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000aaaaaaaaaaaaeaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000aaaa000000aaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000aaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000aaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaaa0007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaeaeaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000aaaaaeeeaaaaa000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaaaaeaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000aaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000aaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000aaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000aaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000777700000000000000077770000000000000000000000000000000000000000000000
00777777770000000000000000000000000000000000000000000000000777700000007770000077770077700000000000000000000000000000000000000000
07777777770000000000000000000000000000000000000000000000000077700000007770000007770077700000000000000000000000000000000000000000
77770000770000000000000000000000000000000000000000000000000077700000000000000007770000000000000000000000000000000000000000000000
77700000770000000000000000000000000000000000000000000000000077700000000000000007770000000000000000000000000000000000000000000000
77000000000077777700777777777777777777770077777707777777770077777770077770077777770777700777777707777777770000000000000000000000
77000000000777777770777770777777777777770777777777777777777007777777077770777777770777700000777707777777770000000000000000000000
77000000000777007770777000077700777007770777007770777000777007700777007770777000770077700000077700777007770000000000000000000000
77700000000770007770777770007700077000770770007770777000777007700077000770770000770007700777777700077000770000000000000000000000
77700000000770007770777777007700077000770770007770777000777007700077000770770000770007700777777700077000770000000000000000000000
77770000077777007770000777007700077000770777007770077000777077700077000770777000770007700770077700077000770000000000000000000000
07777777770777777777777777777770777707777777777770077777777777700777777777777777777777770777777707777707777000000000000000000000
00777777700077777707777770777777777777777077777700077777770777770770077777077777777077777777777777777707777000000000000000000000
00000000000000000000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000777000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000007777700000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000007777770000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000cccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000ccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c0000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cc000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000cc00000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000cc0000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000cc000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000cc00000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000c00000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006660000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006060000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006600000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006060000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000ccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006660000000000cccc000000000000000008888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000
0006060000000000ccc0000000000000000088888888888888888888880000000000000000000000000000000000000000000000000000000000000000000000
0006660000000000cc00000000000000000888888888888888888888888000000000000000000000000000000000000000000000000000000000000000000000
0006060000000000c000000000000000008888888888888888888888888800000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000088888888888888888888888888880000000000000000000000000000000000000000000000000000000000000000000
00060600000000000000000000000000888888888888888888888888888888000000000000000000000000000000000000000000000000000000000000000000
00066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000cc800000000000000000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000cc8006060666000000000000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000cc80006060606000000000000008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000cc800006660666000000000000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cc8000006060600000000000000000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c80000000000000000000000000000008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
77722222222222222222222222222222222222222222222222222222222222222222277777227222222227722777222222222222222222222222222222222222
72722222222222222222222222222222222222222222222222222222222222222222722222727222222222722777222222222222222222222222222222222222
727222222222222222222222222222222222222222222222222222222222222222272222222777222222277227772222222222222222222222222222222ccccc
72722222222222222222222222222222222222222222222222222222222222222272222222227772222277772777222222222222222222222222222222c22227
7772222222222222222222222222222222222222222222222222222222222222227222222222727777777777277722222222222222222222222222222c222277
222222222222222222222222222222222222222222222222222222222222222222722222222777277777222272222222222222222222222222222222c2222277
222222222222222222222222222222222222222222222222222222222222222222722222222277272722222227222222222222222222222222222222c2222278
222222222222222222222222222222222222222222222222222222222222222222722222222777277722222222722222222222222222222222222222c2222277
222222222222222222222222222222222222222222222222222222222222222222272222222722277722222222777777222222222222222222222222c222a887
222222222222222222222222222222222222222222222222222222222222222222777772227777277722222227722777722222222222222222222222c22aaa77
7272777222222222222222222222222222222222222222222222222222222222272227777722222272227777777227272722222222222222222222222caa7777
72727272222222222222222222222222222222222222222222222222222222227222222272227777722722227772272722722222222222222222222222c77777
77727272222222222222222222222222222222222222222222222222222222272222222227272222277222227772272722722222222222222222222887777777
22727272222222222222222222222222222222222222222222222222222222272222222227722222277222227777277727722777222222222222227777777777
22727772222222222222222222222222222222222222222222222222222222272222222277727772272777777227222222722727222222222222877777777777
22222222222222222222222222222222222222222222222222222222222222272222222227727272272722227277227772722727222222222228877777777777
22222222222222222222222222222222222222222222222222222222222222272222222277727272277722777727227277722727222222222227777777777772
22222222222222222222222222222222222222222222222222222222222222227222222277227272272722727277227277772777222222222277777777772222
22222222222222222222222222222222222222222222222222222222222222222722222777727772227722727277777772222222222222228877777777772222
22222222222222222222222222222222222222222222222222222222222222222277777222722222227722727777727772222222222222288877777777772222
7222777222222222222222222222222222222222222222222222227777722222222222222227222227777777722222222222222222222777777777a777772222
72227272222222222222222222222221112222222222222222222722222722222222222222227777722222222222222222222222222277777777778877722222
77727272222222222222222222222211111222222222222222227222222272222222222222222222222222222222222222222222222277777777778222222222
72727272222222222222222222222211111222222222222222277777222227222222222222222222222222222222222222222222222a7777777777822922a222
77727772222222222222222222222111111222222222222222772222722227222222222222222222222222222222222222222222777777777777788222222222
222222222222222222222222222222211122222222222222272722222722777277722222222222222222222222222222222222277777777777777889222222a2
2222222222222222222222222222222222222222222222227227222222722772727222222222222222222222222222222222222777777777777778a992222222
222222222222222222222222222222222222222222222222722722222272777272722222222222222222222222222222222227777777777777778aaa77222222
222222222222222222222222222222222222222222222222722272222777777772722222222222222222222222229222cccc777777777777722287a272222222
22222222222222222222222222222222222222222222222272222722227777777772222222222222222222222222222c228a7777777777722222272222222222
2222222222222222222222222222222222222222222222227222227777772727222222222222222222222222222222ca28aa777777877722222222222b222222
222222222222222222222222222222222222222222222222272222222722272722222222222222222222222222222c2228877777778822222222222228222292
222222222222222222222222222222222222222222222222277777227777277722222222222222222222222222222c2288777777778822222222222222222222
222222222222222222222222222222222222222222222222722777772222222222222222222222222222222222222c277777777777acc2222222222222222282
222222222222222222222222222222222222222222222227222222272222222222222222222222222222222222222c77777777777ac222222222222222222222
222222222222222222222222222222222222222222222272222222227222222222222222222222222222222228882c777777777772ccc2222222222222222222
222222222222222222222222222222222222222222222272222222227222222222222222222222222222222288888277777777772222c2222222222222227222
222222222222222222222222222222222222222222222272222222277727772222222222222222222222222888888a77777777ccc2ccc2222222222222222222
2222222222222222222222222222222222222222222222722222222277272722222222222222222222222228888aa7777777772a822222222222222222222222
222222222222222222222222222222222222222222222272222222277727272222222222222222222222222888a7777777777aa8882222222222222222222222
22222222222222222222222222222222222222222222222722222227222727222222222222272222222222288a7777777778a72a822222222222222222222222
222222222222222222222222222222222222222222222222722222777727772222222b222277722222277788a777777777788722222222222222222222222222
22222222222222222222222222222222222222222222222227777722777772222222bbb222272222227777777777777777788722222222222222222222222222
222222222222222222222222222222222222222222222222222222272222272222222b2222999a22887777777777777777888222222222222222222222222222
2222222222222222222222222222222222222222222222222222227222222272222222222229aaa8887777777777777a88882222222222222222222222222222
2222222222222222222222222222222222222222222222222222272222222227222222222222ba88877777777777777822222222222222222222222222222222
222222222222222222222222222222222222222222222222222227222222222722222ccccc7222aa777777777787778222222222222222222222222222222222
222222222222222222222222222222222222222222222222222227222222227772777baaa7c72aaa77777777a888882222222222222222222222222222222222
2222222222222222222222222222222222222222222222222222272222222227727c7b2aaa7c8aa777777777a882222222222222222222222222222222222222
2222222222222222222222222222222222222222222222222222272222222277727278822ac8877777777777a822222222222222222222222222222222222222
2222222222222222222222222222222222222222222222222222227222222272227278222caa77777777777a8222222222222222222222222222222222222222
222222222222222222222222222222222222222222222222222222272222277772777222aaaa7777777777222222222222222222222222222222222222222222
222222222222222222222222222222222222222222222222222222227777722222c2222aaaaa7777777772222222222222222222222222222222222222222222
222222222222222222222222222222222222222222222222222222222222222222c2222777a77777788822222222222222222222222222222222222222222222
2222222222222222222222222222222222222222222222222222222222222222222c227777777777a888ccc22222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222c77777777777a888c2c22222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222a777777777778882c2c22222222222222222222222222222222222222222
222222222222222222222222222222222222222222222222222222222222222222227777777777778822c2c22222222222222222222222222222222222222222
2222222222222222222222222222222222222222222222222222222222222222227777777777777cccc2ccc22222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222aaa77777777777a8c2222222222222222222222222222222222222222222222222
2222222222222222222222222222222222222222222222222222222222228aaaa777777777778822222222222222222222222222222222222222222222222222
2222222222222222222222222222222222222222222222222222222222288a777777777777788222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222228887777777777777882222222222222222222222222222222222222222222222222222
222222222222222222222222222222222222222222222222222222222288877777777a7778822222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222228aa7777777788822222222222222222222222222222222222222222222222222222222
2222222222222222222222222222222222222222222222222222222222aa77777777788222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222288777777777777722222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222228887777777777777722222222222222222222222222222222222222222222222222222222222
222222222222222222222222222222222222222222222222222288a777777777a777122222222222222222222222222222222222222222222222222222222222
222222222222222222222222222222222222222222222222222888a77777777aaaa1112222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222288877777778aaa811111222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222288777777788888881111122222222222222222222222222222222222222222222222222222222
2222222222222222222222222222222222222222222222222222877777a888888111111122222222222222222222222222222222222222122222222222222222
22222222222222222222222222222222222222222222222222228777778888881111111112222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222221177788888111111111112222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222221111118111111111111112222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222221111811811111111111112222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222221111811111811111111112222222222222222222222222222222222222222222222222222222
222222222222222222222222222222222222222222222222a2a21181811111111111111112222222222222222222222222222222222222222222222222222222
2222222222222222222222222222222222222222222222200aaa1111111111111111111112222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222200a22111111111111111111122222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222220022111111111111111111122222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222211111111111111111222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222221111111111111112222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222111111111111122222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222211111111111222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222111111122222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222212222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222221112222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222211111222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222211111222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222211111222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222221222222222222222221112222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222211122222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222221222222222222222222211111222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222111111122222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222221111111112222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222211111111111222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222211111111111222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222211111111111222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222211111111111222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222211111111111222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222221111111112222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222111111122222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222211111222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222

__map__
0000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100001817010170170600006000060000500003000020000100070001700017000370003700037000370003700037000270002700027000270002700027000270002700027000270002700027000270003700
010400000c67013660056300262000615062050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010204082466013650056300262000215062050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b0000245501854018532185201852018515005000050003500035000f5000f50003500035000350003500085000850008500085002050020500085000850006500065001e5001250005500055000550005500
01040208000700c0700c0700c0600c0600c0700c0700c070004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
011400080c0000c0000c0000c0000c0000c0000c0000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00000c00000000000000000000600000000c000000000c000000000000000600006000000000000000000c00000000000000000000600000000c000000000c000000000c0000060000600000000060000600
010a0020118000500011800058001d9001d9001d9001da00058001da0011800000001d9001d9001d9001da001180000000118001da001d9001d9001db001da00009001da0011800000001d9001d9001d9001d900
010a00201d9301d9301da20240001da10058001d9301d9301da2007c001da10000001d9301d9301da201da001d9301d9301da20240001da10058001d9301d9301da2007c001da10000001d9301d9301da201da00
010a00201d9301d9301da20240001da10058001d9301d9301da2007c001da10000001d9301d9301da201da001d9301d9301da20240001da10058001d9301d9301da2007c001da10000001d9201da301d9301da30
010a0020118500500011850058001d9501d9501d9501da20058001da2011850000001d9501d9501d9001da201185000000118501da001d9501d9201db001da20009001da2011850000001d9501d9501d9001d900
010a002011850050001da20058001d9501d9501d9501da201d9001da201d9501d9501d9501da201d9001da201d9501d9501da201da501d9501d9501d9501da201d9001da201d9501d9501d9001da201d9001da30
0114000011b7011b7011b7011b7005b0005b0005b0005b0005b000000011b7011b700ab700ab700ab700ab700db700db700db700db700db700db7011b7011b7013b7013b7013b7013b7013b7000b000000000b00
0114000014b5014b5014b5014b5005b0005b0005b0005b0005b000000011b5011b5014b5014b5014b5014b5019b5019b5019b5019b5019b5019b5011b5011b5013b5013b5013b5013b5013b5000b000000000b00
0114000014b5014b5014b5014b5005b0005b0005b0005b0005b000000011b5011b5014b5014b5014b5014b5019b5019b5019b5019b5019b5019b5018b5018b5013b5013b5013b5013b5013b5000b000000000b00
0114000011c6511c6511c6511c6511c6511c6011c6011c600dc600dc6003c600dc600dc600dc600dc600dc6008c6008c6008c6008c6008c6008c6008c6008c6003c6003c6003c6003c601bc601bc651bc601bc65
0114000011c6011c6011c6011c6011c6011c6011c6011c600dc600dc6003c600dc600dc600dc600dc600dc6008c6008c6008c6008c6008c6008c6008c6008c600ac600ac600ac600ac600ac600ac600ac600ac60
0114000011c6411c6011c6011c6011c5011c5011c4011c400dc600dc600fc600dc600dc500dc500dc400dc4008c6008c6008c6008c6008c6008c6008c6008c600ac600ac600ac6008c6008c6008c600cc600cc61
0128000019c6519c6519c6519c6519c5519c550dc450dc4514c6514c6520c6514c6514c5514c5514c4514c4518c6518c6518c6518c6518c6518c6518c6518c6511c6511c6511c6511c6511c6511c6511c6511c65
0128000013c6513c6513c6513c6513c5513c5513c4513c451ac651ac651ac651ac651ac551ac551ac451ac4522c6522c6522c6522c6522c6522c6522c6522c6524c6524c6524c6524c6524c6524c6524c6518c65
0114002111045140551b0651f0621f0450c005275001b500190451d0551806527041270450cb0518b4018b4514045180551f06522051220450c00524500185000f0551d05522055180510f0551f0552405529051
0114000011150111401112011115111001110011100051000510000100111501112011140111200a1300a1200a1100a11001210012100d2200d21011140111301315013140131201311013105001000010000100
01140000141501412014110141150510005100051000010000100001001115011130131501313018130181201614016125141001410014150141300121001210131501314013210132100f1400f1200f13011200
0114000011c7511c6511c3511c7511c6511c3511c7011c650dc750dc650fc350dc750dc650dc350dc700dc6514c7514c6514c3514c7514c6514c3514c7014c650fc750fc650fc350fc750fc650fc350fc700fc65
011400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003010009620086210662105621046210362103621036210262102611026110261101611016110161101611016110161101601016011260112601126011260115601126011160111601116011c6011c60100601
010100000945600456084560045607456004560645600456054560a4560545600456054560045606456004560a4460a446064460a4460b4460a43605436084360a42608426074260642606426064160141605416
000100000e70026710267102672027730277302973028730357000270002700017000370032700317002f7002b70027700237001e7002e7001f7001b7401873012730147200f7100c71011710097100f71006700
00010000071701115005140021500b1000b1000610001100330000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
0002000009160071600a1600e150101501315017140191401c1402113023130287302c7202c72030710337103671037100391003b1003f1000010000100001000010000100001000010000100001000010000100
0109000011130141301812018110181150c5000c00000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
01100000237501d7401d7301d7201d710007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
010800001113014130181201811018110181101811524100001000010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101
0114000024131241202411020150201411b1501b15018150181501115111151001010010100101001010010124101241002410020100201011b10018100181000010100101001010010100101001010010100101
01020000130301d020110100e0100b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800000a66007650056400462003620326000060028600326003560029600226002460000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000400000a73007720057100471003710327000070028700327003570029700227002470000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
__music__
00 084f4c44
00 08104d44
00 08114c44
00 08124e44
00 08134444
01 080f0c44
00 090f0d44
00 080f0c44
00 090f0e44
00 1714564a
00 1714164a
00 1714154a
00 1714164a
00 17140a15
00 17144a16
00 17140a15
02 17140b16

