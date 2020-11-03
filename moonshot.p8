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

]]

-->8
--variables / state

function init_physics()
 --gravity
 g=0.2
 --acceleration
 a=1.1
 --inertia
 i=0.8
end
-->8
--loop

function _init()
 init_physics()
 plr=init_player()
end

function _update60()
 update_player(plr)
end

function _draw()
 cls()
 map(0,0)
 draw_player(plr)
 
 --print debug if set
 if debug then print(debug) end
end
-->8
--entity

function init_entity(
 sp,w,h,max_dx,max_dy
)
 return {
 	sp=sp,
  x=0,
  y=0,
  w=w,
  h=h,
  dx=0,
  dy=0,
  frct=0.3,
  max_dx=max_dx,
  max_dy=max_dy,
  flp=false,
 }
end

function update_entity(e)
 --apply gravity
 e.dy+=g
 e.dx*=i

 --check collision up / down
 if e.dy>0 then
  e.dy=mid(
   -e.max_dy,e.dy,e.max_dy
  )

  if collide_map(e,"⬇️",0) then
   e.dy=0
   e.y-=((e.y+e.h+1)%8)-1
  end
 elseif e.dy<0 then
  if collide_map(e,"⬆️",0) then
   e.dy=0
  end
 end

 --check collision left / right
 if e.dx<0 then
  e.dx=mid(
   -e.max_dx,e.dx,e.max_dx
  )

  if collide_map(e,"⬅️",1) then
   e.dx=0
  end
 elseif e.dx>0 then
  e.dx=mid(
  	-e.max_dx,e.dx,e.max_dx
  )
  
  if collide_map(e,"➡️",1) then
   e.dx=0
  end
 end
 
 --apply flip
 e.flp=e.dx<0

 --apply velocity
 e.x+=e.dx
 e.y+=e.dy
end

function draw_entity(e)
	spr(e.sp,e.x,e.y,1,1,e.flp)
end
-->8
--player

function init_player()
 p = init_entity(1,8,8,2,3)
 p.accx=0.2
 p.accy=2.5
 p.anim=0
 return p
end

function update_player(p)
 handle_input(p)

 update_entity(p)
 
 update_sprite(p)
end

function handle_input(p)
 if btn(⬆️) and p.dy == 0 then
  p.dy-=p.accy
 end

 if btn(⬅️) then
  p.dx-=plr.accx
 end

 if btn(➡️) then
  p.dx+=plr.accx
 end
end

function update_sprite(p)
 --determine state form dx/dy
	local state="idle"
	if abs(p.dx)>0.1 then
	 state="running"
	end
	if abs(p.dy) > 0 then
		if p.dy<-1 then
		 state="jumping"
		elseif p.dy>1 then
		 state="falling"
		else
		 state="floating"
		end
 end
	
	--update sprite based on state
 if state=="idle" then
 	p.sp=1
 elseif state=="running" then
 	if time()-p.anim>.1 then
 		p.sp=1+(p.sp+1)%4
 		--todo:remove p.anim?
 		p.anim=time()
 	end
 elseif state=="jumping" then
  p.sp=4
 elseif state=="floating" then
  p.sp=5
 elseif state=="falling" then
  p.sp=6
 end
end

function draw_player(p)
	draw_entity(p)
end
-->8
--utils

function collide_map(obj,aim,flag)
 --obj = table needs x,y,w,h
 --aim = ⬅️,➡️,⬆️,⬇️

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

 return fget(mget(x1,y1), flag)
 or fget(mget(x1,y2), flag)
 or fget(mget(x2,y1), flag)
 or fget(mget(x2,y2), flag)
end
__gfx__
00000000000000000000000000000000000000000066660000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000066660000666600006666000066660006611c6000666600000000000000000000000000000000000000000000000000000000000000000000000000
0070070006611c6006611c6006611c6006611c600661116006611c60000000000000000000000000000000000000000000000000000000000000000000000000
00077000066111600661116006611160066111600066660006611160000000000000000000000000000000000000000000000000000000000000000000000000
00077000006666000066660000666600006666000088a80000666600000000000000000000000000000000000000000000000000000000000000000000000000
007007000088a8000088a8000088a8000088a800008888000088a800000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888000088880000888800008888000600006006888800000000000000000000000000000000000000000000000000000000000000000000000000
00000000006006000060006006000060060006000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000
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
d6666666d00000000000000dd666666dd666666d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd656000000000000565ddddd5005ddddd60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd65d600000000005d65dddd500005dddd60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd65dd6000000005dd65ddd50000005ddd60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd65ddd60000005ddd65dd5000000005dd60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd65dddd600005dddd65d500000000005d60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd65ddddd6005ddddd655000000000000560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555d5555555dd555555dd00000000000000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003010103030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000424300004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000400000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000004000444100004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000004000004000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000004000004000004000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000004241004000004000004000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
