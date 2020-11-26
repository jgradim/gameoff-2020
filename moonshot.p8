pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--moonshot
--by goncalo, jgradim, pkoch

--global:constants,loop,utils

---------------
---constants---
---------------

fps=30

map_width=1024
map_height=256

--downward movement per cycle
gravity=0.2

--movement multiplier per cycle
inertia=0.75

-------------
---sprites---
--------------

sp_player_idle=1
sp_player_run_start=2
sp_player_run_length=3
sp_player_jump=3
sp_player_glide=5

sp_spark_start=19
sp_spark_length=4

sp_platform_start=48
sp_platform_length=4

sp_door_opened=37
sp_door_closed=32

sp_button_on=16
sp_button_off=18

sp_speech=10
sp_e_pod=28
sp_tiny_font=128

---------------------
---player colors---
---------------------
p_colors={
  red={[8]=8},
  yellow={[1]=0,[12]=5,[8]=9},
  blue={[8]=1,[12]=14,[6]=5},
  green={[8]=3,[10]=11}
}

------------------
---sprite flags---
------------------

--obstacles that are rigid and
--apply in all directions
flag_hits=0

--obstacles the player can stand
--on but otherwise move through
flag_stands=1

--------------------------
---dynamic map elements---
--------------------------
function init_mechanics()
 --sparks
 --x,y
 local sprk0=init_spark(
  33*8,28*8
 )
 local sprk1=init_spark(
  34*8,25*8
 )
 local sprk2=init_spark(
  35*8,25*8
 )
 local sprk3=init_spark(
  35*8,26*8
 )
 local sprk4=init_spark(
  36*8,28*8
 )
 local sprk5=init_spark(
  37*8,28*8
 )
 local sprk6=init_spark(
  38*8,25*8
 )
 local sprk7=init_spark(
  38*8,26*8
 )
 local sprk8=init_spark(
  39*8,25*8
 )
 local sprk9=init_spark(
  39*8,28*8
 )
 local sprk10=init_spark(
  40*8,28*8
 )

 --platforms
 --x,y,w,h,delta_fn
 local plt0=init_platform(
  1*8,24*8,8,8,
  linear_delta_fn(
   --1,3 <-> 1,13
   1*8,24*8,8*8,104*8
  )
 )
 local plt1=init_platform(
  5*8,13*8,8,8,
  linear_delta_fn(
   --5,13 <-> 6,13
   5*8,13*8,6*8,13*8
  )
 )
 local plt2=init_platform(
  14*8,15*8,8,8,
  linear_delta_fn(
   --14,15 <-> 14,13
   14*8,15*8,14*8,13*8
  )
 )
 local plt3=init_platform(
  58*8,25*8,8,8,
  linear_delta_fn(
   --59,26 <-> 59,29
   58*8,25*8,58*8,28*8
  )
 )

 --doors
 --x,y,open
 local door0=init_door(
  56*8,28*8,false
 )

 --buttons
 --x,y,on
 local btn0=init_button(
  62*8,25*8,false,
  door_toggle_fn(door0),
  "❎"
 )

 --return list of mechanics
 return {
  sprk0,sprk1,sprk2,sprk3,
  sprk4,sprk5,sprk6,sprk7,
  sprk8,sprk9,sprk10,
  plt0,plt1,plt2,plt3,plt4,
  door0,
  btn0,
 }
end

----------
---loop---
----------

function _init()
 --btnp never repeats
 poke(0x5f5c, 255)

 --mechanics
 mcns=init_mechanics()

 --players
 all_players={
  init_player{
   ⬆️=double_jump,
  },
  init_player{
   ⬆️=glide,
   color="green",
  },
  init_player{
   ⬆️=jump,
   color="yellow",
   x=60*8,
   y=28*8,
  },
 }

 --fxs
 init_bg_fxs()
 init_fxs()

 --camera
 cam=init_camera()
end

function update(o) return o:update() end

function _update()
 --input
 player_btns={"⬅️","➡️","⬆️"}
 for i=1,#player_btns do
  if btn(i-1) then
   fn=player()[player_btns[i]]
   if (fn) fn(player(),btnp(i-1))
  end
 end
 if btnp(🅾️) then
  focus_next_player()
 end
 --if btnp(🅾️) then
 -- if path.found then
 --  path:apply()
 -- else
 --  path:find(
 --   all_players[2],
 --   all_players[2],
 --   player()
 --  )
 -- end
 --end

 --players
 path:update()
 foreach(all_players,update_player)

 --mechanics
 foreach(mcns,update)

 --fxs
 fire_fxs()
 update_bg_fxs()
 update_fxs()

 --camera
 cam:update()
end

function draw(o) return o:draw() end

function _draw()
 cls()

 --fxs
 draw_bg_fxs()
 animate_lights()
 map(0,0)
 pal()
 draw_fxs()

 --tiny text
 print_tiny(
  "diagnostics",
  60*8+4,24*8,14
 )

 --mechanics
 foreach(mcns,draw)

 --players
 foreach(all_players,draw_player)

 --camera
 cam:draw()

 --debug
 color(8)
 cpu=tostring(stat(1)*100\1)
 print(
  cpu,
  peek2(0x5f28)+128-#cpu*4+1,
  peek2(0x5f2a)
 )
 if debug then
  print(
   debug,
   peek2(0x5f28),
   peek2(0x5f2a)
  )
 end
end

-----------
---utils---
-----------

