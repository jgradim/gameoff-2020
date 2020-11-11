pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- moonshot
-- by goncalo, jgradim, and pkoch
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
inertia=0.8

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
 init_bg_fxs()
 init_fxs()
 init_lights(0,0)
end

fps=60
function _update60()
 handle_input(p)
 update_player(p)
 for i=1,#npcs do
  update_npc(npcs[i])
 end
 update_bg_fxs()
 update_fxs()
end

function _draw()
 cls()
 draw_bg_fxs()
 map(0,0)
 draw_lights()
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
 e.dx*=inertia

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
glide_f=g*2

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

   ⬆️=glide
  })
end

function update_player(p)
 update_entity(p)

 --state
 p.prev_state=p.state
 p.state="idle"
 if p.dy==0
 and abs(p.dx)>0.1 then
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
 if not first then return end

 if p.dy==0 then
  p.dy-=jump_f
 end
end

function double_jump(p, first)
 if not first then return end

 if not p._j or p.dy==0 then
  p._j=0
 else
  p._j+=1
 end
 if p._j<2 then
  p.dy=-jump_f
 end
end

function glide(p, first)
 p.glide = first or p.dy>0
 if p.glide then
  p.dy-=glide_f+(rnd(0.5))
 end
end

function draw_player(p)
 spr(p.sp,p.x,p.y,1,1,p.flp)
end

-->8
--bg_fxs

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
  f.t = 1
  f = setmetatable(
    f,
    {__index=kls}
  )
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
  pset(f.x,f.y,f.c)
 end,
}

far_star = class(bg_fx, {
 colors={5,6},
 dx=-1/fps,
})

near_star = class(bg_fx, {
 colors={7,15},
 dx=-6/fps,
})

-->8
--fxs

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
-->8
-- lights
lights_mask=11
lights_loop=30
lights_colors={8,10,9,1}
lights_pos={}

function init_lights(mx,my)
 map(mx,my)
 for y=0,127 do
  for x=0,127 do
   if pget(x,y)==lights_mask then
    add(lights_pos,{x,y})
   end
  end
 end
end

function draw_lights()
 local i=0

 foreach(lights_pos,function(pos)
  local x=pos[1]
  local y=pos[2]
  local c=
   abs(cos(t()/i))*#lights_colors\1

  pset(x,y,lights_colors[c+1])
  i=i>lights_loop and 0 or i+3
 end)
