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

sp_platform=48

sp_door_opened=36
sp_door_closed=32

sp_button_on=16
sp_button_off=18

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
  59*8,26*8,8,8
  linear_delta_fn(
   --59,26 <-> 59,29
   59*8,26*8,59*8,29*8
  )
 )
 local plt4=init_platform(
  57*8,24*8,8,8,
  linear_delta_fn(
   --57,24 <-> 57,29
   57*8,24*8,57*8,29*8
  )
 )

 --doors
 --x,y,open
 local door0=init_door(
  12*8,12*8,false
 )

 --buttons
 --x,y,on
 local btn0=init_button(
  12*8,14*8,false,
  door_toggle_fn(door1)
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
   ⬆️=double_jump
  },
  init_player{
   ⬆️= glide,
   color_map={8,11,10,15,12,13}
  },
  init_player{
   ⬆️=grav_boots,
   color_map={1,0,12,5,8,9},
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
 if btnp(❎) then
   add(
     all_players,
     deli(all_players, #all_players),
     1
   )
 end
 if btnp(🅾️) then
  if path.found then
   path:apply()
  else
   path:find(unpack(all_players))
  end
 end

 --players
 --path:update()
 foreach(all_players, update_player)

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

function player() return all_players[#all_players] end

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
    mid(0,c.x-64,960),
    mid(0,c.y-64,128)
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

--collisions for p
function collision(p,flag)
 --[[
 obj={x,y,w,h}
 flag=<sprite flags above>
 --]]

 local hb={
  x=p.x+1,--+1=left pad
  y=p.y+1,--+1=top pad
  w=p.w-2,---2=horizontal pad
  h=p.h-1,---1=vertical pad
 }

 return collision_plt(hb,flag)
 or collision_map(hb,flag)
end

collidables = {}
function collision_plt(hb,flag)
 for plt in all(collidables) do
  if intersects(plt,hb)
  and fget(plt.sp,flag) then
   return plt
  end
 end
end

function collision_map(
 hb,flag
)
 local x1=hb.x
 local x2=hb.x+hb.w-1
 local y1=hb.y
 local y2=hb.y+hb.h-1

 return flag_on_xy(x1,y1,flag)
 or flag_on_xy(x1,y2,flag)
 or flag_on_xy(x2,y1,flag)
 or flag_on_xy(x2,y2,flag)
end

function expel_x(e, p)
 if p.dx<-0 then
  --left (-1 to pad sprite)
  p.x+=e.x+e.w-p.x-1
 elseif p.dx>0 then
  --right (+1 to pad sprite)
  p.x+=e.x-p.x-p.w+1
 end
 p.dx=0
end

function expel_y(e, p)
 if p.dy<-0 then
  --top (-1 to pad sprite)
  p.y+=e.y+e.h-p.y-1
 elseif p.dy>0 then
  --bottom
  p.y+=e.y-p.y-p.h
 end
 if (e.dx) p.x+=e.dx
 if (e.dy) p.y+=e.dy
 p.dy=0
end

function flag_on_xy(x,y,flag)
 if fget(mget(x/8,y/8),flag)
 then
  return {
   x=x\8*8,
   y=y\8*8,
   w=8,
   h=8,
   dx=0,
   dy=0,
   collide_x=expel_x,
   collide_y=expel_y
  }
 else
  return nil
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
  landed=false,

  sp=sp_player_idle,
  flpx=false,
  flpy=false,

  ⬅️=run_left,
  ➡️=run_right,
  ⬆️=glide,
 }, p)
end

function update_player(p)
 local hcl,vcl

 --move horizontally
 p.dx*=inertia
 p.dx=clamp(p.dx,p.max_dx,0x.08)
 if p.dx!=0 then
  p.x+=p.dx
  hcl=collision(p,flag_hits)
  if hcl then
    hcl:collide_x(p)
  end
 end

 --move vertically
 if p.flpy then
  p.dy-=gravity
 else
  p.dy+=gravity
 end
 p.dy=clamp(p.dy,p.max_dy,0x.08)
 if p.dy!=0 then
  p.y+=p.dy
  vcl=collision(p,flag_hits)
  if vcl then
   vcl:collide_y(p)
  end
 end

 --state
 p.running=p.running and
  abs(p.dx)>0.5
 p.landed=p.falling and vcl!=nil
 if p.landed then
  p.falling=false
  p.jumping=false
  p.gliding=false
 else
  p.falling=p.dy>=0.5
  if p.falling then
   p.jumping=false
   p.gliding=false
  end
 end

 --sprite
 if p.gliding then
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

 if not p.jumping
 and not p.falling then
  p.dy=-jump_accel
  play_sfx("jump")
  p.jumping=true
  p.landed=false
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
  p.jumping=false
  p.falling=false
  jump(p,true)
  p._j=nil
 end
end

function glide(p,_)
 if not p.gliding
 and not p.jumping
 and not p.falling
 then
  jump(p,true)
  return
 end

 if not p.gliding
 and p.dy<0 then
  return
 end

 p.gliding=true
 p.dy-=gravity+0.25
end

function draw_player(p)
 if p.color_map then
   for i=1,#p.color_map,2 do
    pal(
     p.color_map[i],
     p.color_map[i+1]
    )
   end
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
   elseif aim=="⬅️" or aim=="➡️"
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
  sp=sp_platform,
  x=x,
  y=y,
  w=w,
  h=h,
  dx=0,
  dy=0,
  
  delta_fn=delta_fn,
  
  collide=function(p,o)
   local aim=block(p,o)
   if aim=="⬇️" then
    o.x+=p.dx
    o.y+=p.dy
   end
  end,

  update=function(p)
   if (p.delta_fn) p:delta_fn()
   p.x+=p.dx
   p.y+=p.dy
  end,

  draw=function(p)
   spr(p.sp,p.x,p.y,1,1)
  end,
 }
