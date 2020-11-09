pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--[[readme

# todo

--level
--particle systems
--better collisions
--double jump?
--follower
--large levels?
----camera
--cleanup/optim code sections
--use map flag to pick start x,y

]]

-->8
--globals

--gravity
g=0.2
--acceleration
a=1.1
--inertia
i=0.8

--have super extend kls
function class(super,kls)
 kls.meta={__index=super}
 return setmetatable(
  kls,kls.meta
 )
end

function handle_input(obj)
 --[[
  obj={⬅️,➡️,⬆️,⬇️,🅾️,❎}
 ]]
 --button index=number+1
 --https://pico-8.fandom.com/wiki/btn
 btns={
  "⬅️","➡️","⬆️","⬇️","🅾️","❎"
 }
 for i=1,#btns do
  if btn(i-1) then
   h=obj[btns[i]]
   if h then
    h(obj,btnp(i-1))
   end
  end
 end
end

--check if obj collides with map
function collide_map(
 obj,aim,flag
)
 --[[
 obj={x,y,w,h}
 aim=⬅️,➡️,⬆️,⬇️
 flag=
  0-stands on (eg: floor)
  1-bumps into (eg: wall)
 ]]

 local x=obj.x
 local y=obj.y
 local w=obj.w
 local h=obj.h

 local x1=0
 local y1=0
 local x2=0
 local y2=0

 if aim=="⬅️" then
  x1=x-1
  y1=y
  x2=x
  y2=y+h-1
 elseif aim=="➡️" then
  x1=x+w-1
  y1=y
  x2=x+w
  y2=y+h-1
 elseif aim=="⬆️" then
  x1=x+2
  y1=y-1
  x2=x+w-3
  y2=y
 elseif aim=="⬇️" then
  x1=x+2
  y1=y+h
  x2=x+w-3
  y2=y+h
 end

 --pixels to tiles
 x1/=8
 y1/=8
 x2/=8
 y2/=8

 return fget(mget(x1,y1),flag)
 or fget(mget(x1,y2),flag)
 or fget(mget(x2,y1),flag)
 or fget(mget(x2,y2),flag)
end

-->8
--loop

function _init()
 p=init_player()
 npcs={}
 add(npcs,init_npc(
  jump,
  {1,0,12,5,8,9}
 ))
 add(npcs,init_npc(
  glide,
  {8,11,10,15,12,13}
 ))
 init_fxs()
end

function _update60()
 handle_input(p)
 update_player(p)
 for i=1,#npcs do
  update_npc(npcs[i])
 end
 update_fxs()
end

function _draw()
 cls()
 map(0,0)
 draw_fxs()
 for i=1,#npcs do
  draw_npc(npcs[i])
 end
 draw_player(p)

 --print debug if set
 if debug then print(debug) end
end
-->8
--entity

function init_entity(
 w,h,max_dx,max_dy
)
 return {
  x=0,
  y=0,
  w=w,
  h=h,
  dx=0,
  dy=0,
  max_dx=max_dx,
  max_dy=max_dy,
 }
end

function update_entity(e)
 --gravity/inertia
 e.dy+=g
 e.dx*=i

 --vertical map collisions
 if e.dy>0 then
  if collide_map(e,"⬇️",0) then
   e.dy=0
   e.y-=((e.y+e.h+1)%8)-1
  end
 elseif e.dy<0 then
  if collide_map(e,"⬆️",1) then
   e.dy=0
  end
 end

 --horizontal map collisions
 if e.dx<0 then
  if collide_map(e,"⬅️",1) then
   e.dx=0
  end
 elseif e.dx>0 then
  if collide_map(e,"➡️",1) then
   e.dx=0
  end
 end

 --clamp acceleration
 e.dx=mid(
  -e.max_dx,e.dx,e.max_dx
 )
 e.dy=mid(
  -e.max_dy,e.dy,e.max_dy
 )

 --apply acceleration
 e.x+=e.dx
 e.y+=e.dy
end
-->8
--player

walk_f=0.2
jump_f=2.8
glide_f=g*1.1

function init_player()
 return class(
  init_entity(8,8,2,3),{
   sp=1,
   flp=false,
   state="idle",
   prev_state="idle",

   ⬅️=function(self,first)
    self.dx-=walk_f
   end,

   ➡️=function(self,first)
    self.dx+=walk_f
   end,

   ⬆️=function(self,first)
    double_jump(p,first)
   end,
  })