end
__gfx__
00000000000000000000000000666600000000000000000000000000944494445ddd5ddd00000000000000000000000000000000000000000000000000000000
00000000006666000066660006611c6000666600000000000000000044494449ddd5ddd5000b0b00000000000000000000000000000000000000000000000000
0070070006611c6006611c600661116006611c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700006611160066111600066660006611160000000000000000044544454dd5ddd5d0b0b0b00000000000000000000000000000000000000000000000000
0007700000666600006666000088a80000666600000000000000000045444544d5ddd5dd00000000000000000000000000000000000000000000000000000000
007007000088a8000088a800008888000088a800000000000000000000000000000000000b0b0b00000000000000000000000000000000000000000000000000
00000000008888000088880006000060068888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006006000060006000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06611c60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06611160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7788a800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90600600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000070007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000666701c770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0066666701ccc7700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0566666701ccccc70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0566666000ccccc70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555000000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777717171717777777771717171777777777777777777777777555555550000000000000000d6666666d00000000000000d555555555555555555555555
666666666161616166666666616161617666666666666666666666675555555500000000000000005dddddd65600000000000056555666666666666666666555
ddddddddd1d1d1d1ddddddddd1d1d1d176dddddddddddddddddddd675555555500000000000000005dddddd65d600000000005d6556111111111111111111655
dddddddddddddddddddddddddddddddd76dddddddddddddddddddd675555555500000000000000005dddddd65dd6000000005dd6561000000000000000000165
ddddddddddddddddd16dd16dd16dd16d76dddddddddddddddddddd675555555500000000000000005dddddd65ddd60000005ddd6561000000000000000000165
ddddddddddddddddd11dd11dd11dd11d76dddddddddddddddddddd675555555500000000000000005dddddd65dddd600005dddd6561000000000000000000165
dddddddddddddddddddddddddddddddd7666666666666666666666675555555500000000000000005dddddd65ddddd6005ddddd6561000000000000000000165
dddddddddddddddddddddddddddddddd7777777777777777777777775555555500000000000000005555555d5555555dd555555d561000000000000000000165
dddddd67dddddd67dddddd67dddddd6755777755557777555577775555777755557777555577775555777755d666666d15555555561000000000000000000165
dddddd67ddddd111dd16dd67dd16d111576d667557d1d67557111d755711117557111d7557d1d675576d667505ddddd601111115561000000000000000000165
dddddd67dddddd67dd11dd67dd11dd677666d667766d1d6776d111d77111111776d111d7766d1d677666d667005dddd601111115561000000000000000000165
dddddd67ddddd111dddddd67ddddd111766d666776d1d6677d111d67711111177d111d6776d1d667766d66670005ddd601111115561000000000000000000165
dddddd67dddddd67dddddd67dddddd677666d667766d1d6776d111d77111111776d111d7766d1d677666d66700005dd601111115561000000000000000000165
dddddd67ddddd111dd16dd67dd16d111766d666776d1d6677d111d67711111177d111d6776d1d667766d6667000005d601111115561000000000000000000165
dddddd67dddddd67dd11dd67dd11dd677666d667766d1d6776d111d77111111776d111d7766d1d677666d6670000005601111115561000000000000000000165
dddddd67ddddd111dddddd67ddddd111766d666776d1d6677d111d67711111177d111d6776d1d667766d66670000000d00000001561000000000000000000165
111ddddd76dddddd111ddddd76dddddd55555555555555555555555555aba95500000000000000000000000dd000000000000000561000000000000000000165
76dd11dd76dd11dd76dddddd76dddddd55555555555555555555555555aba9550000000000000000000000056000000000000000561000000000000000000165
111d61dd76dd61dd111ddddd76dddddd55555555555aaaaaaaaaa55555aba9550000000000000000000000056000000000000000561000000000000000000165
76dddddd76dddddd76dddddd76dddddd5555555555aabbbbbbbbaa5555aba9550000000000000000000000056000000000000000561000000000000000000165
111ddddd76dddddd111ddddd76dddddd5555555555abaaaaaaaaba5555aba95500000000000000000000000dd000000000000000561000000000000000000165
76dd11dd76dd11dd76dddddd76dddddd5555555555aba999999aba5555aba9550000000000000000000000000000000000000000556111111111111111111655
111d61dd76dd61dd111ddddd76dddddd5555555555aba955559aba5555aba9550000000000000000000000000000000000000000555666666666666666666555
76dddddd76dddddd76dddddd76dddddd5555555555aba955559aba5555aba9550000000000000000000000000000000000000000555555555555555555555555
dddddd6776dddddddddddddddddddddd5555555555aba955559aba55559aba5500000000000000006666666666666666005dd600000000000000000000000000
dddddd6666dddddddddddddddddddddd5555555555aba955559aba55559aba550000000000000000dddddddddddddddd005dd600001111111111111111111100
ddddddddddddddddddddddddddddddddaaaaaaaaaaaba955559abaaa559aba550000000000000000dddddddddddddddd005dd600010000000000000000000010
ddddddddddddddddddddddddddddddddbbbbbbbbbbbaa955559aabbb559aba550000000000000000dddddddddddddddd005dd600010000000000000000000010
ddddddddddddddddddddddddddddddddaaaaaaaaaaaaa955559aaaaa559aba5500000000000000005555555555dddd55005dd600010000000000000000000010
dddddddddddddddddddddddddddddddd999999999999955555599999559aba55000000000000000000000000005dd600005dd600010000000000000000000010
dddddddddddddddddddddd6666dddddd555555555555555555555555559aba55000000000000000000000000005dd600005dd600001111111111111111111100
dddddddddddddddddddddd6776dddddd555555555555555555555555559aba55000000000000000000000000005dd600005dd600000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003030303030303000000000000000000030303030000000000000000000000000303030300000000000000000000000003030303000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6464646464646464646464646464646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646464646464646464646464646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646464646464646464646464646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5064646464646464646464646464646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5064646464646464646464646465746300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50646464644d4e4e4e4e4f646467646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50646464645d000000005f646467646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50747474745d000000005f747475646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50646464645d000000005f646464646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50646464646d6e6e6e6e6f646464646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5064646464646464646464646464646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5064646464646464646464646464646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5064646464646464646464645464646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5064444546646444466464444546646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5064646464646464646464646464646300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7042404140424040404042404140427100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100000000000000000000000000000000000000000000000000000000000000000000000000