function player()
 return all_players[#all_players]
end

function focus_next_player()
 add(
  all_players,
  deli(all_players,#all_players),
  1
 )
end

function sprite_coords(tile)
  return {
    x=8*(tile%16),
    y=8*flr(tile/16),
  }
end

function init_camera()
 return {
  x=0,
  y=0,
  frms=7.5,

  update=function(c)
   c.x+=bucket((player().x - c.x)/c.frms)
   c.y+=bucket((player().y - c.y)/c.frms)
  end,

  draw=function(c)
   camera(
    mid(0,c.x-64,map_width-64),
    mid(0,c.y-64,map_height-128)
   )
  end,
 }
end

--have kls "extends" super
function class(super,kls)
 kls.meta={__index=super}
 return setmetatable(
  kls,kls.meta
 )
end

---make o an instance of kls
function instance(kls,o)
  return setmetatable(
   o,{__index=kls}
  )
end

--check if a contains b
function contains(a,b)
 --[[
 a={x,y,w,h}
 b={x,y,w,h}
 ]]
 return a.x<=b.x
 and a.y<=b.y
 and a.x+a.w>=b.x+b.w
 and a.y+a.h>=b.y+b.h
end

--check if a intersects b
function intersects(a,b)
 --[[
 a={x,y,w,h}
 b={x,y,w,h}
 ]]
 return a.x<b.x+b.w
 and a.y<b.y+b.h
 and a.x+a.w>b.x
 and a.y+a.h>b.y
end

--todo:document
function bucket(v, step)
 if (step==nil) step=0x0.01
 v-=sgn(v)*(v%step)
 if (abs(v)<step) v=0
 return v
end

--clamp v between -max_v and
--max_v in steps step
function clamp(v,max_v,step)
 return bucket(
  mid(-max_v,v,max_v),
  step
 )
end

--ease function for f=[0,1]
function ef_smooth(f)
 return f*f*f*(f*(f*6-15)+10)
end

function hitbox(p)
 return {
  x=p.x+1,
  y=p.y+1,
  w=p.w-2,
  h=p.h-1,
 }
end

function stand_box(p)
 return {
  x=p.x+2,
  w=4,
  y=p.y+p.h,
  h=1,
 }
end

function sprite_hitbox(sp, x, y)
  return {x=x,y=y,w=8,h=8}
end

function collisions(p,flag)

 local hb=hitbox(p)
 local collisions={}

 --check mechanics
 for m in all(mcns) do
  if m.collide
  and intersects(m,hb)
  and fget(m.sp,flag) then
   add(collisions,m)
  end
 end

 --check map
 local x1=hb.x
 local x2=hb.x+hb.w-1
 local y1=hb.y
 local y2=hb.y+hb.h-1
 for x in all({x1,x2}) do
  for y in all({y1,y2}) do
   local map_sp=mget(x/8,y/8)
   if fget(map_sp, flag)
   and intersects(
     sprite_hitbox(map_sp, x, y),
     hb
   )
   then
    add(collisions,{
     x=x\8*8,
     y=y\8*8,
     w=8,
     h=8,
     dx=0,
     dy=0,
     collide=block,
    })
   end
  end
 end

 return collisions
end

function flag_on_xy(x,y,flag)
 return fget(mget(x/8,y/8),flag)
end

--blocks p from intersecting cl
--returns block direction
function block(cl,p)
 local aim = coll_aim(cl,p)

 if aim == "⬅️" then
  p.x+=cl.x-p.x-p.w+1
  return aim
 end
 if aim == "➡️" then
  p.x+=cl.x+cl.w-p.x-1
  return aim
 end
 if aim == "⬆️" then
  p.y+=cl.y+cl.h-p.y-1
  return aim
 end
 if aim == "⬇️" then
  p.y+=cl.y-p.y-p.h
  return aim
 end

 assert(false, "unkown aim")
end

function coll_aim(cl,p)
 local x=max(p.x,cl.x)
 local y=max(p.y,cl.y)
 local int={
  x=x,
  y=y,
  w=min(p.x+p.w,cl.x+cl.w)-x,
  h=min(p.y+p.h,cl.y+cl.h)-y,
 }

 --resolve using shallowest axis
 if int.w<int.h then
  p.dx=0
  if p.x<cl.x then
   return "⬅️"
  else
   return "➡️"
  end
 else
  p.dy=0
  if p.y>cl.y then
   return "⬆️"
  else
   return "⬇️"
  end
 end
end

--[[
--to use, prepend "-" above
function tostring(any)
 if type(any)!="table" then
  return tostr(any)
 end
 local str="{"
 for k,v in pairs(any) do
  if (str!="{") str=str..","
  str..=tostring(k).."="..tostring(v)
 end
 return str.."}"
end
--]]

-->8
--player

------------
---player---
------------

run_accel=0.55
jump_accel=2.55

function init_player(p)
 return instance({
  x=0,
  y=0,
  w=8,
  h=8,
  dx=0,
  dy=0,
  max_dx=2,
  max_dy=3,

  running=false,
  jumping=false,
  falling=false,
  gliding=false,
  glided=false,
  ground=false,
  landed=false,

  color="red",
  sp=sp_player_idle,
  flpx=false,
  flpy=false,

  ⬅️=run_left,
  ➡️=run_right,
  ⬆️=glide,
 }, p)
end

function update_player(p)
 local old_y=p.y\1
 local old_x=p.x\1
 
 --move horizontally
 p.dx*=inertia
 p.dx=clamp(p.dx,p.max_dx,0x.08)
 p.x+=p.dx
 local hcl=collisions(p,flag_hits)
 for cl in all(hcl) do
  cl:collide(p)
 end

 --move vertically
 if p.flpy then
  p.dy-=gravity
 else
  p.dy+=gravity
 end
 p.dy=clamp(p.dy,p.max_dy,0x.08)
 p.y+=p.dy
 local ground_aim=
  p.flpy and "⬆️" or "⬇️"
 local ground_hit=false
 local vcl=collisions(p,flag_hits)
 for cl in all(vcl) do
  local aim=cl:collide(p)
  if (aim==ground_aim) ground_hit=true
 end

 --state
 local was_ground=p.ground
 --running:x changes after dx
 --and collisions
 p.running=p.x\1!=old_x
 --ground:ground hit or no y
 --changes while on ground
 p.ground=ground_hit or
  (p.ground and p.y\1==old_y)
 --landed:newly on ground
 p.landed=p.ground and not was_ground
 if p.ground then
  p.falling=false
  p.jumping=false
  p.gliding=false
 else
  --falling:moving downwards
  --(mini gravity movements
  --excluded since ground=true)
  p.falling=not p.gliding and
   (p.flpy and p.dy<0 or p.dy>0)
  if p.falling then
   p.jumping=false
   p.gliding=false
  end
 end
 --glided:glided this cycle
 p.glided=p.gliding
 --gliding:true on user input
 p.gliding=false

 --sprite
 if p.glided then
  p.sp=sp_player_glide
 elseif p.jumping then
  p.sp=sp_player_jump
 elseif p.falling then
  p.sp=sp_player_idle
 elseif p.running then
  p.sp=sp_player_run_start+
   (t()*10)%sp_player_run_length
  play_sfx("walk")
 else
  p.sp=sp_player_idle
 end
end

function run_left(p)
 p.dx-=run_accel
 p.flpx=true
 p.running=true
end

function run_right(p)
 p.dx+=run_accel
 p.flpx=false
 p.running=true
end

function jump(p,first)
 if (not first) return

 if p.ground then
  p.dy=-jump_accel
  play_sfx("jump")
  p.jumping=true
 end
end

function grav_boots(p,first)
 if (not first) return

 p.flpy= not p.flpy
end

function double_jump(p,first)
 if (not first) return

 if not p.jumping
 and not p.falling then
  jump(p,true)
  p._j=true
 elseif p._j then
  p.ground=true
  jump(p,true)
  p._j=nil
 end
end

function glide(p,_)
 if not p.gliding
 and p.ground
 then
  jump(p,true)
  return
 end

 if not p.gliding
 and p.jumping
 then
  return
 end

 p.gliding=true
 p.dy-=gravity+0.25
end

function draw_player(p)
 local cm = p_colors[p.color]
 for c1,c2 in pairs(cm) do
   pal(c1,c2)
 end
 spr(p.sp,p.x,p.y,1,1,p.flpx, p.flpy)
 pal()
end
-->8
--mechanics:platforms,doors,etc

------------
---sparks---
------------

sparks={}
function init_spark(
 x,y
)
 return {
  x=x,
  y=y,
  w=8,
  h=8,
  dx=0,
  dy=0,
  sp=sp_spark_start,

  collide=function(s,p)
   local old_dx=p.dx
   local old_dy=p.dy
   local aim=block(s,p)
   if aim=="⬅️" or aim=="➡️"
   then
    p.dx=-old_dx*10
   elseif aim=="⬆️" or aim=="⬇️"
   then
    p.dy=-old_dy*10
   end
   spark_aura:on_player(p)
  end,

  update=function(s)
   s.sp=sp_spark_start+(t()*10)%sp_spark_length
  end,

  draw=function(s)
   spr(s.sp,s.x,s.y)
  end
 }
end

---------------
---platforms---
---------------

function init_platform(
 x,y,w,h,delta_fn
)
 --[[
 x,y,w,h=platform pos/size
 delta_fn=fn that updates dx/dy
 ]]
 return {
  sp=sp_platform_start,
  x=x,
  y=y,
  w=w,
  h=h,
  dx=0,
  dy=0,

  delta_fn=delta_fn,

  collide=block,

  update=function(p)
   if (p.delta_fn) p:delta_fn()
   p.x+=p.dx
   p.y+=p.dy

   foreach(all_players, function(pl)
    if intersects(stand_box(pl), p) then
     pl.x+=p.dx
     pl.y+=p.dy
    end
   end)

   p.sp=sp_platform_start+
    (t()*8)%sp_platform_length
  end,

  draw=function(p)
   spr(p.sp,p.x,p.y,1,1)
  end,
 }
end

function linear_delta_fn(
 x,y,to_x,to_y
)
 local dx=(to_x-x)+0.5
 local dy=(to_y-y)+0.5
 return function(plat)
  local f=ef_smooth(
   abs(time()%6-3)/3
  )
  plat.dx=bucket(x+dx*f-plat.x)
  plat.dy=bucket(y+dy*f-plat.y)
 end
end

-----------
---doors---
-----------

function init_door(x,y,open)
 local sp
 if open then
  sp=sp_door_opened
 else
  sp=sp_door_closed
 end
 return {
  sp=sp,
  x=x,
  y=y,
  w=8,
  h=8,
  open=open,

  collide=block,

  update=function(d)
   local dsp=0
   if d.open
   and d.sp!=sp_door_opened
   then
    dsp=1
   end
   if not d.open
   and d.sp!=sp_door_closed
   then
    dsp=-1
   end
   d.sp+=dsp
  end,

  draw=function(d)
   spr(d.sp,d.x,d.y,1,1)
  end,
 }
end

-------------
---buttons---
-------------

function init_button(
 x,y,on,toggle_fn,label
)
 local sp = on and sp_button_on
  or sp_button_off

 return {
  sp=sp,
  x=x,
  y=y,
  w=8,
  h=8,
  on=on,
  label=label,
  toggle=function(b)
    b.on = not b.on
    b.sp = b.on and sp_button_on
     or sp_button_off

    toggle_fn(b.on)
  end,

  collided_prev=false,
  collided_at=0,

  collide=function(b)
   b.collided_at=time()
  end,

  update=function(b)
   --collision changes
   local collided=
    b.collided_at==time()

    if collided and btnp(❎) then
       b:toggle()
   end

   b.collided_prev=collided
  end,

  draw=function(b)
   spr(b.sp,b.x,b.y,1,1)
   if b.label != nil
    and b.collided_prev then
     local c=
      p_colors[player().color][8]

     speech_bubble(
      b.x,b.y,b.label,c
     )
   end
  end,
 }
end

function door_toggle_fn(d)
 return function(on)
  d.open=on
  if (on)
    then play_sfx("door_open")
    else play_sfx("door_close")
    end
 end
end

-->8
--fxs:player,bg,lights

----------------
---player fxs---
----------------

function init_fxs()
 particles={}
end

function fire_fxs()
 foreach(
  all_players,
  function(p)
   if p.glided then
    rocket:on_player(p)
   end
   if p.landed then
    land:on_player(p)
   end
  end
 )
end

function update_fxs()
 for f in all(particles) do
  f.t+=1
  if f.life<=f.t then
   del(particles,f)
  else
   f:update()
  end
 end
end

function draw_fxs()
 for f in all(particles) do
  f:draw()
 end
end

base_fx={
 t=0,
 c=0,
 r=1,
 dx=0,
 dy=0,
 dr=0,
 colors={},

 sched=function(kls,...)
  for i=1,kls.amount do
   f=kls:gen_particle(...)
   kls:add_particle(f)
  end
 end,

 add_particle=function(kls,f)
  f.t=0
  f=instance(kls,f)
  return add(particles,f)
 end,

 curr_color=function(f)
  return f.colors[
   ceil(f.t*#f.colors/f.life)
  ]
 end,

 draw=function(f)
  circfill(f.x,f.y,f.r,f.c)
 end,

 update=function(f)
  f.x+=f.dx
  f.y+=f.dy
  f.r+=f.dr
  f.c=f:curr_color()
 end,
}

rocket=class(base_fx,{
 width=3,
 colors={8,9,10,6},
 amount=6,

 on_player=function(kls,p)
  local x_off=0
  if p.flpx then x_off=8 end
  kls:sched(
   p.x+x_off,
   p.y+8,
   -p.dx,
   -p.dy
  )
 end,

 gen_particle=function(
  kls,
  x,
  y,
  dx,
  dy
 )
  local w=kls.width
  return {
   x=x-w/2+rnd(w),
   y=y-w/2+rnd(w),
   life=6+rnd(3),
  }
 end,

 update=function(f)
  f.x+=f.dx
  f.y+=f.dy
  f.r+=f.dr
  f.c=f:curr_color()

  if flag_on_xy(
   f.x,f.y,flag_hits
  ) then
   f.r=0
   f.dx=0
   f.dy=0
  end
 end,
})

spark_aura=class(base_fx,{
 colors={10,9},
 amount=6,
 t=0,
 life=fps,

 on_player=function(kls,p)
  add(
    particles,
    instance(kls,{player=p})
  )
 end,

 update=function(f)
 end,

 draw=function(f)
  local p=f.player
  for i=1,f.amount do
   pset(
     p.x+rnd(p.w-1),
     p.y+rnd(p.h-1),
     f:curr_color()
   )
  end
 end,
})

land=class(base_fx,{
 colors={7,6,13},
 life=20,
 dy=-0.3,

 on_player=function(kls,p)
  kls:sched(p.x+4,p.y+8)
 end,

 sched=function(kls,x,y)
  kls:add_particle({
   x=x,
   y=y,
   dx=-0.3,
  })

  kls:add_particle({
   x=x,
   y=y,
   dx=0,
  })

  kls:add_particle({
   x=x,
   y=y,
   dx=0.3,
  })
 end,
})

--------------------
---background fxs---
--------------------

function init_bg_fxs()
 bg_particles={}
 far_star:add_plane()
 near_star:add_plane()
end

function update_bg_fxs()
 for f in all(bg_particles) do
  f.t+=1
  f.t%=f.life

  f:update()
 end
end

function draw_bg_fxs()
 for f in all(bg_particles) do
  f:draw()
 end
end

bg_fx={
 t=0,
 c=0,
 dx=0,
 colors={1},

 add_plane=function(kls)
  for i=1,75 do
   kls:add_particle({
     x=rnd(128)\1,
     y=rnd(128)\1,
     life=30+rnd(90)*fps,
   })
  end
 end,

 add_particle=function(kls,f)
  f.t=1
  f=instance(kls,f)
  return add(bg_particles,f)
 end,

 curr_color=function(f)
  return f.colors[
   ceil(f.t*#f.colors/f.life)
  ]
 end,

 update=function(f)
  f.x+=f.dx
  f.x%=128
  f.c=f:curr_color()
 end,

 draw=function(f)
  --camera
  local cmx = %0x5f28
  local cmy = %0x5f2a
  pset(cmx+f.x,cmy+f.y,f.c)
 end,
}

far_star=class(bg_fx,{
 colors={5,6},
 dx=-1/fps,
})

near_star=class(bg_fx,{
 colors={7,15},
 dx=-6/fps,
})

----------------
---lights fxs---
----------------

light_masks={2,4,11,15}
light_freqs={
 [2]=4,
 [11]=7,
 [4]=7,
 [15]=11,
}
light_seqs={
 [2]={12,12,1,0,1},
 [11]={12,12,1,0,1},
 [4]={8,9,12,1},
 [15]={8,9,12,1},
}

function animate_lights()
 for m in all(light_masks) do
  local f=light_freqs[m]
  local s=light_seqs[m]
  local c=
   (abs(cos(t()/f))*(#s-1)+.3)\1

  pal(m,s[c+1])
 end
end

--------------------
---speech bubbles---
--------------------

function speech_bubble(x,y,l,c)
  local sx=8*(sp_speech%16)
  local sy=8*flr(sp_speech/16)
  local dx=x-4
  local dy=y-12+cos(t()/2)+.5

  pal(11,c)
  sspr(sx,sy,16,16,dx,dy)
  pal()
  print(l,dx+3,dy+2,7)
end

-----------------
---escape pods---
-----------------

function escape_pod(x,y,l,cm)
  local sx=8*(sp_e_pod%16)
  local sy=8*(sp_e_pod/16\1)

  for c1,c2 in pairs(cm) do
    pal(c1,c2)
  end
  sspr(sx,sy,32,24,x,y)
  pal()
  print_tiny(l,x+11,y+15,9)
end

---------------
---tiny text---
---------------

-- https://www.1001fonts.com/tinier-font.html
tiny_font={
 a={0,0,3,3},
 b={0,3,3,3},
 c={0,6,3,3},
 d={0,9,3,3},
 e={0,12,3,3},
 f={0,15,3,3},
 g={0,18,3,3},
 h={0,21,3,3},
 i={3,0,1,3},
 j={3,3,2,3},
 k={3,6,3,3},
 l={3,9,2,3},
 m={3,12,5,3},
 n={3,15,4,3},
 o={3,18,3,3},
 p={3,21,2,3},
 q={8,0,3,3},
 r={8,3,3,3},
 s={8,6,3,3},
 t={8,9,3,3},
 u={8,12,3,3},
 v={8,15,3,3},
 w={8,18,5,3},
 x={8,21,3,3},
 y={11,0,3,3},
 z={11,3,3,3},
 [1]={11,6,2,3},
 [2]={11,3,3,3}, -- z
 [3]={11,9,3,3},
 [4]={11,12,3,3},
 [5]={8,6,3,3},  -- s
 [6]={11,15,3,3},
 [7]={13,18,3,3},
 [8]={11,21,3,3},
 [9]={13,2,3,3},
 [0]={13,6,3,3},

 [" "]={4,0,3,3},
}

function print_tiny(str,x,y,c)
 local chars=split(str,"")
 local sc=sprite_coords(sp_tiny_font)
 local cursor=0

 for char in all(chars) do
  local r=tiny_font[char]
  --pal(14,2)
  --sspr(
  --  sc.x+r[1],sc.y+r[2],
  --  r[3],r[4],
  --  x+cursor-1,y+1
  --)
  pal(14,c or 14)
  sspr(
    sc.x+r[1],sc.y+r[2],
    r[3],r[4],
    x+cursor,y
  )
  pal()
  cursor+=r[3]+1
 end
end

-->8
--path

path={
 player=nil,
 from=nil,
 to=nil,

 --{idle,find,apply}
 state="idle",
 found=false,

 --open nodes to explore,
 --ordered by priority
 open={},
 --cost for each node
 cost={},
 --grid to discretize space
 grid=8,

 --sequence of btns from->to
 btns={},

 find=function(
  self,player,from,to,grid
 )
  self.player=player

  self.from=from
  self.to=to

  grid=grid or 8
  self.grid=grid

  self.open={}
  self.cost={}
  if to!=nil then
   if vec2i(from,grid)==
    vec2i(to,grid)
   then
    self.state="idle"
    self.found=true
   else
    insert(self.open,from,0)
    from_i=vec2i(from,grid)
    self.cost[from_i]=0
    self.state="find"
    self.found=false
   end
  else
   self.state="idle"
   self.found=false
  end

  self.btns={}
 end,

 apply=function(self)
  self.state="apply"
 end,

 clear=function(self)
  self:find(nil,nil,nil)
 end,

 update=function(self)
  if self.state=="find"
  then
   self:_update_find()
  elseif self.state=="apply"
  then
   self:_update_apply()
  end
 end,

 _update_find=function(self)
  local from=self.from
  local to=self.to

  if not from or not to then
   return nil
  end

  local open=self.open
  local cost=self.cost
  local grid=self.grid

  while #open>0 do
   local cur=popend(open)

   --check if done
   if vec2i(cur,grid)==
    vec2i(to,grid)
   then
    cur=cur.prev
    local c_i=vec2i(cur,grid)
    local f_i=vec2i(from,grid)

    --go through previous nodes
    --and build self.btns
    while c_i!=f_i do
     prepend(self.btns,cur.btns)
     cur=cur.prev
     c_i=vec2i(cur,grid)
    end

    self.found=true
    break
   end

   --expand current node
   local ns=self._expand(
    self,cur
   )
   for n in all(ns) do
    local new_cost=
     cost[vec2i(cur,grid)]+1

    local n_i=vec2i(n,grid)
    if not cost[n_i]
    or cost[n_i]>new_cost
    then
     cost[n_i]=new_cost
     insert(
      open,
      n,
      --divide distance by 8
      --to snap to map tiles,
      --bringing it to the
      --magnitude of cost (1)
      new_cost+
       distance(n,to)/grid
     )
    end
   end

   --avoid exhausting frame time
   --todo:re-test later
   budget=stat(1)
   if budget>0.5 and budget<0.8
   or budget%1>0.5 and budget>1
   then
    return
   end
  end

  --no more open nodes
  self.state="idle"
 end,

 _update_apply=function(self)
  if #self.btns>0 then
   move_player(
    self.player,
    unpack(pop(self.btns))
   )
  else
   self:clear()
  end
 end,

 --expand node by moving it
 _expand=function(self,n)
  local ns={}
  local grid=self.grid
  local start_x=n.x\grid
  local start_y=n.y\grid
  local prev_btns=nil
  for btns in all({
   "",--do nothing
   "⬅️",--press left
   "➡️",--press right
   "⬆️",--press up
   "⬆️⬅️",--press up/left
   "⬆️➡️",--press up/right
  }) do
   local cur={
    --player data
    x=n.x,
    y=n.y,
    w=n.w,
    h=n.h,
    dx=n.dx,
    dy=n.dy,
    max_dx=n.max_dx,
    max_dy=n.max_dy,

    --player btns functions
    ⬅️=n.⬅️,
    ➡️=n.➡️,
    ⬆️=n.⬆️,

    --pathfinding data
    prev=n,
    btns={}
   }
   --repeat btns until position
   --changes, up to 15 times
   --(see btnp() for threshold)
   for i=1,15 do
    local tap=i==1 and
     btns!=prev_btns
    move_player(cur,btns,tap)
    update_player(cur)
    add(cur.btns,{btns,tap})

    if cur.x>=0
    and cur.x<=map_width
    and cur.y>=0
    and cur.y<=map_height
    and (cur.x\grid!=start_x
    or cur.y\grid!=start_y)
    then
     add(ns,cur)
     prev_btns=btns
     break
    end
   end
  end
  return ns
 end,
}

--move player
--invokes btns as player functions
function move_player(p,btns,tap)
 for i=1,#btns do
  p[sub(btns,i,i)](p,tap)
 end
end

--diagonal distance
function distance(a,b)
 local dx=abs(a.x-b.x)
 local dy=abs(a.y-b.y)
 return (dx+dy)-0.7*min(dx,dy)
end

--preprend b's elements in a
function prepend(a,b)
 for i=1,#b do
  add(a,b[i],i)
 end
end

--insert v in t and sort t by p
function insert(t,v,p)
 if #t>=1 then
  add(t,{})
  for i=(#t),2,-1 do
   local n=t[i-1]
   if p<n[2] then
    t[i]={v,p}
    return
   else
    t[i]=n
   end
  end
  t[1]={v,p}
 else
  add(t,{v,p})
 end
end

--pop last element of t
function popend(t)
 local top=t[#t]
 del(t,top)
 return top[1]
end

--pop first element of t
function pop(t)
 local top=t[1]
 for i=1,(#t) do
  if i==(#t) then
   del(t,t[i])
  else
   t[i]=t[i+1]
  end
 end
 return top
end

--convert x,y to map index
--snaps x,y into map tiles
--i=x+width*y
function vec2i(v,grid)
 return 1+
  (v.x\grid)+
  (map_width/grid)*(v.y\grid)
end

-->8
--sound effects, music

--[[
channels:
 0. drums
 1. bass
 2. melody
 3. sfx
]]

---------------
---sound fxs---
---------------

--i=index,o=offset,l=length
sfx_map={
 walk={i=0,o=0,l=8},
 jump={i=1,o=0,l=6},
 land={i=2,o=0,l=2},
 door_open={i=3,o=0,l=3},
 door_close={i=4,o=0,l=3},
}

function play_sfx(_sfx)
 local idx=sfx_map[_sfx].i

 if (stat(19)==idx) then return end

 sfx(
  idx,
  --possibly bad idea, no way to
  --play 2 sfx at the same time
  3,
  sfx_map[_sfx].o,
  sfx_map[_sfx].l
 )
end

function stop_sfx(_sfx)
 sfx(sfx_map[_sfx].i,-2)
end

------------------
---music tracks---
------------------

music_tracks={
 bass_2bars={i=8,o=0,l=32},
 bass_4bars={i=9,o=0,l=32},
}

-->8
--screens

---------------
---main title--
---------------

function init_title_screen()
 return {
  
 }
end

---------------
---game over---
---------------
__gfx__
000000000000000000000000006666000000000000000000000000000000000000000000000000000057777777000000d777777dddddddddddddddddd566667d
00000000006666000066660006611c60006666000000000000666600000000000000000000000000057bbbbbbb70000076666667ddddddddddddddddd566667d
0070070006611c6006611c600661116006611c600066660006611c6000000000000000000000000057bbbbbbbbb70000d555555dddddadddddddddddd566667d
000770000661116006611160006666000661116006611c600661116000000000000000000000000057bbbbbbbbb70000dddddddddddaaddddddd667dd561617d
0007700000666600006666000088a80000666600066111607766660000000000000000000000000057bbbbbbbbb70000dd9dd9ddddaaa9dddddd8e6dd516167d
007007000088a8000088a800008888000088a800006666007788a80000000000000000000000000057bbbbbbbbb700007dd99ddd7dda9ddd7ddd886d7566667d
00000000008888000088880006000060068888000088a8000a88880000000000000000000000000057bbbbbbbbb70000d7ddddddd7d9ddddd7dd666dd766667d
00000000006006000060006000000000000006000688886090600600000000000000000000000000057bbbbbbb7000007d7ddddd7d7ddddd7d7d666d7576667d
0000000000000000000000000000000000000000000000000000000000000000000000000000000000577bbb7700000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000777777000000000000557b70000000000000000000000000000000000000000
0000000000000000000000000000a0000000a0000000a00000009000000000077666666770000000000005700000000000000777777770000000000000000000
000066700000667000006670000aa000000aa000000a90000009a000000006666666566667700000000000000000000000077777777777777700000000000000
00003b6000009a6000008e6000aaa90000aa9a0000a9aa00009aaa00000066666666666666670000000000000000000000777676767677777777777000000000
000033600000996000008860000a90000009a000000aa000000aa000000666666666666666667000000000000000000007776766676666666666666777000000
00006660000066600000666000090000000a0000000a0000000a00000006666655766666d6667000000000000000000077767676666666666666666666700000
000066600000666000006660000000000000000000000000000000000066666d55d6667666666700000000000000000007676666666666666666666666670000
05666670056666700566667005616170001010000000000000000000006dd66dddd6665666666700000000000000000000767666666666655555555666667000
05666670056666700561617000101000000000000000000000000000066dd666dd666666666566700000007777000000000666666666667dddddddd566666700
056666700561617000101000000000000000000000000000000000000666666666666666666666700000776666770000000099999999997dd6666dd5999999a0
0561617000101000000000000000000000000000000000000000000006666666666666ddd6666d700006666665667000000066666666667d6611c6d566666667
051616700001010000000000000000000000000000000000000000000665666666666d555d66d5600065667766d66700000099999999997d661116d599999994
05666670051616700001010000000000000000000000000000000000066666d66666d55555d6d56000666d5d66676700000099999999997dd6666dd599999940
056666700566667005161670000101000000000000000000000000000d6666666666d55555d6666006d56dd666666670000666666666667dd33b3dd566666500
0566667005666670056666700516167000010100000000000000000000d556667666d55555d6660006dd66666dd66d7000565666666666677777777666665000
0777777007777770077777700777777000000000000000000000000000dd5566d7666d555d666d0006666666d55d667005656666666666666666666666650000
56666667566666675666666756666667000000000000000000000000000dd566666566ddd666d0000d666d66d55d666055565656666666666666666666500000
05555550055555500555555005555550000000000000000000000000000ddd66666666666666d00000d566666dd6660005556566656666666666666555000000
090000900000000000000000009999000000000000000000000000000000ddd66666666666dd000000dd566766666d0000555656565655555555555000000000
0099990000900900000000000000000000000000000000000000000000000ddd66666666ddd00000000dd666666dd00000055555555555555500000000000000
000000000009900000000000000000000000000000000000000000000000000dddddddddd00000000000dddddddd000000000555555550000000000000000000
00000000000000000009900000000000000000000000000000000000000000000dddddd000000000000000dddd00000000000000000000000000000000000000
00000000000000000000000000099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd7777777dd566667ddd777777777777dddddddddddddddddddddddddd777777777766667dd55555555555555dd555555ddddddddddddddddddddddddd
dddddddd66666667d566667dd56666666666667dddddddddd555555ddddddddd666666666666667d611111111111111561111115ddd555555555555555555ddd
dddddddd66666667d566667dd56666666666667dddddddd550c000c55ddddddd666666666666667961ccccc11c11111561ffff45dd50000000000000000005dd
dddddddd66666667d566667dd56666666666667dddddd55000000000055ddddd666666666666667f611111111cc1c11561111115d6000000000000000000005d
dddddddd66666667d566667dd56666666666667ddddd50002000c000c005dddd666666666666667961ccc1c11cc1cc15614441f5d6000000000000000000005d
dddddddd5555555dd566667dd56666655666667dddd600000000000000005ddd555555555666667d611111111ccccc1561111115d6000000000000000000005d
ddddddddddddddddd566667dd566667dd566667dddd600c000b000c000205ddddd9f9dddd566667d61c1ccc11111111561f14445d6000000000000000000005d
ddddddddddddddddd566667dd566667dd566667ddd60000000000000000005dddd9f9dddd566667dd66666666666666dd666666dd6000000000000000000005d
77777777d7777777d566667dd56666677666667ddd60c000c0002000c000c5dddd949dddd5666677d55555555555555dd555555dd6000000000000000000005d
6666666656666666d566667dd56666666666667dd6000000000000000000005ddd949dddd566666661111cc11cc1111561111ff5d6000000000000000000005d
6666666656666666d566667dd56666666666667dd6b000c000c000c000c0005d994449999566666661cc111111111cc561441115d6000000000000000000005d
6666666656666666d566667dd56666666666667dd6000000000000000000005d44444444f56666666111c1c11111c11561114145d6000000000000000000005d
6666666656666666d566667dd56666666666667dd600c000c000c0002000b05d994449999566666661c1c1111c11c11561f14115d6000000000000000000005d
55555555d5555555d566667ddd555555555555ddd6000000000000000000005ddd949dddd5666665611111c1c1cc111561111145d6000000000000000000005d
dddddddddddddddddd5555ddddddddddddddddddd6c00020002000c000c0005ddd949dddd566667d61ccc1c11111111561fff145d6000000000000000000005d
dddddddddddddddddddddddddddddddddddddddddd60000000000000000005dddd949dddd566667dd66666666666666dd666666dd6000000000000000000005d
777777777766667dddddddddddddddddd5666670dd60c000c000c0002000c5ddd566667dddddddddddddddddddddddddddddddddd6000000000000000000005d
666666666666667ddd7777ddddddddddd566667cddd600000000000000005dddd566667dddddddddddddddddddddddddddddddddd6000000000000000000005d
666666666666667dd566667dddddddddd5666670ddd600c000c0002000c05ddd9566667d9999999999999999ddd999999999ddddd6000000000000000000005d
666666666666667dd566667dddddddddd5666670dddd6000000000000006dddd4566667dfffff4444ffff4f4dd94444ff4449dddd6000000000000000000005d
666666666666667dd566667dddddddddd5666670ddddd660b000c000c66ddddd9566667d9999999999999999dd9ff99999f49dddd6000000000000000000005d
566666655666667dd566667dddddddddd5666676ddddddd6600000066dddddddd566667ddddddddddddddddddd9f9ddddd9f9ddddd60000000000000000005dd
d566667dd566667dd566667dddddddddd566667dddddddddd666666dddddddddd566667ddddddddddddddddddd9f9ddddd9f9dddddd666666666666666666ddd
d566667dd566667dd566667dddddddddd566667dddddddddddddddddddddddddd566667ddddddddddddddddddd949ddddd9f9ddddddddddddddddddddddddddd
77666677d5666677ddddddddddddddddd566667dd5666670777777770566667dd566667ddd9f9ddddd949ddddd949ddddd9f9ddddddddddddddddddd00000000
66666666d5666666ddddddddddddddddd566667dd566667c666666660566667dd566667ddd9f9ddddd949ddddd9f9ddddd949ddddddddddddddddddd00000000
66666666d5666666ddddddddddddddddd5666675d5666670666666660566667dd5666679dd949ddddd949ddddd9f499999449ddddd555555555555dd00000000
66666666d5666666ddddddddddddddddd5666670d5666670666666660566667dd566667fdd949ddddd949ddddd9f44fff44f9dddd61111111111115d00000000
66666666d5666666ddddddddddddddddd5666670d566667066666666c566667dd5666679dd9f9ddddd9f9dddddd999999999ddddd61555555555515d00000000
55555555d5666665ddddddddddddddddd5666670d5666670555555550566667dd566667ddd949ddddd9f9dddddddddddddddddddd61111111111115d00000000
ddddddddd566667dddddddddddddddddd5666670d5666670cc0c0cc00566667dd566667ddd9f9ddddd949dddddddddddddddddddd61555555555515d00000000
ddddddddd566667dddddddddddddddddd5666670d566667c000000000566667dd566667ddd9f9ddddd949dddddddddddddddddddd61111111111115d00000000
0e0e00000e0e0e00d566667dd566667d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0ee0000e0e0eeeed56666755566667d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0ee00000ee0eeeed56666700566667d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee00e000ee0ee00ed566667c0566667d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee0e000ee00e000d56666700566667d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee0e0000e0e0ee00d56666700566667d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eee0e000eeeeeeed5666670c566667d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e00ee0000e00ee0ed56666700566667d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eee0e00ee00eeeedddddddd555ddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee0e0000eeeee000ddd55d5500055ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0ee00000e00ee00dd600500000005dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee0ee0000e0ee000dd60cc0c0cc0c5dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeee000ee0ee0e00d6000000000005dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee0ee0eee0eeee00600000000000005d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeee0e0eeee00e006c0c0cc0c0cc0c05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeee00e0e0ee0000600000000000055d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee0ee0e0e0eeee00d600000000005ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e00e0ee00e0eee00d6c0cc0c0cc0c5dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e000e000e000eeeedd6000000000005d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0ee0e00e0e0e00eddd600000000005d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee0e0000e0e00e0dddd66c0c0cc0cdd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0eee000e0e0ee00dddddd6600005ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeee0000e0eee00dddddddd6666dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0ee0000e0eee000dddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000006000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000070000000000
00000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000007000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700
00000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000007000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000
06000000000000000000000000000070007000000000000000000000000000007000000000000000000000000070000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000700000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000070000000000000000007000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000070000000000000000700000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000700700000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000060000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000
00666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06611d60000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000
06611160000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000
00666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbfb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000
00600600000000000000000000000000000000000000000000000000000000000000066660000000000000000000007000000000000000000000000000000000
d00000000000000000000000000000000000000000000000000000000000000000006611c600000000000000000000000000000000000000000000000000000d
56000000000000000000000000000000000000000000000000000000000000000000661116000000000007000000000000000000000000000000000000000056
5d6000000000000000000000000000000000000000000000000000000000000000000666600000000000000000000000000000000000000000000000000005d6
5dd60000000000000000000000000000000000000000000000000000000000000000088a80000000000000000000000000000000000000000000000000005dd6
5ddd600000000000000000000000000000000000000000060000000000000000000008888000000700000000000000000000000000000000000000000005ddd6
5dddd6000000000000000000000000000000000000000000000000000000000000006000060000000000000000000000000000000000000000000000005dddd6
5ddddd60000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005ddddd6
5555555d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d555555d
d66666660000006000000000000000000000000007000000000000000000000000000000000070000000000000000000000000000000000000000000d6666666
5dddddd600000000000000000000000000000000000000000000000000000090000000000000000000000000000700007000000000000000000070005dddddd6
5dddddd600000000000000000000000000000000000000000000000000000999000000000000000000000000000000000000000000000000000000005dddddd6
5dddddd60000000000000000000000000000000000000000000000000000aa99090000000000000000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000000000000000005000a99999000000000000000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000000000000006055500999090000000000000000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000000000000000005000090000000000000000000000000000000000000000000000000000000005dddddd6
5555555d00000000000000000000000000000000000000000000000000000000000000000000000000000007007000000000000000000000000000005555555d
d66666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d6666666
5dddddd600000000000700000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000000000000006000000000000000700000000000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000007000700000000000000000000000000000000000000000000000000000000000000000000005dddddd6
5555555d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555d
d6666666000000000000000000000000000000000000000000000000000000000000000dd00000000000000000000000000000000000000000000000d6666666
5dddddd600000000000000000000000000000000000000000000000000000000000000565600000000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000000000000000000000000000005d65d60000000000000000000000000000000000000000000005dddddd6
5dddddd60000000000000060000000000000000007000000000000000000000000005dd65dd6000070000000000000000000000000000000000000005dddddd6
5dddddd6000000000000000000000600000000000000000000000000000000000005ddd65ddd600000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000700000000000000000000000000000000000000005dddd65dddd60000000000000000000000000000000000000000005dddddd6
5dddddd60000000000000000000000000000000000000000000000000000000005ddddd65ddddd6000000000000000000000000000000000000000005dddddd6
5555555d00000000000000000000000000000000000000000000000000000000d555555d5555555d00000000000000000700000000000000000000005555555d
d66666660000000000000000d666666600000000000000000000000000000000d6666666d66666660000000000000000000000000000000000000000d6666666
5dddddd600000000600000005dddddd6000000000000000000000000000000005dddddd65dddddd600000000000000000000000000000000000000005dddddd6
5dddddd600000000000000005dddddd6000000000000000000000000000000005dddddd65dddddd600000000000000000000000000000000000000005dddddd6
5dddddd600000000000000005dddddd6000000000000000000000000000000005dddddd65dddddd600000000000000000000000000000000000000005dddddd6
5dddddd600000000000000005dddddd6000000000000000000000000000000005dddddd65dddddd600000000000000000000000000000000000000005dddddd6
5dddddd600000000000000005dddddd6000000000000000000000000000000005dddddd65dddddd600000000000000000000000000000000000000005dddddd6
5dddddd600000000000000005dddddd6000000000000000000000000000000005dddddd65dddddd600000000000000000000000000000000000000005dddddd6
5555555d00000000000000005555555d000000000000000000000000000700005555555d5555555d00000000000000000000000000000000000000005555555d
d66666660000000006000000d666666600000000d6666666000000000000000dd6666666d6666666d000000000000000000000000000000000000000d6666666
5dddddd600000000000000005dddddd6000000005dddddd600000000000000565dddddd65dddddd656000000000000000000000000000000000000005dddddd6
5dddddd600000000000000005dddddd6000000005dddddd600000000000005d65dddddd65dddddd65d600000000000000000000000000000000600005dddddd6
5dddddd600000000000000005dddddd6000000005dddddd60000000000005dd65dddddd65dddddd65dd60000000000000000000000000000000000005dddddd6
5dddddd600000000000000005dddddd6000000005dddddd6000000000005ddd65dddddd65dddddd65ddd6000000000000000000000000000000000005dddddd6
5dddddd600000000000000005dddddd6000000005dddddd600000000005dddd65dddddd65dddddd65dddd600000000000000000000000000000000005dddddd6
5dddddd600000000000000005dddddd6000000005dddddd60700000005ddddd65dddddd65dddddd65ddddd60000070000000000000000000000000005dddddd6
5555555d00000000000000005555555d000000005555555d00000000d555555d5555555d5555555d5555555d700000000000000000000000000000005555555d
d666666600000000d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d66666660000000000000000d6666666
5dddddd6000000005dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd600000000000000005dddddd6
5dddddd6000000005dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd600000000000000005dddddd6
5dddddd6000000005dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd600000000000000005dddddd6
5dddddd6000000005dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd600000000000000005dddddd6
5dddddd6000000005dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd600000000000000005dddddd6
5dddddd6000000005dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd600000000000000705dddddd6
5555555d000000005555555d5555555d5555555d5555555d5555555d5555555d5555555d5555555d5555555d5555555d5555555d00000000000000005555555d
d66666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d6666666
5dddddd600000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005dddddd6
5dddddd600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005dddddd6
5555555d00000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000070005555555d
d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666d6666666
5dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd6
5dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd6
5dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd6
5dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd6
5dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd6
5dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd65dddddd6
5555555d5555555d5555555d5555555d5555555d5555555d5555555d5555555d5555555d5555555d5555555d5555555d5555555d5555555d5555555d5555555d

__gff__
0000000000000000000000000000000001010101010101000000000000000000010101010000000000000000000000000101010100000000000000000000000000010100000002010101000000000000010101000000000101010000000000000101010000000000000000000000000001010000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
424040404040404040404040404040404040404040404040404040404040406240404040404040404040404040404040400d0d0d0d0d0d40435050505050505050504440404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
424040404040404040404040404040404040404040404040404040404040404240404040404040404040404040404040400d0d0d0d0d0d40424d4e4f4040404040404240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
424040404040404040404040404040404040404040404040404040404051606050505050505050505050506041404040400d0d0d0d0d0d40425d5e5f4040404040404240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
424040404040404040404040404040404040404040404040404040404040424240404045454d4f4545404042404040405150505050505050615d5e5f40404040400e4240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
424040404040404040404040404040404040404040404040404040404040427141404040456d6f454040404240400c404d4e4e4e4e4e4e4f425d5e5f4051485050506140404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
42404040404040405a4b404040404040404040404040404040404040515061424a5b40404540404040404052404040406d6e6e6e6e6e6e6f426d6e6f40407b5c6a4c6840404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4240404040404040404040404040404040404040404040404040404040404242404045404545454545454040404040404040404040404040404040404040404040404240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
5050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505440404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
__sfx__
00070008006150000000000046000f615000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000a7110a7110e711127111a711227110c7000070000700007000070004700037000370003700037000370000700007000070000700007000f70013700177001b7001b7001a70012700107000070000700
011000001361510615006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011000000473404721047110070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
011000000071400721007310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00200402004020040101b000040200402004010040000400004000040200402105020050210b0200b0210400004000040000400004000040000c0000c0000c0000b0000b0000c0000c0000c0000000000000
010a002004020040200401000000040200402004010000000000000000040200402105020050210b0200b02100000000000b0200b0200c0200c0200b0200b0200c0200c0200b0200b02007020070210402104001
