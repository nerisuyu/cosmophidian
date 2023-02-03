pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
      --[[
todo

main menu

laser charging 

parry charge

unlockable laser and parry

ship on_hit's --done

oh: freeze frame
    take damage
    become invincible
    screen_shake

invinc frames cap
	based on the hitter?
	the stronger the hit the longer
	the invis?

fix snakes, segments

new parry


smoke and explosions

highscore 


particle templates
render particles only on screen

enemy manager
animations handler: 
		parry wave
		parry speed boost
		explosions
	
	camera
]]--
ship={}

null=function() end



background=13

freeze_frame=0

function _init()
	start_menu()
	
	end

function start_menu()
	game_starting=false
	particles={}
	play_btn_color=7
	shp=add_draw_object({x=48,y=32,dx=0,dy=0},ship_d_o)
	poke(0x5f2d, 1)
	music(1)
	camera()
	cls(0)
	tt=0
	_update60=menu_update
	_draw=menu_draw
end

function menu_draw()
	cls(2)

	draw_particles()
	pal(7,play_btn_color)
	spr(112,10,54,-2+tt/2,3)
	print("press ❎ to play",30,90,play_btn_color)
	line(-6+8*tt/2,55,-6+8*tt/2,70,play_btn_color)

	draw_draw_objects()
end

function menu_update()
	tt+=1
	tt=tt%10000
	update_animations()
	upd_particles()
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
	if btnp(❎) and not game_starting then
		game_starting=true
		add_animation(function ()
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
			explode(shp)
			clear_draw_objects()
			start_game()
		end)
	end
end



function _update60()
	end

function start_game()
	music(5)
	ship={x=64,y=64,dx=0,dy=0,
						ax=0,ay=0,
						hp=20,
						collider_r=25,
						damage=1,
						angle=0.25,
						c1=12,
						invincible=0,
						speed=0,
						on_hit={explode,oh_take_damage},
						
						nosex=0,
						nosey=0,
						acc=0.07,
						lacc=0.008,
						dcc=0.005,
						turningd=0.1,
						maxspeed=1.5,
						scale=1,
						states={}
						}
	ship.states={
		turning=0,
 		flying=false,
		shooting=false,
		laser=false,
		parry=0,
		parry_cd=0
	}
	tt=-1
	base_turning=0.03
	fly_turning=0.005
	laser_turning=0.003
	cam={x=0,y=0}
	laser={length=120,segments=9}
	stars={}
	enemies={}
	particles={}
	projectiles={}
	snakes={}
	dead_snakes={}
	for i=0,0 do
		for j=0,0 do
		add_enemy({x=i*100,
			y=j*100,
			dx=0,
			dy=0,
			collider_r=10,
			angle=0,
			speed=0*randb(1,2)},
			template_enemy)
		end
	end
	add_snake(ship.x,
		ship.y+300,8,15,20,100)
	add_stars()

	_update60=game_update
	_draw=game_draw
end

	
function game_update()
	if freeze_frame >0 then
		freeze_frame=min(freeze_frame,50)
		
		shake_explode(0.01+0.2/freeze_frame)
			
		freeze_frame-=1
		else
	
	//ship.hp+=0.02
	ship.hp=min(20,ship.hp)
	if ship.invincible>0 then
		ship.invincible-=1
	end	
	if #snakes==0 and tt%10then
		add_snake(ship.x,ship.y+300,11,11,20,1)
		add_snake(ship.x,ship.y+300,11,11,20,1)
		add_snake(ship.x,ship.y+300,11,11,20,1)
		add_snake(ship.x,ship.y+300,11,11,20,1)
		add_snake(ship.x,ship.y+300,11,11,20,1)
		add_snake(ship.x,ship.y+300,11,11,20,1)
		add_snake(ship.x,ship.y+300,11,11,20,1)
		//add_snake(50,100,7,8,20,25)
	end

	tt+=1
	tt=tt%10000
	update_animations()
	handle_input()
	upd_ship()
	update_all_entities()
	update_snakes()
	update_dead_snakes()
	upd_particles()
	manage_collisions()
	manage_player_collisions()
	clear_collision()
	
	end
	
	if ship.hp<=0 then
	start_menu()
	end
end