end

function update_player(p)
 update_entity(p)

 --state
 p.prev_state=p.state
 p.state="idle"
 if abs(p.dx)>0.1 then
  p.state="running"
 end
 if abs(p.dy)>0 then
  if p.glide then
   p.state="gliding"
  elseif p.dy<-1 then
   p.state="jumping"
  elseif p.dy>1 then
   p.state="falling"
  end
 end

 --flip
 if p.dx<0 then
  p.flp=true
 elseif p.dx>0 then
  p.flp=false
 end

 --sprite
 if p.state=="idle" then
  p.sp=1
 elseif p.state=="running" then
  p.sp=2+(t()*10)%3
 elseif p.state=="jumping" then
  p.sp=3
 elseif p.state=="gliding" then
  p.sp=1
 elseif p.state=="falling" then
  p.sp=1
 end

 --fire effects
 if p.state=="gliding" then
  rocket:on_player(p)
 end
 if p.prev_state=="falling"
 and p.state != "falling" then
  land:on_player(p)
 end
end

function jump(p, first)
 if first and p.dy==0 then
  p.dy-=jump_f
 end
end

function double_jump(p, first)
 if first then
  if not p._j or p.dy==0 then
   p._j=0
  else
   p._j+=1
  end
  if p._j<2 then
   p.dy=-jump_f
  end
 end
end

function glide(p, first)
 p.glide=first and p.dy>-glide_f
 if p.glide then
  p.dy-=glide_f+(rnd(0.5))
 end
end

function draw_player(p)
 spr(p.sp,p.x,p.y,1,1,p.flp)
end

-->8
--particles

function init_fxs()
 particles={}
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
 sfx=nil,

 sched=function(kls,...)
  if kls.sfx then
   sfx(kls.sfx)
  end

  for i=1,kls.amount do
   f=kls:gen_particle(...)
   kls:add_particle(f)
  end
 end,

 add_particle=function(kls,f)
  f.t = 0
  f = setmetatable(
   f,{__index=kls}
  )
  assert(f.life,"particle must know how many frames it'll live")
  assert(f.x,"particle must know its x")
  assert(f.y,"particle must know its y")
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
 colors={8,9,10,5},
 amount=3,

 on_player=function(kls,p)
  local x_off=0
  if p.flp then x_off=8 end
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
  local w = kls.width
  return {
   x=x-w/2+rnd(w),
   y=y-w/2+rnd(w),
   life=6+rnd(3),
   dx=dx,
   dy=dy,
  }
 end,

 update=function(f)
  f.x+=f.dx
  f.y+=f.dy
  f.r+=f.dr
  f.c=f:curr_color()

  if mget(f.x\8,f.y\8) ~= 0 then
   f.r=0
   f.dx=0
   f.dy=0
  end
 end,
})


land=class(base_fx, {
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

-->8
--npc

function init_npc(⬆️,color_map)
 return class(
  init_player(),{
   ⬆️=⬆️,
   color_map=color_map
  })
end

function update_npc(n)
 update_player(n)
end

function draw_npc(n)
 for i=1,#n.color_map,2 do
  pal(
   n.color_map[i],
   n.color_map[i+1]
  )
 end
 draw_player(n)
 pal()
end
__gfx__
00000000000000000000000000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006666000066660006611c60006666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070006611c6006611c600661116006611c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000066111600661116000666600066111600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000666600006666000088a800006666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000088a8000088a800008888000088a8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888000088880006000060068888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006006000060006000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000006611c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066111600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000776666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007788a8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000a8888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000906006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d6666666d00000000000000dd666666dd666666d00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005dddddd656000000000000565ddddd5005ddddd600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005dddddd65d600000000005d65dddd500005dddd600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005dddddd65dd6000000005dd65ddd50000005ddd600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005dddddd65ddd60000005ddd65dd5000000005dd600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005dddddd65dddd600005dddd65d500000000005d600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005dddddd65ddddd6005ddddd6550000000000005600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005555555d5555555dd555555dd00000000000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4200000000000000000000000000004300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000434200000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100004100000000414100000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100004100410043414142000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100414141414141414141414100004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414141414141414141414141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100000000000000000000000000000000000000000000000000000000000000000000000000