end

function linear_delta_fn(
 x,y,to_x,to_y
)
 local dx,dy=to_x-x,to_y-y
 return function(plat)
  local f=ef_smooth(
   abs(time()%6-3)/3
  )
  plat.dx=x+dx*f+0.5-plat.x
  plat.dy=y+dy*f+0.5-plat.y
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
  open=open,

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
 x,y,on,toggle_fn
)
 local sp
 if on then
  sp=sp_button_on
 else
  sp=sp_button_off
 end
 return {
  sp=sp,
  x=x,
  y=y,
  w=8,
  h=8,
  on=on,
  was_colliding=false,
  toggle_fn=toggle_fn,

  update=function(b)
   local is_coll = false
   for i=1,#all_players do
     is_coll = is_coll or intersects(all_players[i],b)
   end
   if is_coll and not b.was_colliding then
    on = not on
   end
   b.was_colliding = is_coll

   if on
   and b.sp!=sp_button_on
   then
    b.sp=sp_button_on
    toggle_fn(on)
   end
   if not on
   and b.sp!=sp_button_off
   then
    b.sp=sp_button_off
    toggle_fn(on)
   end
  end,

  draw=function(b)
   spr(b.sp,b.x,b.y,1,1)
  end,
 }
end

function door_toggle_fn(d)
 return function(on)
  d.open=on
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
   if p.gliding then
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

light_masks={2,4,15}
light_freqs={
 [2]=3,
 [4]=7,
 [15]=11,
}
light_seqs={
 [2]={8,9,12,1},
 [4]={8,9,12,1},
 [15]={8,9,12,1},
}

function animate_lights()
 for m in all(light_masks) do
  local f=light_freqs[m]
  local s=light_seqs[m]
  local c=mid(
   0,
   abs(cos(t()/f))*#s\1,
   #s-2
  )

  if c<0 or c>4 then
   printh(m.."/"..c)
  end

  pal(m,s[c+1])
 end
end
-->8
--path

path={
 npc=nil,
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
  self,npc,from,to,grid
 )
  self.npc=npc

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
   move_npc(
    self.npc,
    unpack(pop(self.btns))
   )
  else
   self:clear()
  end
 end,

 --expand n by moving it
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
    --npc data
    x=n.x,
    y=n.y,
    w=n.w,
    h=n.h,
    dx=n.dx,
    dy=n.dy,
    max_dx=n.max_dx,
    max_dy=n.max_dy,

    --npc btns functions
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

    local bounds={
     x=0,y=0,w=128,h=128
    }
    if contains(bounds,cur)
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
--there are 16x16 map tiles
--which are 8x8 pixels wide
function vec2i(v,grid)
 return 1+
  (v.x\grid)+
  (128/grid)*(v.y\grid)
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