function _draw()
end
function game_draw()
	cls(background)
	
	screen_shake()
	camera(cam.x-64,cam.y-64)
	draw_stars()
	draw_dead_snakes()
	draw_snakes()
	draw_particles()
	if freeze_frame >0 and ship.states.parry>0 then
		fillp(0b1011111111111111.1)
		circfill(ship.x,ship.y,5+150/freeze_frame,12)
		fillp()
	end
	draw_all(projectiles)
	draw_all(enemies)
	
	draw_ship()
	//draw_collisions()
 //clear_collision()
	
	--[[
	print(#projectiles,cam.x-64,cam.y-10,7)
	print(#enemies,cam.x-64,cam.y-54,7)
	
	print(stat(7),cam.x-64,cam.y-64,7)
	print(ship.hp,ship.x,ship.y+10,15)
	print(ship.states.parry,ship.x+32,ship.y+32)
	]]--
	//print(enemies[1][1].hp,ship.x,ship.y+20)
	print(flr(ship.hp),ship.x+10,ship.y)
	end

shots=0
-->8
//ship update and input
//laser

function upd_ship()
	ship.turningd=base_turning
	
	if ship.states.parry>0 then
		
		ship.states.parry-=1
		ship.states.laser=false
		ship.states.shooting=false
	end
	
	if ship.states.flying then
		//sfx(5)
		add_particle(
				ship.ass1x,
				ship.ass1y,
				ship.dx-40*ship.acc*cos(ship.angle)+randb(-3,4)/5,
 			ship.dy-40*ship.acc*sin(ship.angle)+randb(-3,4)/5,
				20,12)

		ship.turningd=fly_turning
		ship.ay=ship.acc*sin(ship.angle) 
 	ship.ax=ship.acc*cos(ship.angle) 
	end
	
	if ship.states.laser then
		//sfx(1)
		shake_gun(0.1)
		ship.turningd=laser_turning
		fire_laser(
			ship.nosex,
			ship.nosey,
			ship.angle,
			laser.length,
			laser.segments)
	
		ship.ay-=ship.lacc*sin(ship.angle) 
		ship.ax-=ship.lacc*cos(ship.angle) 
	end
	
	if ship.states.shooting then
		//sfx(4)
		for i=-0,0 do
		shots+=1
		add_projectile(
									{x=ship.nosex,
										y=ship.nosey,
										damage=10,
										speed=2,
										t=20,
										c1=12,
										c2=background,
										angle=ship.angle+0.05*i,
										dx=ship.dx,
										dy=ship.dy},
										true,
										basic_bullet)
																	end
	end
	
	ship.angle+=ship.turningd*ship.states.turning
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
		ship.dx=ship.maxspeed*cac*0.99
		ship.dy=ship.maxspeed*cas*0.99
		end

	ship.nosex=ship.x+10*ac
	ship.nosey=ship.y+10*as
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
		rspr(1,ship.x,
									ship.y,
									ship.angle,
									1,
									ship.scale)
	end
	
	
				
	if ship.states.shooting then
		rspr(9,								//draw flash
						ship.nosex,
						ship.nosey,
						ship.angle,
						0,
						1.5)
	end
end

function handle_input()
	ship.states.turning=0
	ship.states.flying=false
	ship.states.shooting=false
	ship.states.laser=false
	if btn(⬅️) and not btn(➡️) then 
		ship.states.turning=1 
	end
	if btn(➡️) and not btn(⬅️) then
		ship.states.turning=-1
	end
	if btn(⬆️) and not btn(⬇️) then 
		ship.states.flying=true
	end
	if btn(⬇️) then
		ship.states.laser=true
	end
	ship.states.parry_cd-=1
	if btn(🅾️) then
		if ship.states.parry_cd <0 then
		ship.states.parry=2
		ship.states.parry_cd=60
		end
	end
	if btn(❎) and tt%5==0 then
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
		a.c=7
		a.on_hit={}
		a.on_death={}
		
		add_friend_projectile_collider(a)
	end	
end




function draw_laser(x,y,a,l,part)
	ca=cos(a) sa=sin(a)
	x1=x+l*ca
	y1=y+l*sa
	//line(x,y,x1,y1,1)
	decay_line(x,y,x1,y1,80,4,2,8,false)
	decay_line(x,y,x1,y1,80,3,1,10,part)
	decay_line(x,y,x1,y1,80,2,2,7,false)
	
		add_particle(
				ship.nosex,
				ship.nosey,
				ship.dx+1*ship.acc*cos(ship.angle)+randb(-2,3)/5,
 			ship.dy+1*ship.acc*sin(ship.angle)+randb(-2,3)/5,
				20,randb(8,9))
				
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

function clear_collision()
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
		if collide(p,e) and e.invincible==0 then
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
	
function parry(p)
				
				p.angle=0.5+p.angle
				p.speed*=1
				p.friendly=true
				//p.t+=20
				p.c1=7
				
				explode(p)
				p.invincible=10
				freeze_frame+=10
				shake_explode(0.2)
				sfx(3)

end
	
function manage_player_collisions()
	for p in all(player_collisions) do
		if ship.states.parry>0 and 
					collide(p,ship) 
		then
			if p.is_parriable and 
						p.invincible==0 then
						parry(p)
			end
		end
			
			if ship.invincible==0 and 
					collide_p(p,ship) 
			then
				for oh in all(p.on_hit) do
					oh(p,ship)
				end
				for oh in all(ship.on_hit) do
					oh(ship,p)
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


function draw_collisions()
	local h=(cr_border*2*cr_cell+128)/(cr_dimensions)
	
	for p in all(player_collisions) do
		circ(p.x,p.y,p.collider_r+1,0)			
		
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
-->8
//stars, particles and projectiles
function add_stars()
	for i=0,100 do
		local star={}
		star.x=randb(0,256)
		star.y=randb(0,256)
		star.d=randb(50,99)/100
		star.c=7
		star.move=randb(1,3)
		add(stars,star)
		end
	for i=0,150 do
		local star={}
		star.x=randb(0,256)
		star.y=randb(0,256)
		star.d=randb(3,20)/100
		star.c=2
		star.move=randb(1,3)
		add(stars,star)
		end
end



function draw_stars()
	for i in all(stars) do
		local x=i.x+cam.x*i.d
		local y=i.y+cam.y*i.d
		if x>cam.x+128 then i.x-=256 end
		if x<cam.x-128 then i.x+=256 end
		if y>cam.y+128 then i.y-=256 end
		if y<cam.y-128 then i.y+=256 end
		pset(x,y,i.c)
		circfill(x,y,0.5/i.d,i.c)
	end
end



function add_particle(x,y,dx,dy,t,c)
	local a={}
	a.x=x
	a.y=y
	a.dx=dx
	a.dy=dy
	a.t=t
	a.c=c
	add(particles,a)
end

function draw_particles()
	for a in all(particles) do
		pset(a.x,a.y,a.c)
		circfill(a.x,a.y,a.t/15,a.c)
	end
end

function upd_particles()
	for a in all(particles) do
		a.x+=a.dx
		a.y+=a.dy
		a.t-=1
		if a.t<0 then
			del(particles,a)
		end
	end
end

function add_projectile(pos,
																								friendly,
																								template)
	local p=table_clone(template)
	p.created=tt
	p.id=#projectiles+1
	p.util=randb(-100,100)
	p.friendly=friendly
	
	for key,obj in pairs(pos) do
		p[key]=obj
	end
	
	add(projectiles,p)																								
end


function draw_all(p)
	for a in all(p) do
		a.draw(a)
	end
end

function upd_all(p)
	for a in all(p) do
		for u in all(a.update) do
			u(a)
		end
	end
end



-->8
//enemies and snakes


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
//test this


function add_enemy(pos,	template)
	local e=table_clone(template)
	e.id=#enemies+1
	e.util=randb(-100,100)
	e.invincible=0
	for key,obj in pairs(pos) do
		e[key]=obj
	end
	add(enemies,e)							
end

//template






function update_all_entities()
	for a in all(enemies) do
		update_entity(a)
	end
	for a in all(projectiles) do
		update_entity(a)
	end
end

function update_entity(self)
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






function add_snake(x,
																			y,
																			c1,
																			c2,
																			hp,
																			l)
	local s={}
	local snake_width=randb(5,8)
	s.hp=hp
	s.angle=0
	s.r=0
	s.x=0
	s.y=0
	s.segments={}
	s.segments2={}
	s.c1=c1
	s.c2=c2
	s.node_distance=1
		head={x=x,
							c1=8,
							y=y,
							r=5,
							dx=0,
							dy=0,
							hp=80,
							is_parriable=true,
							angle=0,
							speed=1.9,//1.9,
							collider_r=5,
							invincible=0,
							d=randb(20,35),
							a=0,
							damage=5,
							util=randb(-100,100)}
	add(s.segments,head)
	ff=function(e,p)
					if s.segments[1].invincible==0 then
					s.segments[1].hp-=p.damage
					end
					
					s.segments[1].invincible=10
				end
	for i=0,l do
		local segment={}
		segment.on_hit={ff,knockback}
		segment.x=x
		segment.angle=0
		segment.speed=0
		segment.damage=4
		segment.is_parriable=false
		segment.y=y+10+i*10
		segment.dx=0
		segment.invincible=0
		segment.dy=0
		segment.collider_r=min(l-i+1,snake_width)
		segment.c1=c1
 	add(s.segments,segment)
	end
	//red tail
	for i=1,#s.segments do
			s.segments2[i]={}
			s.segments2[i].x=s.segments[i].x
			s.segments2[i].y=s.segments[i].y
	end
	s.segments[#s.segments].c1=c2
	s.segments[#s.segments-1].c1=c2
	s.segments[#s.segments-2].c1=c2
	s.segments[1].on_hit={explode,oh_take_damage}
							
	add(snakes,s)
end



function update_dead_snakes()
	local death_period=3
	for s in all(dead_snakes) do
		if(tt%death_period==0)then
		 explode_snake(s.segments[1],8)//red explosion
			del(s.segments,s.segments[1])

		end
		if #s.segments==0 then
			del(dead_snakes,s)
		end
	end
end

function update_snakes()
	local period=4
	
	for s in all(snakes) do
		if s.segments[1].invincible>0 then
					s.segments[1].invincible-=1
		else
			for cc in all(s.segments) do
			
				add_enemy_collider(cc)
			
			end
		end
		for cc in all(s.segments) do
			
				add_enemy_projectile_collider(cc)
			
			end
			
		
		if s.segments[1].hp>0 then
		face_towards_ship(s.segments[1])
		add_enemy_collider(s.segments[1])
		if (tt%period==0) then
			for i=1,#s.segments do
			s.segments2[i]={}
			s.segments2[i].x=s.segments[i].x
			s.segments2[i].y=s.segments[i].y
			end
		else
				for i=2,#s.segments do
			s.segments[i].x=
				s.segments2[i].x+
				(tt%period)*
				(s.segments2[i-1].x-
				s.segments2[i].x)/period
			
			s.segments[i].y=
				s.segments2[i].y+
				(tt%period)*
				(s.segments2[i-1].y-
				s.segments2[i].y)/period
			end
		end
	else
		del(snakes,s)
		add(dead_snakes,s)
		end
		end
end



function draw_snakes()
	for s in all(snakes) do
			if s.segments[1].invincible>0 then
				for i=2,#s.segments do
 			circfill(s.segments[i].x,
 												s.segments[i].y,
 												s.segments[i].collider_r+1,
  											s.c2)
 			end
			end
			
			for i=2,#s.segments do
 			circfill(s.segments[i].x,
 												s.segments[i].y,
 												s.segments[i].collider_r,
  											s.segments[i].c1)
 			end
			pal(1,s.c1)
			pal(12,s.c2)
			rspr(7,		//head
							s.segments[1].x,
							s.segments[1].y,
							s.segments[1].angle,
							0,
							1)
			print(s.segments[1].hp,s.segments[1].x+20,
							s.segments[1].y+20)
			pal()
	end
end

function draw_dead_snakes()
	for s in all(dead_snakes) do
				circfill(s.segments[1].x,
 												s.segments[1].y,
 												s.segments[1].collider_r,
  											s.segments[1].c1)
  		circfill(s.segments[1].x,
 												s.segments[1].y,
 												s.segments[1].collider_r/2,
  											8)	//red insides
			for i=2,#s.segments do
 			circfill(s.segments[i].x+randb(-2,2),
 												s.segments[i].y+randb(-2,2),
 												s.segments[i].collider_r,
  											s.segments[i].c1)
 			end
	end
end
-->8



animations_list={}
draw_objects_list={}

function draw_draw_objects()
	for d in all(draw_objects_list) do 
		d.draw(d)
	end
end

function clear_draw_objects()
	draw_objects_list={}
end

function add_draw_object(pos,template)
	local d_o=table_clone(template)

	for key,obj in pairs(pos) do
		d_o[key]=obj
	end
	add(draw_objects_list,d_o)
	return d_o
end

function remove_draw_object(pos,template)
	
end


function add_animation(new_anim)
	add(animations_list,cocreate(new_anim))
end

function update_animations()
	if #animations_list>0 then 
		for anim in all(animations_list) do 
			if costatus(anim) != 'dead' then
				coresume(anim)
			else 
				del(animations_list,anim)
			end
		end
	end
end

function clear_animations()
	animations_list={}
end
-->8
//behaviour

//have a hitbox
//can be invincible
//can die

function bh_hitbox(self)
	if self.invincible==0 then
		if self.group=="enemy" then
			add_enemy_collider(self)
		end
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


function draw_debug(self)

	//print(self.damage,self.x,self.y+10)
	circfill(self.x,self.y,
						self.collider_r,
						self.c2)
	circfill(self.x,self.y,
						self.collider_r-1,
						self.c1)
	//print(self.hp,self.x,
	//					self.y,7)
	if self.invincible and 
				self.invincible>0 then
				fillp(0b0011011011001001.1)
				
				circfill(self.x,self.y,
						self.collider_r-1,
						2)
				fillp()
		end
						
	
	
	end





function knockback(e,p)
	ang=atan2(-e.x+p.x,
											-e.y+p.y)
	p.dx=cos(ang)*1
	p.dy=sin(ang)*1
end






function   explode_snake(a,c)
	shake_explode(0.1)
	for i=0,4 do
	add_particle(
				a.x,
				a.y,
				randb(-20,21)/10,
 			randb(-20,21)/10,
				40,c)
	end
end
	
function fish_towards_ship(a)
	
	a.a=atan2(-a.x+ship.x,
									-a.y+ship.y)+
											sin(a.util/60+
											tt/150)/5
	local as=sin(a.a)
	local ac=cos(a.a)
	a.x+=ac*a.speed
	a.y+=as*a.speed
	end



function face_towards_ship_1(self)
	local as=sin(self.angle)
	local ac=cos(self.angle)
	local ff=(-self.x+ship.x)*as -
										(-self.y+ship.y)*ac
	
	if(ff>0) then
			self.angle+=0.003
		else
			self.angle-=0.003
		end
	local angle=self.angle+
													sin(self.util/100+
													tt/150)/10
	self.x+=cos(angle)*1
	self.y+=sin(angle)*1
	
	end


function face_towards_ship(a)
	
	local as=sin(a.angle)
	local ac=cos(a.angle)
	local ff=(-a.x+ship.x)*as -
										(-a.y+ship.y)*ac
	
	if(ff>0) then
			a.angle+=0.003
		else
			a.angle-=0.003
		end
	local angle=a.angle+
													sin(a.util/100+
													tt/150)/10
	a.x+=cos(angle)*a.speed
	a.y+=sin(angle)*a.speed
	
	if (tt+a.util*2)%300==0 then
		shoot_at_player(a)
	end
	end
	

	
function explode(a)
	shake_explode(0.2)
	for i=0,10 do
	add_particle(
				a.x,
				a.y,
				a.dx+randb(-4,5)/20,
 			a.dy+randb(-4,5)/20,
				40,randb(7,12))
	end
end

function dissolve(a)
	for i=0,5 do
	add_particle(
				a.x,
				a.y,
				a.dx+randb(-4,5)/20,
 			a.dy+randb(-4,5)/20,
				30,a.c1)
	end
end

function oh_take_damage(e,p)
	if e.invincible==0 then
	e.hp-=p.damage
	e.invincible=20
	end
end

function del_entity(self)
	if self.group=="enemy" then
		del(enemies,self)
	else if self.group=="proj" then
		del(projectiles,self)
		end
	end
end



function fly_straight(a)
	a.x+=a.dx+cos(a.angle)*a.speed
	a.y+=a.dy+sin(a.angle)*a.speed
end



function shoot_at_player(a)
	offset=randb(0,100)/100
	ang=atan2(-a.x+ship.x,
											-a.y+ship.y)
	for i=-2,2 do
	add_projectile(
									{
										x=a.x,
										y=a.y,
										radia=7,
										util=i/3,
										speed=1+randb(-2,2)/20,
										c1=7,
										c2=background,
										angle=ang+randb(-2,2)/50,
										dx=0,
										dy=0},
										false,
										basic_bullet)
	end
end


function shoot_straight(a)
	offset=randb(0,100)/100
	for i=0,0 do
	add_projectile(
									{
										x=a.x,
										y=a.y,
										radia=7,
										util=i/3,
										speed=3,
										c1=2,
										damage=5,
										c2=background,
										angle=a.angle,
										dx=0,
										dy=0},
										false,
										basic_bullet)
	end
end




template_enemy={collider_r=5,
							group="enemy",
							sp=2,
							c1=8,
							c2=background,
							hp=20,
							speed=0.5,
							damage=1,
							is_parriable=true,
							update={face_towards_ship,bh_hitbox},
       draw=draw_debug,
       on_hit={oh_take_damage},
							on_death={explode,shoot_straight,del_entity}//explode}
							}
							
basic_bullet={
							group="proj",
							collider_r=3,
							damage=1,
							hp=200,
							c1=12,
							speed=4,
							invincible=0,
							is_parriable=true,
							update={fly_straight,bh_hitbox,bh_tick_hp},
       draw=draw_debug,
       on_hit={explode},//,del_entity},
							on_death={dissolve,del_entity}
							}
	
ship_d_o={
		c=4,					
		draw=function(self)
			spr(16+32*flr(1.5+(1.4*sin(tt/250))),self.x-10,self.y-8,6,2)
		end
		}

ship.on_hit={explode,oh_take_damage}

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
	
	cam.x=ship.x+offset_x
	cam.y=ship.y+offset_y
	
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
00000000111aa111111771111110011100aaaa00000000000000000000c00c000007700000000000006c000000076c0000000000000000000000000000000000
00000000111aa111111771111110011100aaaa0000000000000000000011110007777770000000000c000000000000c000a0a000000000000000000000000000
00700700111aa111111771111100001100adda00000cc000000aa00001c11c100777777000000000c00000000000000c00a0a000000000000000000000000000
0007700011aaaa11117aa7111100001100dddd00000cc000000aa0001cc11cc17777777700000000600000077000000c00a0a000000000000000000000000000
0007700011aaaa11117aa71111100111000dd00000cccc0000adda001c1111c17777777700000000700000067000000600000000000000000000000000000000
0070070011aaaa1111aaaa1111100111000dd0000cccccc00adddda01111111107777770000700000000000cc00000000a000a00000000000000000000000000
000000001aaaaaa11aaaaaa11100001100adda000000000000000000111111110777777000777000000000c0060000000aaaaa00000000000000000000000000
000000001aaaaaa11aaaaaa11101101100d00d000000000000000000011111100007700077777770000cc60000cc000000000000000000000000000000000000
00000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaa0aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaaa0007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaaa0077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaaaa0000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000aaaaaaaaaa0000aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000aaaaaaaaa000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000aaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000aaaaaaaaaaaaa000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000aaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000aaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000aaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000aaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000777700000000000000077770000000000000000000000000000000000000000000000
00777777770000000000000000000000000000000000000000000000000777700000007770000077770000000000000000000000000000000000000000000000
07777777770000000000000000000000000000000000000000000000000077700000007770000007770000000000000000000000000000000000000000000000
77770000770000000000000000000000000000000000000000000000000077700000000000000007770000000000000000000000000000000000000000000000
77700000770000000000000000000000000000000000000000000000000077700000000000000007770000000000000000000000000000000000000000000000
77000000000077777700777777777777777777770077777707777777770077777770077770077777770077777007777777077777777700000000000000000000
77000000000777777770777770777777777777770777777777777777777007777777077770777777770777777700007777077777777700000000000000000000
77000000000777007770777000077700777007770777007770777000777007700777007770777000770770077700000777007770077700000000000000000000
77700000000770007770777770007700077000770770007770777000777007700077000770770000770777777707777777000770007700000000000000000000
77700000000770007770777777007700077000770770007770777000777007700077000770770000770770000007777777000770007700000000000000000000
77770000077777007770000777007700077000770777007770077000777077700077000770777000770777000007700777000770007700000000000000000000
07777777770777777777777777777770777707777777777770077777777777700777777777777777777777777707777777077777077770000000000000000000
00777777700077777707777770777777777777777077777700077777770777770777077777077777777077777777777777777777077770000000000000000000
00000000000000000000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000777000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000007777700000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000007777770000000000000000000000000000000000000000000000000000000000000000000000000
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