__gfx__
000000000000000000000000006666000000000000000000000000000000000000000000000000000000000000000000d777777dddddddddddddddddd566667d
00000000006666000066660006611c60006666000066660000000000000000000000000000000000000000000000000076666667ddddddddddddddddd566667d
0070070006611c6006611c600661116006611c6006611c60000000000000000000000000000000000000000000000000d555555dddddadddddddddddd566667d
000770000661116006611160006666000661116006611160000000000000000000000000000000000000000000000000dddddddddddaaddddddd667dd561617d
0007700000666600006666000088a8000066660077666600000000000000000000000000000000000000000000000000dd9dd9ddddaaa9dddddd8e6dd516167d
007007000088a8000088a800008888000088a8007788a800000000000000000000000000000000000000000000000000ddd99dddddda9ddddddd886dd566667d
00000000008888000088880006000060068888000a888800000000000000000000000000000000000000000000000000ddddddddddd9dddddddd666dd566667d
000000000060060000600060000000000000060090600600000000000000000000000000000000000000000000000000dddddddddddddddddddd666dd566667d
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000a0000000a0000000a00000009000000000000000000000000000000000000000000000000000000000000000000000000000
000066700000667000006670000aa000000aa000000a90000009a000000000000000000000000000000000000000000000000000000000000000000000000000
00003b6000009a6000008e6000aaa90000aa9a0000a9aa00009aaa00000000000000000000000000000000000000000000000000000000000000000000000000
000033600000996000008860000a90000009a000000aa000000aa000000000000000000000000000000000000000000000000000000000000000000000000000
00006660000066600000666000090000000a0000000a0000000a0000000000000000000000000000000000000000000000000000000000000000000000000000
00006660000066600000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666670056666700566667005616170001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666670056666700561617000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000700000
05666670056161700010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666701c77000
05616170001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666701ccc770
05161670000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666701ccccc7
05666670051616700001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666000ccccc7
05666670056666700516167000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011110
05666670056666700566667005161670000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0777777007777770077777700777777000000000000000000000000000000000000000000000000000000000000000000000000000000000944494445ddd5ddd
766666677666666776666667766666670000000000000000000000000000000000000000000000000000000000000000000000000000000044494449ddd5ddd5
05555550055555500555555005555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090000900000000000000000009009000000000000000000000000000000000000000000000000000000000000000000000000000000000044544454dd5ddd5d
009999000090090000000000000990000000000000000000000000000000000000000000000000000000000000000000000000000000000045444544d5ddd5dd
00000000000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd7777777dd566667dddddddddddddddddddddddddddddddddd566667d777777777766667dd66666666666666dd666666ddddddddddddddddddddddddd
dddddddd66666667d566667dddddddddddddddddddddddddddddddddd566667d666666666666667d611111111111111661111116ddd666666666666666666ddd
dddddddd66666667d566667ddddddddddddddddddddddddddddddddd9566667d666666666666667961ccccc11c11111661ffff46dd65555555555555555556dd
dddddddd66666667d566667ddddddddddddddddddddddddddddddddd4566667d666666666666667f611111111cc1c11661111116d6500000000000000000056d
dddddddd66666667d566667ddddddddddddddddddddddddddddddddd9566667d666666666666667961ccc1c11cc1cc16612221f6d6500000000000000000056d
dddddddd5555555dd566667dddddddddddddddddddddddddddddddddd566667d555555555666667d611111111ccccc1661111116d6500000000000000000056d
ddddddddddddddddd566667dddddddddddddddddddddddddddddddddd566667ddd9f9dddd566667d61c1ccc11111111661f14446d6500000000000000000056d
ddddddddddddddddd566667dddddddddddddddddddddddddddddddddd566667ddd9f9dddd566667dd66666666666666dd666666dd6500000000000000000056d
77777777d7777777d566667dddddddddddddddddddddddddddddddddd566667ddd949dddd5666677d66666666666666dd666666dd6500000000000000000056d
6666666656666666d566667dddddddddddddddddddddddddddddddddd566667ddd949dddd566666661111cc11cc1111661111ff6d6500000000000000000056d
6666666656666666d566667dddddddddddddddddddddddddddddd9add5666679994449999566666661cc111111111cc661441116d6500000000000000000056d
6666666656666666d566667ddddddddddddddddddddddddddddd9addd566667244444444256666666111c1c11111c11661114126d6500000000000000000056d
6666666656666666d566667dddddddddddddddddddddddddddd9adddd5666679994449999566666661c1c1111c11c11661214116d6500000000000000000056d
55555555d5555555d566667ddddddddddddddddddddddddddddd9addd566667ddd949dddd5666665611111c1c1cc111661111146d6500000000000000000056d
dddddddddddddddddd5555ddddddddddddddddddddddddddddddd9add566667ddd949dddd566667d61ccc1c11111111661fff146d6500000000000000000056d
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd566667ddd949dddd566667dd66666666666666dd666666dd6500000000000000000056d
777777777766667ddddddddddddddddddddddddddddddddddddddddddd9f9ddddd9f9dddddddddddddddddddddddddddddddddddd6500000000000000000056d
666666666666667ddd7777dddddddddddddddddddddddddddddddddddd9f9ddddd9f9dddddddddddddddddddddddddddddddddddd6500000000000000000056d
666666666666667dd566667ddddddddddddddddddddddddddddddddddd9ff99999ff9ddd9999999999999999ddd999999999ddddd6500000000000000000056d
666666666666667dd566667ddddddddddddddddddddddddddddddddddd9fffffffff9dddff2224444fff2424dd92444224449dddd6500000000000000000056d
666666666666667dd566667ddddddddddddddddddddddddddddddddddd9ff99999ff9ddd9999999999999999dd9ff99999229dddd6500000000000000000056d
566666655666667dd566667ddddddddddddddddddddddddddddddddddd9f9ddddd9f9ddddddddddddddddddddd9f9ddddd929ddddd65555555555555555556dd
d566667dd566667dd566667ddddddddddddddddddddddddddddddddddd9f9ddddd9f9ddddddddddddddddddddd9f9ddddd9f9dddddd666666666666666666ddd
d566667dd566667dd566667ddddddddddddddddddddddddddddddddddd9f9ddddd9f9ddddddddddddddddddddd929ddddd9f9ddddddddddddddddddddddddddd
77666677d5666677dddddddddddddddddddddddddddddddddddddddddd949ddddddddddddd9f9ddddd949ddddd929ddddd9f9ddddddddddddddddddddddddddd
66666666d5666666dddddddddddddddddddddddddddddddddddddddddd949ddddddddddddd929ddddd949ddddd9f9ddddd929ddddd66666666666666666666dd
66666666d5666666dddddddddddddddddddddddddddddddddddddddd9944499999999999dd949ddddd949ddddd92499999429dddd6555555555555555555556d
66666666d5666666dddddddddddddddddddddddddddddddddddddddd4444444444444444dd949ddddd949ddddd9424fff44f9dddd6500000000000000000056d
66666666d5666666dddddddddddddddddddddddddddddddddddddddd9999999999444999dd929ddddd929dddddd999999999ddddd6500000000000000000056d
55555555d5666665dddddddddddddddddddddddddddddddddddddddddddddddddd949ddddd949ddddd9f9dddddddddddddddddddd6555555555555555555556d
ddddddddd566667ddddddddddddddddddddddddddddddddddddddddddddddddddd949ddddd9f9ddddd929ddddddddddddddddddddd66666666666666666666dd
ddddddddd566667ddddddddddddddddddddddddddddddddddddddddddddddddddd949ddddd9f9ddddd929ddddddddddddddddddddddddddddddddddddddddddd
77777777717171717777777771717171000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666616161616666666661616161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddd1d1d1d1ddddddddd1d1d1d1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddddddddddd16dd16dd16dd16d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddddddddddd11dd11dd11dd11d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd67dddddd67dddddd67dddddd67000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd67ddddd111dd16dd67dd16d111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd67dddddd67dd11dd67dd11dd67000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd67ddddd111dddddd67ddddd111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd67dddddd67dddddd67dddddd67000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd67ddddd111dd16dd67dd16d111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd67dddddd67dd11dd67dd11dd67000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd67ddddd111dddddd67ddddd111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111ddddd76dddddd111ddddd76dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76dd11dd76dd11dd76dddddd76dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111d61dd76dd61dd111ddddd76dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76dddddd76dddddd76dddddd76dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111ddddd76dddddd111ddddd76dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76dd11dd76dd11dd76dddddd76dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111d61dd76dd61dd111ddddd76dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76dddddd76dddddd76dddddd76dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd6776dddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd6666dddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddd6666dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddd6776dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7555d557755d1d5775d111d771111117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
755d555775d1d5577d111d5771111117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7555d557755d1d5775d111d771111117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
755d555775d1d5577d111d5771111117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7555d557755d1d5775d111d771111117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
755d555775d1d5577d111d5771111117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7555d557755d1d5775d111d771111117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
755d555775d1d5577d111d5771111117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000000000001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000010100000002000101000000000000010101000000000001010000000000000101010000000000000000000000000001010000000000000000000000000000
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
424040404040404040404040404040404040404040404040404040404040406240404040404040404040404040404040400d0d0d0d0d0d40424040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
424040404040404040404040404040404040404040404040404040404040404240404040404040404040404040404040400d0d0d0d0d0d40715050505050506040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
424040404040404040404040404040404040404040404040404040404051606050505050505050505050506041404040400d0d0d0d0d0d40424d4f404040404240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
424040404040404040404040404040404040404040404040404040404040424240404045454d4f4545404042404040405150505050505050615d5f4040400e4240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
424040404040404040404040404040404040404040404040404040404040427141404040456d6f454040404240400c404d4e4e4e4e4e4e4f425d5f405148506140404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
42404040404040405a4b404040404040404040404040404040404040515061424a5b40404540404040404052404040406d6e6e6e6e6e6e6f426d6f0c407b5c4740404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
42404040404040404040404040404040404040404040404040404040404042424040454045454545454540404040404040404040404040400f4040404040404240404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
5050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
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
