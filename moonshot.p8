pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--shoot for the moon
--by goncalossilva,jgradim,pkoch

---------------
---constants---
---------------

fps=60

map_width=1024
map_height=256

--downward movement per cycle
gravity=.1

--movement multiplier per cycle
inertia=.125

-------------
---sprites---
--------------

sp_player_idle=1
sp_player_run_start=2
sp_player_run_length=3
sp_player_jump=3
sp_player_glide=5

sp_spark_start=39
sp_spark_length=4

sp_platform_start=48
sp_platform_length=4

sp_door_opened=0
sp_door_closed=11

sp_screen=8
sp_button_left=9
sp_button_right=10

sp_tiny_font=128

sp_laser_h=182
sp_laser_v=186

sp_checkpoint=63

sp_hole=190

sp_ship_s=55
sp_ship_m=27
sp_ship_l=16

-----------------------
---sprite animations---
-----------------------
anim_platform=split(
"23,24,25,26"
)
anim_door_open=split(
"11,12,13,14,15,0"
)
anim_door_close=split(
"0,15,14,13,12,11"
)
anim_door_jammed=split(
"11,11,11,12,11,12"
)
anim_bolt=split(
"39,40,41,42"
)
anim_screen_warn=split(
"57,58"
)
anim_screen_ok={59}
anim_checkpoint=split(
 "63,63,63,63,63,62,63,63,"..
 "62,63,63,63,63,63,63"
)
anim_player_unlocker=split(
 "5,1,5,1,5,1,3,1"
)

------------------
---rect sprites---
------------------

function xywh(x,y,w,h)
 return {x=x,y=y,w=w,h=h}
end

rect_tooltip=xywh(
 112,8,12,11
)
rect_escape_pod_l=xywh(
0,8,32,20
)
rect_escape_pod_m=xywh(
96,7,23,15
)
rect_escale_pod_s=xywh(
48,64,11,8
)
rect_laser_v_u=xywh(
96,28,5,4
)
rect_laser_v_d=xywh(
101,28,5,4
)
rect_laser_h_l=xywh(
96,23,4,5
)
rect_laser_h_r=xywh(
100,23,4,5
)
rect_title=xywh(
0,96,58,26
)
rect_moon=xywh(
96,96,32,32
)
rect_ship_s=xywh(
56,24,10,7
)
rect_ship_m=xywh(
88,8,22,14
)
rect_ship_l=xywh(
0,8,31,19
)


function ssprrect(box,dx,dy)
 sspr(box.x,box.y,box.w,box.h,dx,dy)
end

-------------------
---palette swaps---
-------------------
pal_default={}
pal_button_off={
 [3]=8,
 [11]=14
}
pal_button_disabled={
 [3]=9,
 [11]=10
}
pal_checkpoint_on={
 [14]=12,
 [15]=13,
}
pal_checkpoint_off={
 [14]=12,
 [15]=12,
 [12]=13,
 [1]=13
}
pal_screen_blank={
 [8]=1,
 [10]=1,
 [3]=1,
}
pal_screen_error={
 [3]=1,
 [10]=8,
}
pal_screen_ok={
 [8]=1,
 [10]=3,
}

p_colors={
 red={[8]=8},
 yellow={[1]=0,[12]=5,[8]=9},
 blue={[8]=1,[12]=14,[6]=5},
 green={[8]=3,[10]=11}
}

--------------
---messages---
--------------

msg_close_scren=
 "    press 🅾️/z to exit"

msg_dbljmp=
 "   thank you for saving me!\n"..
 "   let me help you,i can\n"..
 "   double jump!"..
 "\n\n"..
 "     great! we can switch\n"..
 "   between us with ⬆️/⬇️!"

--msg_glider=
-- "check out my sweet jetpack!"..
-- "not a fire hazard"..
-- "\nor anything"..
-- "\n\n\n\n"..
-- "that's nice. don't burn"..
-- "your ankles, dearie"

-----------------
---wall labels---
-----------------
--{text,x,y,color}
wall_labels={
 {
  "diagnostics",
  62*8+4,23*8+4,14
 },
 {
  "lvl 1",
  44*8+4,26*8+4,14
 },
 {
  "< engine room",
  15*8,29*8+2,14
 },
 {
  "< lab",
  38*8,20*8
 },
 {
  "escape pods >",
  50*8+4,11*8+4
 },
 {
  "thank you for playing",
  61*8+4,14*8+2
 },
}

-----------------------
---credits formation---
-----------------------
credits_formation={
 [1]={
  -rect_ship_l.w-16,
  64-rect_ship_l.h/2
 },
 [2]={
  (-rect_ship_l.w-16)*2,
  64-rect_ship_l.h/2-32
 },
 [3]={
  (-rect_ship_l.w-16)*2,
  64-rect_ship_l.h/2+32
 },
 [4]={
  (-rect_ship_l.w-16)*3,
  64-rect_ship_l.h/2
 }
}


------------------
---sprite flags---
------------------

--obstacles that are rigid and
--block in all directions
flag_block=0

--obstacles that move the player
--to the last checkpoint
flag_spawn=1

---------------------
---custom hitboxes---
---------------------

--[sprite]={{x,y,w,h},(...)}
custom_hitboxes={
 -------------------
 ---interactables---
 -------------------

 --doors
 "11|1,0,6,8",
 "12|1,0,6,8",
 "13|1,0,6,8",
 "14|1,0,6,8",

 --moving platforms
 "23|0,0,8,3",
 "24|0,0,8,3",
 "25|0,0,8,3",
 "26|0,0,8,3",

 --horizontal lasers
 "182|0,1,8,3",
 "183|0,1,8,3;8,1,8,3",
 "184|0,1,8,3;8,1,8,3;16,1,8,3",
 "185|0,1,8,3;8,1,8,3;16,1,8,3;24,1,8,3",

 --vertical lasers
 "186|1,0,3,8",
 "187|1,0,3,8;1,8,3,8",
 "188|1,0,3,8;1,8,3,8;1,16,3,8",
 "189|1,0,3,8;1,8,3,8;1,16,3,8;1,24,3,8",

 --pressure plates
 "20|0,0,8,2",
 "36|0,0,8,2",

 --sparks
 "52|2,2,4,4",

 ---------------
 ---map tiles---
 ---------------

 --left endpiece
 "112|1,0,7,6;0,1,8,4",
 "180|1,0,7,6;0,1,8,4",

 --right endpiece
 "113|0,0,7,6;0,1,8,4",
 "181|0,0,7,6;0,1,8,4",

 --top endpiece
 "97|2,1,4,7;1,2,6,6",

 --bottom endpiece
 "96|1,0,6,6;2,0,4,7",

 --walls
 "80|1,0,6,8",
 "83|1,0,6,8",
 "84|1,0,6,8",
 "85|1,0,6,8",
 "86|1,0,6,8",
 "101|1,0,6,8",
 "102|1,0,6,8",
 "117|1,0,6,8",
 "118|1,0,6,8",
 "162|1,0,6,8",
 "163|1,0,6,8",

 --top left corner
 "98]2,0,6,6;1,1,6,7",
 "130|2,0,6,6;1,1,6,7",
 "132|2,0,6,6;1,1,6,7",
 --top right corner
 "99|0,0,6,6;1,1,6,7",
 "131|0,0,6,6;1,1,6,7",
 "133|0,0,6,6;1,1,6,7",

 --bottom left corner
 "114|1,0,7,5;2,0,6,6",
 "146|1,0,7,5;2,0,6,6",
 "148|1,0,7,5;2,0,6,6",

 --bottom right corner
 "115|0,0,7,5;0,0,6,6",
 "147|0,0,7,5;0,0,6,6",
 "149|0,0,7,5;0,0,6,6",

 --floor
 "64|0,0,8,6",
 "66|0,0,8,6",
 "67|0,0,8,6",
 "68|0,0,8,6",
 "69|0,0,8,6",
 "70|0,0,8,6",
 "164|0,0,8,6",
 "165|0,0,8,6",

 --reverse "t" shape
 "66|0,0,8,6",
 "165|0,0,8,6",

 --"t" shape
 "65|0,0,8,6;1,0,6,8",
 "176|0,0,8,6;1,0,6,8",
 "177|0,0,8,6;1,0,6,8",

 --branch left
 "81|0,0,7,6;1,0,6,8",
 "100|0,0,7,6;1,0,6,8",
 "179|0,0,7,6;1,0,6,8",

 --branch right
 "82|1,0,6,8;1,0,7,6",
 "116|1,0,6,8;1,0,7,6",
 "178|1,0,6,8;1,0,7,6",

 --broken endpiece left
 "172|4,0,4,6",
 "174|4,0,4,6",

 --broken endpiece right
 "173|0,0,5,6",
 "175|0,0,5,6",
}

------------------
---map elements---
------------------

function init_mechanics()

 ---------------
 --diagnostics--
 ---------------
 --cosmetics
 local diag_jammed_door=
  init_animated({
   x=68*8,
   y=29*8,
   w=8,
   h=8,
   anim=anim_door_jammed,
   anim_freq=6,
   collide=block,
  })

 local diag_screen_warn=
  init_animated({
   x=62*8,
   y=29*8,
   anim=anim_screen_warn,
   anim_freq=8,
  })

 --doors
 local diag_door=
  init_door(
   56*8,28*8,false
  )

 --platforms
 local diag_plt=
  init_platform(
   60*8,26*8,
   60*8,28*8,
   false
  )

 --buttons
 local diag_door_btn=init_button(
   sp_button_right,67*8,25*8,
   false,false,
   function(b)
    toggle_door(diag_door,b.active)
   end
 )

 local diag_plt_btn=init_button(
  sp_button_left, 58*8,29*8,
  true,false,
  function()
   play_sfx("platform_on")
   diag_screen_warn.anim=
    anim_screen_ok
   diag_plt.moving_since=t()
  end
 )

 --screens
 local diag_screen_high=
  init_interactable({
   sp=sp_screen,
   x=65*8,
   y=25*8,
   tooltip="🅾️",
   msg=
    "> status report:\n\n"..
    "-heavy damage to hull\n"..
    "-remaining crew: 3\n"..
    "-escape pods: 4\n"..
    "-disabled platforms: 5\n"..
    "-shocking hazards\n\n"..
    "objective: open door\n"..
    "objective: rescue crew\n"..
    "objective: escape to moon\n\n"..
    msg_close_scren,
  })

 -------------------
 --broken corridor--
 -------------------
 local shaft_l1_plt=
  init_platform(
    47*8,22*8,
    47*8,28*8,
    false
  )

 local shaft_l1_btn=init_button(
  sp_button_right,42*8,25*8,
  true,false,function()
    play_sfx("platform_on")
    shaft_l1_plt.moving_since=t()
  end
 )

 local shaft_l2_plt=
  init_platform(
    45*8,13*8,
    45*8,21*8,
    false
  )

 local shaft_l2_btn=init_button(
  sp_button_right,42*8,15*8,
  true,false,function()
    play_sfx("platform_on")
    shaft_l2_plt.moving_since=t()
  end
 )

 local shaft_l2_laser=
  init_laser(
   {41*8+2,12*8+1},{41*8+2,12*8+1},
   "v",4
  )

 local shaft_l2_screen=
  init_animated({
   x=38*8,
   y=18*8,
   anim=anim_screen_ok,
   anim_freq=8,
  })

 --------------------------
 ---double jumper unlock---
 --------------------------
 dbljmp_plt=init_platform(
   9*8,16*8,
   9*8,26*8,
   true
 )

 dbljmp_door=
  init_door(
   6*8,18*8,false
  )

 dbljump_btn=
  init_interactable({
   sp=sp_button_left,
   sp_pal=pal_button_off,
   x=7*8,
   y=15*8,
   tooltip="🅾️",

   active=false,

   on_button_press=function(b)
    b.tooltip=nil
    b.active=not b.active
    b.sp_pal=b.active
     and pal_default
     or pal_button_off

    toggle_door(
     dbljmp_door,
     b.active
    )
  end,
  })

 dbljmp_player_unlock=
  init_player_unlocker(
   3,18,
   msg_dbljmp,
   "yellow",double_jump
  )

 ---------
 ---lab---
 ---------

 local lab_door=init_door(
   33*8,21*8,false
 )

 local lab_press_plate=
  init_press_plate(
   36*8,22*8,true,
   function(p)
    toggle_door(lab_door,p.pressed)
   end
  )

 local lab_shaft_laser_btn=
  init_button(
   sp_button_left,42*8,9*8,
   false,true,function(b)
     shaft_l2_laser.on=
      b.active
     shaft_l2_screen.anim=
      anim_screen_warn
   end
  )

 local lab_laser_l_1=init_laser({25*8,17*8+1},{25*8,17*8+1},"v",4,function(l) l.on=t()%4>=1 end)
 local lab_laser_l_2=init_laser({21*8,17*8+1},{21*8,17*8+1},"v",4,function(l) l.on=t()%4<=2 end)
 local lab_laser_l_3=init_laser({17*8,17*8+1},{17*8,17*8+1},"v",4,function(l) l.on=t()%4>=1 end)

 local lab_plt=
  init_platform(
   12*8,13*8,
   12*8,19*8,
   true
  )

 local lab_laser_h_1=init_laser({27*8,12*8+1},{27*8,12*8+1},"v",4,function(l) l.on=t()%4<=2 end)
 local lab_laser_h_2=init_laser({22*8,12*8+1},{22*8,12*8+1},"v",4,function(l) l.on=t()%4>=1 end)
 local lab_laser_h_3=init_laser({17*8,12*8+1},{17*8,12*8+1},"v",4,function(l) l.on=t()%4<=2 end)

 ---------
 ---end---
 ---------

 local end_screen=
  init_interactable({
   sp=sp_screen,
   x=83*8,
   y=14*8,
   tooltip="🅾️",
   msg=
    "\n"..
    "     congratulations!\n\n"..
    "thank you for playing\n"..
    "shoot for the moon, our\n"..
    "entry in\n"..
    "github's game off 2020\n\n"..
    "it is unfinished, but we\n"..
    "hope you enjoyed it!\n\n\n"..
    msg_close_scren,

    on_msg_end=function(s)
     players[1].saved=true
     players[2].saved=true
     set_scene(scene_credits)
    end,
  })

 -------------------
 ---glider unlock---
 -------------------
 --glider_player_unlock=
 -- init_player_unlocker(
 --  0,0,
 --  msg_glider,
 --  "green",glide
 -- )

 ------------------------
 ---hover boots unlock---
 ------------------------

 return {
  --checkpoints
  init_checkpoint(45,29),
  init_checkpoint(1,18),
  init_checkpoint(14,20),

  -- dianostics
  diag_jammed_door,
  diag_screen_warn,
  diag_screen_high,
  diag_door,
  diag_door_btn,
  diag_plt,
  diag_plt_btn,

  --shaft
  shaft_l1_plt,
  shaft_l1_btn,
  shaft_l2_plt,
  shaft_l2_btn,
  shaft_l2_laser,
  shaft_l2_screen,

  -- corridor
  corridor_btn,

  -- double jumper
  dbljmp_plt,
  dbljmp_door,
  dbljump_btn,
  dbljmp_player_unlock,

  -- lab
  lab_door,
  lab_press_plate,
  lab_shaft_laser_btn,
  lab_laser_l_1,
  lab_laser_l_2,
  lab_laser_l_3,
  lab_plt,
  lab_laser_h_1,
  lab_laser_h_2,
  lab_laser_h_3,
  lab_p,

  -- end
  end_screen,
 }
end

-->8
--scenes,loop,camera,utils

----------
---loop---
----------

function set_scene(s)
 _update60=s.update
 _draw=s.draw
 s.init()
end

function _init()
 --starting scene
 set_scene(scene_title)
end

-----------------
---title scene---
-----------------

start_game_at=nil
repeat_music_at=nil

scene_title={
 init=function()
  start_game_at=nil

  --background fx
  add_bg_fxs()

  --music
  music(0,5000)
  repeat_music_at=t()+17
 end,

 update=function()
  --handle input
  if btnp(❎) then
   if not start_game_at then
    --crossfade scenes and start
    play_sfx("start_game")
    start_game_at=t()+1
    music(-1)
   else
    --start immediately
    start_game_at-=2
   end
  end

  --fxs
  foreach(bg_particles,update)
  update_fxs()

  --start game when ready
  if start_game_at
  and t()>=start_game_at
  then
   set_scene(scene_game)
  end

  --music
  if repeat_music_at<=t() then
   music(0)
   repeat_music_at=t()+17
  end
 end,

 draw=function()
  cls()
  pal()

  --fxs
  foreach(bg_particles,draw)
  draw_fxs()

  --top left title
  ssprrect(rect_title, 8,8)

  --center text
  local txt=
   "press ❎/x to play"
  print(
   txt,hcenter(txt),72,
   time()%0.4<0.2 and 7 or 10
  )

  --bottom commands
  print_footer(
   "⬅️➡️:run   ❎/x:jump   🅾️/z:use    "
  )

  --fade out if starting game
  if start_game_at then
   fadepal(1-(start_game_at-t()),1)
  end
 end,
}

----------------
---game scene---
----------------

players={}

scene_game={
 init=function()
  --btnp never repeats
  poke(0x5f5c,255)

  set_checkpoint(65*8,28*8)

  --players
  players={
   init_player{
    🅾️=jump,
    color="red",
    x=65*8,-- diagnostics
    y=28*8,
    --x=7*8, -- dbljump
    --y=14*8,
    --x=48*8, -- shaft
    --y=29*8,
    --x=40*8, -- lab
    --y=9*8,
    --x=82*8, -- end
    --y=14*8,
   },
  }

  --background fx and thrusters
  add_bg_fxs()
  thruster:add(1,22.5)
  thruster:add(1,8.5)

  --mechanics
  mcns=init_mechanics()

  --camera
  cam:move(player(),true)
 end,

 update=function()
  --input
  local p=player()

  if player_input then
    player_btns={[0]="⬅️",[1]="➡️",[5]="❎"}
    for n, b in pairs(player_btns) do
      if btn(n) then
       fn=p[b]
       if (fn) fn(p,btnp(n))
      end
    end

    if btnp(⬆️) then
      focus_next_player()
    end

    if btnp(⬇️) then
      focus_prev_player()
    end
  end

  --players
  --path:update()
  foreach(players,update)

  --mechanics
  foreach(mcns,update)

  --fxs
  fire_fxs()
  foreach(bg_particles,update)
  update_fxs()

  --camera
  cam:move(p)
 end,

 draw=function()
  cls()
  pal()

  --fxs
  foreach(bg_particles, draw)
  animate_map()
  map(0,0)
  draw_fxs()

  --tiny text
  for wl in all(wall_labels) do
   print_tiny(
    wl[1],wl[2],wl[3],wl[4]
   )
  end

  --mechanics
  foreach(mcns,draw)

  --players
  foreach(players,draw)

  --modals from interactables
  foreach(mcns,function(m)
   if m.draw_modal then
    m:draw_modal()
   end
  end)

  --camera
  cam:draw()

  --start game fade-in effect
  if start_game_at
  and start_game_at+1>t() then
   fadepal(1-(t()-start_game_at),1)
  end
 end,
}

-------------------
---credits scene---
-------------------

saved_players={}
show_credits_at=nil

scene_credits={
 init=function()
  show_credits_at=nil

  --reset draw state
  pal()

  --gather saved players
  saved_players={}
  local i=1
  for p in all(players) do
   if p.saved then
    add(
     saved_players,
     instance(p,{
      x=credits_formation[i][1],
      y=credits_formation[i][2],
      dx=0.25,
     })
    )
    i+=1
   end
  end

  --background fx
  add_bg_fxs()
 end,

 update=function()
  --handle input
  if btnp(❎) then
   set_scene(scene_title)
   return
  end

  --fxs
  foreach(bg_particles,update)
  update_fxs()

  --player ships
  for i,p in ipairs(saved_players) do
   p.x+=p.dx
   if p.x>(32-i*8) then
    p.dx+=rnd(0.3)
   end
  end

  --reset camera
  cam:move()
 end,

 draw=function()
  cls()
  pal()

  cam:draw()

  --fxs
  foreach(bg_particles,draw)
  draw_fxs()

  if not show_credits_at then
   --animate player ships

   local ships=false
   for p in all(saved_players) do
    local cm=p_colors[p.color]
    for c1,c2 in pairs(cm) do
     pal(c1,c2)
    end

    ssprrect(rect_ship_l,p.x,p.y)

    ships=ships or p.x<128
   end
   if not ships then
    show_credits_at=t()+1
   end
  else
   --show credits

   if show_credits_at>t() then
    fadepal(show_credits_at-t(),0)
   end

   --title
   ssprrect(rect_title,8,8)

   --center
   local txt={
    "congratulations!",
    "you're on the way to the moon.",
    "",
   }
   local abandoned=
    #players-#saved_players
   if abandoned>0 then
    add(txt,"crew saved:     "..#saved_players)
    add(txt,"crew abandoned: "..abandoned)
   else
    add(txt,"crew saved: all ♥")
   end
   add(txt,"")
   add(txt,"press ❎/x to restart")
   for i,t in ipairs(txt) do
    print(t,hcenter(t),56+i*6,7)
   end

   --bottom
   print_footer(
    "by goncalossilva, jgradim, pkoch"
   )
  end
 end,
}

------------
---camera---
------------

cam={
 x=0,
 y=0,
 frms=7.5,
 shk=0,

 fixed_x=function(c,x)
  return c.x+x
 end,

 fixed_y=function(c,y)
  return c.y+y
 end,

 inv_x=function(c,x)
  return c.x+(x-c.x%128)
 end,

 inv_y=function(c,y)
  return c.y+(y-c.y%128)
 end,

 shake=function(c,shk)
  shk=shk or 1
  c.shk+=shk
 end,

 move=function(c,p,now)
  if p then
   local f=now and 1 or c.frms
   c.x=mid(
    -64,
    c.x+(p.x-c.x-64)/f,
    map_width+64
   )
   c.y=mid(
    0,
    c.y+(p.y-c.y-64)/f,
    map_height-128
   )
   c.shk*=0.9
  else
   c.x=0
   c.y=0
   c.shk=0
  end
 end,

 draw=function(c)
  local x=c.x
  local y=c.y
  local shk=c.shk

  if shk>0 then
   local shkx=16-rnd(32)
   local shky=16-rnd(32)
   x+=shkx*shk
   y+=shky*shk
  end

  camera(x,y)
 end,
}

-----------
---utils---
-----------

function add_bg_fxs()
 bg_particles={}
 far_star:add_plane()
 near_star:add_plane()
 ship:add_all()
 moon:add()
end

function print_footer(t)
 print(t,hcenter(t),122,5)
end

function update(o)
 return o:update()
end

function draw(o)
 return o:draw()
end

function player()
 return players[#players]
end

function focus_next_player()
 add(
  players,
  deli(players,#players),
  1
 )
end

function focus_prev_player()
 add(
  players,
  deli(players,1)
 )
end

player_input=true

function enable_player_input()
player_input=true
end

function disable_player_input()
player_input=false
end

function animate(e,freq,loop,p)
 p=p or "sp"

 if (#e.anim==0) return
 if (#e.anim==1) e[p]=e.anim[1]

 local ac=mid(
  1,
  e.anim_cursor+(1/freq),
  #e.anim+2
 )

 if ac>=#e.anim+1 then
  ac=loop and 1 or #e.anim
 end

 e.anim_cursor=ac
 e[p]=e.anim[e.anim_cursor\1]
end

--have kls "extends" super
function class(super,kls)
 kls.meta={__index=super}
 kls.super=super
 return setmetatable(
  kls,kls.meta
 )
end

---make o an instance of kls
function instance(kls,o)
  o.super=kls
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

--intersection of a and b
function intersect(a,b)
 local x=max(a.x,b.x)
 local y=max(a.y,b.y)
 return {
  x=x,
  y=y,
  w=min(a.x+a.w,b.x+b.w)-x,
  h=min(a.y+a.h,b.y+b.h)-y,
 }
end

--todo:document
function bucket(v,step)
 v-=(sgn(v)*v)%step
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

function sp_coords(tile)
 return {
  x=8*(tile%16),
  y=8*(tile\16),
 }
end

function sp_hitboxes(sp,x,y)
 local hbs=custom_hitboxes[sp]

 if not hbs then
  return {{x=x,y=y,w=8,h=8}}
 end

 local r={}
 for hb in all(hbs) do
  add(r,{
   x=hb[1]+x,
   y=hb[2]+y,
   w=hb[3],
   h=hb[4],
  })
 end
 return r
end

function sp_collisions_iter(
 sp,x,y,phb,flag
)
 if not fget(sp,flag) then
  return function() end
 end

 local hbs=sp_hitboxes(sp,x,y)
 local i=0
 return function()
  while i<#hbs do
   i+=1
   local hb=hbs[i]
   if intersects(phb,hb) then
    return hb
   end
  end
 end
end

function resolve_collisions(p)
 --p:{x,y,hitbox():{x,y,w,h}}

 local collisions={}

 local function add_colliding(
  sp,x,y,
  flag,phb,
  resolve_fn_args
 )
  for mhb in sp_collisions_iter(
   sp,x,y,phb,flag
  ) do
   local res_fn,res_args=
    resolve_fn_args(mhb)
   local x=intersect(phb,mhb)
   insert(
    collisions,
    {res_fn,res_args},
    x.w+x.h
   )
  end
 end

 --check colliding map tiles
 local phb=p:hitbox()
 local x1=phb.x
 local x2=phb.x+phb.w-1
 local y1=phb.y
 local y2=phb.y+phb.h-1
 for x in all({x1,x2}) do
  for y in all({y1,y2}) do
   local sp=mget(x/8,y/8)
   local tilex=x\8*8
   local tiley=y\8*8

   --block when colliding with
   --tiles that have flag_block
   add_colliding(
    sp,tilex,tiley,
    flag_block,
    phb,
    function(mhb)
     return block,{mhb,mhb,p}
    end
   )

   --respawn when colliding with
   --tiles that have flag_spawn
   add_colliding(
    sp,tilex,tiley,
    flag_spawn,
    phb,
    function(mhb)
     return chkpt.restore,{chkpt}
    end
   )
  end
 end

 --check colliding mechanics
 for mcn in all(mcns) do
  if mcn.collide then

   --invoke the mechanics'
   --collide() when flag_block
   add_colliding(
    mcn.sp,mcn.x,mcn.y,
    flag_block,
    phb,
    function(mhb)
     return mcn.collide,{mcn,mhb,p}
    end
   )
  end
 end

 --resolve collisions from the
 --most to least colliding
 while #collisions>0 do
  local r=pop(collisions)[1]
  local r_fn=r[1]
  r_fn(unpack(r[2]))
 end
end

--blocks p from intersecting cl,
--adjusting for specific hitboxes
--returns block direction
function block(cl,clhb,p)
 local phb=p:hitbox()
 local x=intersect(phb,clhb)

 --resolve using shallowest axis
 local aim=nil
 if x.w<x.h then
  aim=phb.x<cl.x and "⬅️" or "➡️"
 else
  aim=phb.y<cl.y and "⬆️" or "⬇️"
 end

 if aim=="⬅️" then
  p.dx=min(p.dx,0)
  p.x+=min(clhb.x-phb.x-phb.w,0)
  return aim
 elseif aim=="➡️" then
  p.dx=max(p.dx,0)
  p.x+=max(clhb.x+clhb.w-phb.x,0)
  return aim
 elseif aim=="⬆️" then
  p.dy=min(p.dy,0)
  p.y+=min(clhb.y-phb.y-phb.h,0)
  return aim
 elseif aim=="⬇️" then
  p.dy=max(p.dy,0)
  p.y+=max(clhb.y+clhb.h-phb.y,0)
  return aim
 end
end

function fadepal(perc,pal_p)
 --perc:0 normal,
 --     1 is completely dark

 local p=flr(mid(0,perc,1)*100)
 local dpal={
  0,1,1,2,1,13,6,4,
  4,9,3,13,1,13,14
 }

 for j=1,15 do
  local col=j

  --this is a messy formula and
  --not exact science. when kmax
  --reaches 5 every color turns
  -- black.
  local kmax=(p+(j*1.46))/22
  for k=1,kmax do
   col=dpal[col]
  end

  pal(j,col,pal_p)
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

function unpack_custom_hitboxes(ls)
 local r={}
 for l in all(ls) do
  local derp=split(l,"|")
  local k=derp[1]
  local ts=derp[2]
  r[k]={}
  for t in all(split(ts,";")) do
   add(r[k], split(t))
  end
 end
 return r
end
custom_hitboxes=unpack_custom_hitboxes(custom_hitboxes)

function hcenter(s)
 return 64-#s*2
end


-->8
--player

------------
---player---
------------

run_accel=1/4
jump_accel=1.9

function init_player(p)
 return instance({
  x=0,
  y=0,
  w=8,
  h=8,
  dx=0,
  dy=0,
  max_dx=1,
  max_dy=1.5,

  color="red",
  sp=sp_player_idle,
  flpx=false,
  flpy=false,

  running=false,
  jumping=false,
  falling=false,
  gliding=false,
  glided=false,
  ground=false,
  landed=false,

  saved=false,

  hitbox=function(p)
   return {
    x=p.x+1,
    y=p.y+1,
    w=p.w-2,
    h=p.h-1,
   }
  end,
  standbox=function(p)
   return {
    x=p.x+2,
    w=4,
    y=p.y+p.h,
    h=1,
   }
  end,

  ⬅️=run_left,
  ➡️=run_right,
  ❎=jump,

  update=function(p)
   local old_y=p.y\1
   local old_x=p.x\1

   --move horizontally
   p.dx=mid(-p.max_dx,p.dx,p.max_dx)
   if abs(p.dx) > inertia then
     p.dx+=-1*sgn(p.dx)*inertia
   else
    p.dx=0
   end
   p.x+=p.dx
   resolve_collisions(p)

   --move vertically
   if p.flpy then
    p.dy-=gravity
   else
    p.dy+=gravity
   end
   p.dy=clamp(p.dy,p.max_dy,0x.08)
   p.y+=p.dy
   local was_falling=
    p.flpy and p.dy<0 or p.dy>0
   resolve_collisions(p)
   local ground_hit=
    was_falling and p.dy==0

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
   p.landed=p.ground
    and not was_ground
   if p.ground then
    p.falling=false
    p.jumping=false
    p.gliding=false
   else
    --falling:moving downwards
    --(mini gravity movements
    --excluded since ground=true)
    p.falling=not p.gliding
     and (
      p.flpy and p.dy<0 or p.dy>0
     )
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
   else
    p.sp=sp_player_idle
   end

   --sfx
   if p.landed then
    play_sfx("land")
   elseif p.running then
    play_sfx("walk")
   end
  end,

  draw=function(p)
   local cm=p_colors[p.color]
   for c1,c2 in pairs(cm) do
    pal(c1,c2)
   end
   spr(
    p.sp,
    p.x,p.y,
    1,1,
    p.flpx,p.flpy
   )
   pal()
  end,
 },p)
end

--------------------
---player actions---
--------------------

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

 p.flpy=not p.flpy
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
 p.dy-=gravity*1.7
end

----------
---path---
----------

--[[
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
   local cur=popend(open)[1]

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
   "⬅️",
   "➡️",
   "🅾️",
   "🅾️⬅️",
   "🅾️➡️",
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
    🅾️=n.🅾️,

    --pathfinding data
    prev=n,
    btns={}
   }
   --repeat btns until position
   --changes,up to 15 times
   --(see btnp() for threshold)
   for i=1,15 do
    local tap=i==1
     and btns!=prev_btns
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
--invokes btns as player fns
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

--pop last element of t
function popend(t)
 local top=t[#t]
 del(t,top)
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
]]

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

  collide=function(s,cl,p)
   local old_dx=p.dx
   local old_dy=p.dy
   local aim=block(s,cl,p)
   if aim=="⬅️" or aim=="➡️"
   then
    p.dx=-old_dx*10
    p.dy=p.flpy
     and abs(p.dx)
     or -abs(p.dx)
   elseif aim=="⬆️" or aim=="⬇️"
   then
    p.dy=-old_dy*10
    p.dx=p.flpx
     and -abs(p.dx)
     or abs(p.dx)
   end
   spark_aura:on_player(p)
  end,

  update=function(s)
   s.sp=sp_spark_start+
    (t()*10)%sp_spark_length
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
 x,y,to_x,to_y,on
)
 return {
  sp=sp_platform_start,
  x=x,
  y=y,
  w=8,
  h=8,
  dx=0,
  dy=0,
  to_x=to_x,
  to_y=to_y,
  from_x=x,
  from_y=y,
  moving_since=on and time() or false,
  anim_cursor=1,
  anim=anim_platform,

  collide=block,

  update=function(p)
   animate(p,8,true)

   if p.moving_since then
    linear_delta_fn(
      p.from_x,
      p.from_y,
      p.to_x,
      p.to_y
    )(p, p.moving_since)
    p.x+=p.dx
    p.y+=p.dy

    foreach(players,function(pl)
     if intersects(pl:standbox(),p)
     then
      pl.x+=p.dx
      pl.y+=p.dy
     end
    end)
   end
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
 return function(plat, st)
  local f=ef_smooth(
   abs((time()-st+3)%6-3)/3
  )
  plat.dx=x+dx*f+0.5-plat.x
  plat.dy=y+dy*f+0.5-plat.y
 end
end

-----------
---doors---
-----------

function init_door(x,y,open)
 local sp=open
  and sp_door_opened
  or sp_door_closed

 return {
  sp=sp,
  x=x,
  y=y,
  w=8,
  h=8,
  open=open,

  anim_cursor=1,
  anim={sp},

  collide=block,

  update=function(d)
   animate(d,2,false)
  end,

  draw=function(d)
   spr(d.sp,d.x,d.y,1,1)
  end,
 }
end

function toggle_door(d,open)
 d.open=open
 d.anim_cursor=1
 d.anim=open and anim_door_open
  or anim_door_close

 if (open)
   then play_sfx("door_open")
   else play_sfx("door_close")
   end
end

-----------------
---checkpoints---
-----------------

chkpt={}

function set_checkpoint(x,y)
 chkpt={
  x=x,
  y=y,
  restore=function(c)
   local p=player()
   p.x=x
   p.y=y
   p.dx=0
   p.dy=0
   fx_respwan:on_player(p)
   fx_respwan_darker:on_player(p)
   cam:shake()
   play_sfx("respawn")
  end,
 }
end

function init_checkpoint(x,y)
 return init_interactable({
  sp=sp_checkpoint,
  x=x*8,
  y=y*8,
  anim=anim_checkpoint,
  anim_cursor=1,

  on_collide=function(c)
   set_checkpoint(c.x,c.y)
  end,

  on_update=function(c)
   animate(c,2,true)
  end,

  draw=function(c)
   local curr=c.x==chkpt.x
    and c.y==chkpt.y

   with_pal(
    curr and pal_checkpoint_on
     or pal_checkpoint_off,
    sprfn(c.sp,c.x,c.y)
   )
  end,
 },opts)
end

-------------
---buttons---
-------------

function init_button(
 sp,x,y,once,active,on_change
)
 local sp_pal=active
  and pal_default
  or pal_button_off

 return init_interactable({
   sp=sp,
   sp_pal=sp_pal,
   x=x,
   y=y,
   once=once,
   active=active,

   tooltip="🅾️",

   on_button_press=function(b)
    if b.once and b.active != active then
     return
    end

    if (b.once) b.tooltip=nil
    b.active=not b.active
    b.sp_pal=b.active
     and pal_default
     or pal_button_off

    on_change(b)
   end
 })
end

---------------------
---pressure plates---
---------------------

function init_press_plate(
 x,y,active,on_change
)
 return init_interactable({
  sp=20,
  x=x,
  y=y,
  active=true,
  on_change=on_change,

  pressed=false,

  on_update=function(p)
   if (not active) return

   local pressed=p.collided_prev

   if p.pressed!=pressed then
    p.pressed=pressed
    p:on_change()
   end
  end,

  draw=function(p)
   spr(
    p.pressed and 36 or 20,
    p.x,p.y
   )
  end,
 })
end

---------------------
---player unlocker---
---------------------
function init_player_unlocker(
 tx,ty,msg,color,ability
)
 return init_interactable({
  x=tx*8,
  y=ty*8,
  w=8,
  h=8,
  sp=5,
  sp_pal=p_colors[color],
  anim=anim_player_unlocker,
  anim_cursor=1,
  tooltip="🅾️",

  color=color or "red",
  ability=ability or jump,

  msg=msg,
  msg_x=5,
  msg_y=76,
  msg_w=115,
  msg_h=47,

  unlocked=false,

  on_collide=function(u)
   if (u.unlocked) return
  end,

  on_msg_end=function(u)
   add(players,init_player({
    x=u.x,
    y=u.y,
    color=u.color,
    ❎=u.ability,
   }))
   u.tooltip="⬆️"
   u.anim={0}
  end,

  on_update=function(u)
   animate(u,5,true)
  end,

  draw_modal=function(u)
   if u.msg_open then
     local x=u.msg_x+peek2(0x5f28)
     local y=u.msg_y+peek2(0x5f2a)
     local w=u.msg_w
     local h=u.msg_h

     modal(x,y,w,h)

     with_pal(
      u.sp_pal,
      sprfn(7,x+3,y+5)
     )
     print(
      sub(u.msg,1,u.msg_cursor),
      x+4,y+5,
      u.msg_color
     )
     with_pal(
      p_colors.red,
      sprfn(7,x+w-10,y+h-18)
     )
   end
  end,
 })
end

------------
---lasers---
------------

function move_smooth(
 e,from,to,spd
)
 local x=from[1]
 local y=from[2]
 local dx=(to[1]-from[1])+.5
 local dy=(to[2]-from[2])+.5

 --TODO: remove t()
 local f=ef_smooth(
  abs(t()%spd-(spd/2))/(spd/2)
 )

 e.x+=x+dx*f-e.x
 e.y+=y+dy*f-e.y
end

function init_laser(
 from,to,dir,len,on_update
)
 local s=2
 local m=8
 local h=14

 from=from or {0,0}
 to=to or {0,0}
 dir=dir or "h"
 len=mid(1,len,4)\1

 local sp=dir=="h"
  and sp_laser_h+len-1
  or sp_laser_v+len-1

 return init_interactable({
  sp=sp,
  x=from[1],
  y=from[2],
  from=from,
  to=to,
  dir=dir,
  len=len,
  anim={1,2,3,4,5,6,7,8},--frame
  anim_cursor=1,
  frame=1,
  pals={
   [1]={h,m,s,s,s,s,m,h},
   [2]={h,h,m,s,s,s,s,m},
   [3]={m,h,h,m,s,s,s,s},
   [4]={s,m,h,h,m,s,s,s},
   [5]={s,s,m,h,h,m,s,s},
   [6]={s,s,s,m,h,h,m,s},
   [7]={s,s,s,s,m,h,h,m},
   [9]={m,s,s,s,s,m,h,h},
  },

  on=true,

  on_collide=function(l)
   if (l.on) chkpt:restore()
  end,

  on_update=function(l)
   animate(l,1.5,true,"frame")

   move_smooth(
    l,l.from,l.to,5
   )

   if (on_update) on_update(l)
  end,

  draw=function(l)
   if (l.dir=="h") l:draw_h()
   if (l.dir=="v") l:draw_v()
  end,

  draw_h=function(l)
   local x=l.x+4
   local y=l.y+2
   local lhl=rect_laser_h_l
   local lhr=rect_laser_h_r

   if l.on then
    for c1,p in pairs(l.pals) do
     pal(c1,p[l.anim[l.frame]])
    end
    for i=0,l.len-1 do
     spr(l.sp,l.x+i*8,l.y)
    end
    pal()
   end

   ssprrect(lhl,l.x,l.y)
   ssprrect(lhr,l.x+l.len*8,l.y)
  end,

  draw_v=function(l)
   local x=l.x+4
   local y=l.y+2
   local lvu=rect_laser_v_u
   local lvd=rect_laser_v_d

   if l.on then
    for c1,p in pairs(l.pals) do
     pal(c1,p[l.anim[l.frame]])
    end
    for i=0,l.len-1 do
     spr(l.sp,l.x,l.y+i*8)
    end
    pal()
   end

   ssprrect(lvu,l.x,l.y)
   ssprrect(lvd,l.x,l.y+l.len*8)
  end,
 })
end

-->8
--fxs:player,bg,lights

----------------
---player fxs---
----------------

particles={}

function fire_fxs()
 foreach(
  players,
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

  if fget(mget(
   (f.x+f.r)/8,(f.y+f.r)/8),
   flag_block
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
fx_respwan=class(spark_aura,{
 colors={12},
 amount=15,
})

fx_respwan_darker=class(fx_respwan,{
 colors={1},
})

--------------------
---background fxs---
--------------------

bg_particles={}

bg_fx={
 t=0,
 c=0,
 dx=0,
 colors={1},

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
  f.t+=1
  f.t%=f.life
 end,
}

circle_bg_fx=class(bg_fx,{
 r=4,
 life=fps/6,

 draw=function(f)
  circfill(f.x,f.y,f.r,f:curr_color())
 end,
})

thruster={
 add=function(_, x, y)
  x*=8 y*=8
  thr_dark:add(x-6,y+4)
  thr_mid:add(x-3,y+2)
  thr_bright:add(x,y)
 end
}

thr_bright=class(circle_bg_fx, {
 colors={7,12},

 add=function(kls, x, y)
  kls:add_particle{
   x=x, y=y
  }
  kls:add_particle{
   x=x, y=y+7
  }
  kls:add_particle{
   x=x, y=y+14
  }
  kls:add_particle{
   x=x, y=y+20
  }
 end,
})

thr_mid=class(circle_bg_fx, {
 colors={12,1},

 add=function(kls, x, y)
  kls:add_particle{
   x=x, y=y
  }
  kls:add_particle{
   x=x, y=y+6
  }
  kls:add_particle{
   x=x, y=y+12
  }
  kls:add_particle{
   x=x, y=y+16
  }
 end,
})

thr_dark=class(circle_bg_fx, {
 colors={1,0},

 add=function(kls, x, y)
  kls:add_particle{
   x=x, y=y
  }
  kls:add_particle{
   x=x, y=y+7
  }
  kls:add_particle{
   x=x, y=y+12
  }
 end
})

pixel_star=class(bg_fx,{
 add_plane=function(kls)
  for i=1,100 do
   kls:add_particle({
     x=rnd(256)\1,
     y=rnd(256)\1,
     life=30+rnd(90)*fps,
   })
  end
 end,

 update=function(f)
  bg_fx.update(f)

  f.x+=f.dx
  f.x%=256
  f.c=f:curr_color()
 end,

 draw=function(f)
  pset(
   cam:inv_x(f.x),
   cam:inv_y(f.y),
   f.c
  )
 end,
})

far_star=class(pixel_star,{
 colors={5,6},
 dx=-5*1/fps,
})

near_star=class(pixel_star,{
 colors={7,15},
 dx=-5*6/fps,
})

moon=class(bg_fx,{
 add=function(m)
  m:add_particle({})
 end,

 update=function(m) end,

 draw=function(m)
  ssprrect(
   rect_moon,
   cam:fixed_x(86),
   cam:fixed_y(8)
  )
 end
})

ship=class(bg_fx,{
 add_all=function(s)
  local max_ships=4

  --small ship
  for i=1,max_ships do
   local sp,r

   --max_ships-1 small ships
   --1 medium ship
   if i<=max_ships-1 then
    sp=sp_ship_s
    r=rect_ship_s
   else
    sp=sp_ship_m
    r=rect_ship_m
   end

   s:add_particle{
    sp=sp,
    r=r,
    x=-rnd(96)-32,
    y=64+rnd(48),
    dx=0.5+rnd(1.1)^2,
    dy=0,
   }
  end
 end,

 update=function(s)
  s.dy+=rnd(0.01)-0.005
  s.dy=sgn(s.dy)*min(
   abs(s.dy),s.dx)

  s.x+=s.dx
  s.y+=s.dy

  if (s.x>256) s.x-=384
 end,

 draw=function(s)
  ssprrect(
    s.r,
    cam:inv_x(s.x),
    cam:inv_y(s.y)
  )
 end
})

----------------
---lights fxs---
----------------

light_masks={4,11,15}
light_freqs={
 [11]=7,
 [4]=7,
 [15]=11,
}
light_seqs={
 [11]={12,12,1,0,1},
 [4]={8,12,1},
 [15]={8,12,12,3,12,8,12,12},
}

function animate_map()
 for m in all(light_masks) do
  local f=light_freqs[m]
  local s=light_seqs[m]
  local c=mid(
   0,
   abs((cos(t()/f))*(#s-1))\1,
   #s-1
  )

  pal(m,s[c+1])
 end
end

--------------------
---speech bubbles---
--------------------

function speech_bubble(x,y,l,c)
  local r=rect_tooltip
  local dx=x-4
  local dy=y-12+cos(t()/2)+.5

  pal(11,c)
  ssprrect(r,dx,dy)
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

--https://www.1001fonts.com/tinier-font.html
tiny_font={
 a=split("0,0,3,3"),
 b=split("0,3,3,3"),
 c=split("0,6,3,3"),
 d=split("0,9,3,3"),
 e=split("0,12,3,3"),
 f=split("0,15,3,3"),
 g=split("0,18,3,3"),
 h=split("0,21,3,3"),
 i=split("3,0,1,3"),
 j=split("3,3,2,3"),
 k=split("3,6,3,3"),
 l=split("3,9,2,3"),
 m=split("3,12,5,3"),
 n=split("3,15,4,3"),
 o=split("3,18,3,3"),
 p=split("3,21,2,3"),
 q=split("8,0,3,3"),
 r=split("8,3,3,3"),
 s=split("8,6,3,3"),
 t=split("8,9,3,3"),
 u=split("8,12,3,3"),
 v=split("8,15,3,3"),
 w=split("8,18,5,3"),
 x=split("8,21,3,3"),
 y=split("11,0,3,3"),
 z=split("11,3,3,3"),
 [1]=split("11,6,2,3"),
 [2]=split("11,3,3,3"), --z
 [3]=split("11,9,3,3"),
 [4]=split("11,12,3,3"),
 [5]=split("8,6,3,3"), --s
 [6]=split("11,15,3,3"),
 [7]=split("13,18,3,3"),
 [8]=split("11,21,3,3"),
 [9]=split("13,2,3,3"),
 [0]=split("13,6,3,3"),


 ["<"]=split("3,18,2,3"),
 [">"]=split("4,18,2,3"),
 [" "]=split("5,9,3,3"),
}

function print_tiny(str,x,y,c)
 local chars=split(str,"")
 local sc=sp_coords(
  sp_tiny_font
 )
 local cursor=0

 for char in all(chars) do
  local r=tiny_font[char]
  --dropshadow
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

---------------------------
---modals, interactables---
---------------------------
dialog_open=false
function modal(x,y,w,h)
 local cbg=1
 local ct=7
 local cb=6
 local cs=5

 --bg
 rectfill(x,y,x+w,y+h,cbg)
 --top
 rectfill(x+1,y,x+w,y,ct)
 --right
 rectfill(
  x+w+1,y+1,x+w+1,y+h-1,ct
 )
 --bottom
 rectfill(x+1,y+h,x+w,y+h,cb)
 --left
 rectfill(x,y+1,x,y+h-1,cb)
 --shadow
 pset(x,y,cs)
 --shadow
 pset(x,y+h,cs)
 --shadow
 rectfill(x-1,y+1,x-1,y+h-1,cs)
 --shadow
 rectfill(
  x+1,y+h+1,x+w-1,y+h+1,cs
 )
 --inner shadow
 rectfill(x+1,y+1,x+w,y+1,cs)
 --inner shadow
 rectfill(x+w,y+1,x+w,y+h-1,cs)
end

function init_animated(opts)
 return instance({
  x=0,
  y=0,
  sp=0,
  anim={0},
  anim_cursor=1,
  anim_freq=5,
  anim_loop=true,

  update=function(a)
   animate(
    a,a.anim_freq,a.anim_loop
   )
  end,

  draw=function(a)
   spr(a.sp,a.x,a.y)
  end,
 }, opts)
end

function init_interactable(opts)
 local original_freq=
  opts.msg_freq or 1

 return instance({
  sp=0,
  sp_pal={},
  x=0,
  y=0,
  w=8,
  h=8,

  msg_x=7,
  msg_y=16,
  msg_w=113,
  msg_h=87,
  msg=nil,
  -- msg_type=nil,
  msg_color=12,
  msg_open=false,
  msg_cursor=1,
  msg_freq=1,
  msg_max_freq=5,
  on_msg_end=function(s) end,

  tooltip=nil,

  on_button_press=function(s) end,
  on_collide=function(s) end,
  on_update=function(s) end,

  collided_prev=false,
  collided_at=0,

  collide=function(b)
   b.collided_at=time()
  end,

  update=function(s)
   if (s.on_update) s:on_update()

   local collided=
    s.collided_at==time()
   s.collided_prev=collided

   if collided then
    s:on_collide()
   end

   local interacted=
    collided and btnp(🅾️)

   if interacted then
    s:on_button_press()
   end

   if s.msg then
    local just_opened=false

    if interacted
    and not s.msg_open
    then
     s.msg_open=true
     s.msg_cursor=0
     just_opened=true
     disable_player_input()
    end

    if s.msg_open then
     if s.msg_cursor<#s.msg then
      s.msg_cursor+=s.msg_freq;
      play_sfx(
       s.msg_freq==original_freq
       and "text_type_slow"
       or "text_type_fast"
      )

      if interacted
      and not just_opened
      then
       s.msg_freq=mid(
        original_freq,
        s.msg_freq*2,
        s.msg_max_freq
       )
      end
     else
      if interacted then
       s.msg_freq=original_freq
       s.msg_open=false
       enable_player_input()
       s:on_msg_end()
     end
    end
   end
  end
 end,

 draw=function(s)
  with_pal(
   s.sp_pal,
   sprfn(s.sp,s.x,s.y)
  )

  if s.tooltip
  and not s.msg_open
  and s.collided_prev
  then
   local c=
    p_colors[player().color][8]

   speech_bubble(
    s.x+2,s.y-2,s.tooltip,c
   )
  end
 end,

 draw_modal=function(s)
  if s.msg_open then
   local x=s.msg_x+peek2(0x5f28)
   local y=s.msg_y+peek2(0x5f2a)
   modal(x,y,s.msg_w,s.msg_h)

   print(
    sub(s.msg,1,s.msg_cursor),
    x+4,y+5,
    s.msg_color
   )
  end
 end,
 },opts)
end

function sprfn(s,x,y)
  return function()
    spr(s,x,y)
  end
end

function with_pal(cm,fn)
  for c1,c2 in pairs(cm) do
    pal(c1,c2)
  end
  fn()
  pal()
end

-->8
--sound effects,music

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
 door_open={i=3,o=0,l=4},
 door_close={i=3,o=4,l=4},
 platform_on={i=3,o=8,l=2},
 text_type_slow={i=4,o=0,l=4},
 text_type_fast={i=4,o=4,l=4},
 start_game={i=6,o=0,l=6},
 respawn={i=7,o=0,l=32},
}

function play_sfx(_sfx)
 local idx=sfx_map[_sfx].i

 if stat(16)==idx
 or stat(17)==idx
 or stat(18)==idx
 or stat(19)==idx
 then
  return
 end

 sfx(
  idx,
  -1,
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

--music_tracks={
-- bass_2bars={i=8,o=0,l=32},
-- bass_4bars={i=9,o=0,l=32},
--}


-->8
--[[tests:to run,prepend dash(-)

function test(fn)
 return fn()
end

cls()
stop("all tests pass.")

--]]

__gfx__
00000000000000000000000000666600000000000000000000000000006666000777777000000000000000000566667005666670056666700561617000101000
00000000006666000066660006611c600066660000000000006666000611cc6061ccc11700000000000000000566667005666670056161700010100000000000
0000000006611c6006611c600661116006611c600066660006611c60511111c6611111c700000000000000000566667005616170001010000000000000000000
000000000661116006611160006666000661116006611c60066111605111111661c1ccc706670000000066700561617000101000000000000000000000000000
0000000000666600006666000088a8000066660006611160776666000511115061111117063b000000003b600516167000010100000000000000000000000000
000000000088a8000088a800008888000088a800006666007788a800005555000666666006330000000033600566667005161670000101000000000000000000
00000000008888000088880006000060068888000088a8000a8888000088a8000006700006660000000066600566667005666670051616700001010000000000
00000000006006000060006000000000000006000688886090600600008888000006700006660000000066600566667005666670056666700516167000010100
00000777777770000000000000000000577777750000000000000000077777700777777007777770077777700000777770000000000000000057777777000000
0007777777777777770000000000000026666662005505000555000056666667566666675666666756666667007777777777700000000000057bbbbbbb700000
007776767676777777777770000000000222222006225255522250000555555005555550055555500555555007777667677777777000000057bbbbbbbbb70000
077767666766666666666667770000006666666606222222222225000490009000000000000000000049990077676666666666666770000057bbbbbbbbb70000
777676766666666666666666667000006666666600622222222225000049990000490900000000000004400006766666666ddddd6667000057bbbbbbbbb70000
076766666666666666666666666700005555555500622222222222500004400000049000000000000000000000666666667d666dd666700057bbbbbbbbb70000
007676666666666555555556666670000000000000062222222225000000000000000000000499000000000000099999997d61cdd9999a0057bbbbbbbbb70000
000666666666667dddddddd5666667000000000000622222222225000000000000000000000040000004900000066666667d666dd6666670057bbbbbbb700000
000099999999997dd6666dd5999999f05555555506222222222250000000000000000000000000000000000000099999997d333dd999940000577bbb77000000
000066666666667d6611c6d56666666757777775006222222222250000000000000000000000000000000000006666666665555566665000000557b700000000
000099999999997d661116d5999999942666666200622222222222500000a0000000a0000000a000000070000656666666666666666500000000057000000000
000099999999997dd6666dd599999940622222260622222222222250000a7000000aa000000aa0000007a0005565666666666666655000000000000000000000
000666666666667dd88a8dd56666650066666666062222222222225000a7a90000aa790000aaa900007aa9000555566565555555500000000000000000000000
00565666666666677777777666665000555555550622666226226600000a900000079000000a9000000a90000055555555555000000000000000000000000000
05656666666666666666666666650000000000000066000660660000000900000009000000090000000900000000555550000000000000000000000000000000
55565656666666666666666666500000000000000000000000000000000000000000000000000000000000000000000007700770000000000000000000000000
055565666566666666666665550000000050050000000000000000000077770000000000077777700777777007777770566756670000000000cc0c0000ccc000
005556565656555555555550000000000625525000000000000000000766667770000000611111176118811761111117565ee56700000000cc0101c00cc11c00
000555555555555555000000000000006222222500000000000000007666666667000000611111176118811761111317566756670000000000c0c00000ccc000
000005555555500000000000000000000611a215000000000000000006666d5d6670000061111117611111176131311705500550000000000e0c000000ece000
0000000000000000000000000000000006221225000000000000000009999d3d994000006111111761188117611311170777007e700000000c000e0000cfc000
00000000000000000000000000000000622212500000000000000000566666666500000006666660066666600666666056667565670000000000f0c000000000
00000000000000000000000000000000066215000000000000000000056666555000000000067000000670000006700056567566670000000566670005666700
00000000000000000000000000000000000660000000000000000000005555000000000000067000000670000006700005e50055500000005666667056666670
77777777777777777766667777777777777777777777777777777777dddddddddddddddddd645ddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666666666666666666666666666666dddddddddddddddddd6f5dddddddddddddd555555555555555555ddddddddddddddddddd
66666666666666666666666666666666666666666666666666666666dddddddddddddddddd6f5ddddddddddddd50000000000000000005dddddddddddddddddd
66666666666666666666666666666666666666666666666666666666555555555555555555f4f555dd555555d6000000000000000000005ddddddddddddddddd
66666666666666666666666666666666666666666666666666666666fffff4444ffff4f4ff444ff4d5fff444d6000000000000000000005ddddddddddddddddd
55555555566666655555555555555555555555555555555555555555666666666666666666666666dd666666d6000000000000000000005ddddddddddddddddd
ddddddddd566667ddddddddddd6f5ddddd6000c000b000c000b005ddddddddddddddddddddddddddddddddddd6000000000000000000005dddddddd66ddddddd
ddddddddd566667ddddddddddd6f5ddddd60000000000000000005ddddddddddddddddddddddddddddddddddd6000000000000000000005ddddddd5006dddddd
d566667d7766667dd5666677d566667dd566667dc566667dd5666670dd6f5ddddd645ddddd645dddddddddddd6000000000000000000005ddddddd5006dddddd
d566667d6666667dd5666666d566667dd566667d0566667dd5666670dd6f5ddddd645ddddd645dddddddddddd6000000000000000000005dddddddd55ddddddd
d566667d6666667dd5666666d566667dd566667d0566667dd566667cdd645ddddd645ddddd645dddddddddddd6000000000000000000005ddddddddddddddddd
d566667d6666667dd56666665566667dd56666750566667dd5666670dd645ddddd645ddddd64f555555555ddd6000000000000000000005ddddddddddddddddd
d566667d6666667dd56666664566667dd566667fc566667dd5666670dd6f5ddddd6f5ddddd644fff4ffff45dd6000000000000000000005ddddddddddddddddd
d566667d5666667dd56666656566667dd56666760566667dd5666670dd645ddddd6f5ddddd6f4666666666ddd6000000000000000000005ddddddddddddddddd
d566667dd566667dd566667dd566667dd566667d0566667dd566667cdd6f5ddddd645ddddd6f5dddddddddddd6000000000000000000005ddddddddddddddddd
d566667dd566667dd566667dd566667dd566667d0566667dd5666670dd6f5ddddd645ddddd645dddddddddddd6000000000000000000005ddddddddddddddddd
d566667ddddddddddd777777777777dd7766667dd566667dd566667ddddddddddddddddddd645dddddddddddd6000000000000000000005d0000000000000000
d566667ddd7777ddd56666666666667d6666667dd566667dd5666675dddddddddddddddddd645dddddd5ddddd6000000000000000000005d0000000000000000
d566667dd566667dd56666666666667d6666667d5566667dd5666670dddddddddddddddddd645ddddd645dddd6000000000000000000005d0000000000000000
d566667dd566667dd56666666666667d666666750566667dd5666670ddd555555555dddd66445ddddd645dddd6000000000000000000005d0000000000000000
d566667dd566667dd56666666666667d6666667fc566667dd5666670dd64444ff4445dddfff45ddddd6f5dddd6000000000000000000005d0000000000000000
d566667dd566667dd56666655666667d566666760566667dd5666670dd6ff66666f45ddd66ff5ddddd645ddddd60000000000000000005dd0000000000000000
dd5555ddd566667dd566667dd566667dd566667d0566667dd566667cdd6f5ddddd6f5ddddd645ddddd6f5dddddd666666666666666666ddd0000000660000000
ddddddddd566667dd566667dd566667dd566667d0566667dd5666670dd6f5ddddd6f5ddddd645ddddd6f5ddddddddddddddddddddddddddd0000005dd6000000
d77777777777777dd56666677666667dd5666677c566667dd5666670dd645ddddd6f5ddddddddddddd645dddd666666dd666666ddddddddd0000005dd6000000
5666666666666667d56666666666667dd56666660566667dd5666670dd645ddddd6f5ddddddddddddd645ddd51111ff651111116dddddddd0000000550000000
5666666666666667d56666666666667dd56666660566667dd566667cdd6f5ddddd645ddddddddddddd645ddd5144111651ffff46ddddd6dd0000000000000000
5666666666666667d56666666666667d556666660566667dd5666670dd6f455555445ddddddddddddd645ddd5111414651111116dddddadd0000000000000000
5666666666666667d56666666666667df5666666c566667dd5666670dd6f44fff44f5ddddddddddddd6f5ddd51f14116514441f6ddddd9dd0000000000000000
d55555555555555ddd555555555555dd656666650566667dd5666676ddd666666666dddddddddddddd6f5ddd5111114651111116ddddd5dd0000000000000000
ddddddddddddddddddddddddddddddddd566667d6566667dd566667dddddddddddddddddddddddddddd5dddd51fff14651f14446dddddddd0000000000000000
ddddddddddddddddddddddddddddddddd566667dd566667dd566667dddddddddddddddddddddddddddddddddd555555dd555555ddddddddd0000000000000000
0e0e00000e0e0e000077777777777700dd777777777777ddddddddddddddddddddddddddddddddddddddddddddddddddc000b000c000b000dddddddddddddddd
e0ee0000e0e0eeee0566666666666670d56666666666667dddddddddddddddddddddddddddddddddd555555ddddddddd0000000000000000dddddddddddddddd
e0ee00000ee0eeee0566666666666670d56666666666667dddddddddddddddddddddddddddddddd550c000c55ddddddd00c000c000c000c0dddddddddddddddd
ee00e000ee0ee00e0566666666666670d56666666666667dddddddddddddddddddddddddddddd65000000000055ddddd0000000000000000dddddddddddddddd
eee0e000ee00e0000566666666666670d56666666666667ddddddddddddddddddddddddddddd6000c000c000c005ddddc000c000c000c000dddddddddddddddd
ee0e0000e0e0ee000566666556666670d56666655666667dddddddddddddddddddddddddddd600000000000000005ddd0000000000000000dddddddddddddddd
0eee0e000eeeeeee0566667dd5666670d56666700566667dddddddddddddddddddddddddddd600c000b000c000b05ddd00b000c660b000c0ddddddd66ddddddd
e00ee0000e00ee0e0566667dd5666670d56666700566667ddddddddddddddddddddddddddd60000000000000000005dd0000005dd6000000dddddd5006dddddd
0eee0e00ee00eeee0566666776666670d56666677666667ddddddddddddddddddddddddddd60b000c000b000c000b5ddc000b05dd600b000dddddd50c6dddddd
ee0e0000eeeee0000566666666666670d56666666666667dd766666dddddddddddddddddd6000000000000000000005d0000000550000000ddddddd55ddddddd
e0ee00000e00ee000566666666666670d56666666666667ddc11115dddddddddddddddddd6c000c000c000c000c0005d00c000c000c000c0dddddddddddddddd
ee0ee0000e0ee0000566666666666670d56666666666667dddd555ddddddddddddddddddd6000000000000000000005d0000000000000000dddddddddddddddd
eeee000ee0ee0e000566666666666670d56666666666667dddddddddddddddddddddddddd600c000c000c000c000c05dc000c000c000c000dddddddddddddddd
ee0ee0eee0eeee000055555555555500dd555555555555ddddddddddddddddddddddddddd6000000000000000000005d0000000000000000dddddddddddddddd
eeee0e0eeee00e000000000000000000ddddddddddddddddddddddddddddddddddddddddd6b000c000b000c000b0005d00b000c000b000c0dddddddddddddddd
eeee00e0e0ee00000000000000000000dddddddddddddddddddddddddddddddddddddddddd60000000000000000005dd0000000000000000dddddddddddddddd
ee0ee0e0e0eeee000566667dd56666707777777777666677dddddddddddddddddddddddddd60b000c000b000c000b5ddc00007777777b000c00007777777b000
e00e0ee00e0eee000566667dd56666706666666666666666d666667dddddddddddddddddddd600000000000000005ddd00005666666650000000566666665000
e000e000e000eeee0566667dd56666706666666666666666d51111cdddddddddddddddddddd600c000c000c000c05ddd00c56666666500c000c56666666500c0
e0ee0e00e0e0e00e0566667dd56666706666666666666666dd555ddddddddddddddddddddddd6000000000000006dddd00005666665000000000566666500000
eee0e0000e0e00e00566667dd56666706666666666666666ddddddddddddddddddddddddddddd660c000c000c66dddddc00566666665c0000005666666650000
e0eee000e0e0ee000566667dd56666705555555555555555ddddddddddddddddddddddddddddddd6600000066ddddddd00005555555000000000555555500000
eeeee0000e0eee000566667dd56666700000000000000000ddddddddddddddddddddddddddddddddd666666ddddddddd00b000c000c000b00000000000000000
e0ee0000e0eee0000566667dd56666700000000000000000dddddddddddddddddddddddddddddddddddddddddddddddd00000000000000000000000000000000
777777777777777705666677776666700777777777777770000000000000000000000000000000000090000000900000009000000090000000000000c000b000
66666666666666660566666666666670566666666666666701230000012300000123000001230000008100000081000000810000008100000000000000000000
66666666666666660566666666666670566666666666666798884888988848889888488898884888008200000082000000820000008200000000000000b000c0
66666666666666660566666666666670566666666666666700000567000005670000056700000567008300000083000000830000008300000000000000000000
66666666666666660566666666666670566666666666666700000000000000000000000000000000004000000040000000400000004000000000000000000000
56666665566666650566666556666670055555555555555000000000000000000000000000000000058000000580000005800000058000000000000000000000
0566667dd56666700566667dd5666670000000000000000000000000000000000000000000000000068000000680000006800000068000000000000000000000
0566667dd56666700566667dd5666670000000000000000000000000000000000000000000000000078000000780000007800000078000000000000000000000
000000000000000000000000000000000000000000000000000077000000000000000000d5666677000000000000000000000000000077777777000000000000
000000000000000000000000000000000000000007700777770770000000000000000000d5666666000000000000000000000000077766666666777000000000
000000000000000000000000000000000000000097009799779770000000000000000000d5666666000000000000000000000000766666666666666700000000
000000000000000000000000000000070000000477747749779770000000000000000000d5666666000000000000000000000077666666566666666677000000
000000000000000000000000000000977700000777097749749970000000000000000000d5666666000000000000000000000766666666666666666666700000
000000000000000000000000000004777000009977499077044900007000000000000000d5666665000000000000000000007666666666666666566666670000
000000000000000000000000007709977000044997740990004000077000000000000000d56666700000000000000000000666666ddd666676666666dd667000
000000000000000000000000779077997700004499004400000000977000000000000000d56666700000000000000000000666667555d6666666666d55d67000
000000000000000000077779770977497777000440000000777774970000000000000000000000000000000000000000006666667555d66666666667d5d66700
0000000000070000007997797749774999900000000070077999779000000000000000000000000000000000000000000666666667776666666666667d666670
000000000077777707749779777770444400000000770779774977007700000000000000000000000000000000000000066666666666666666ddd66666666670
0000777779779977977497499799000000000770077097797749770990000000000000000000000000000000000000000666d6666666666667555d6666666670
00079999497749779777774494400007700779779774977977499044000000000000000000000000000000000000000066675d666666d666667dd66666666667
00774447499779977999900400770077707749779774774990440000000000000000000000000000000000000000000066667666666666666666666666d66667
09977770779774994444000009777777797749779977904400000000000000000000000000000000000000000000000066666666666666666666666666766667
44999907749904400000000049777797799777774994000000000000000000000000000000000000000000000000000066666666666666666666666666666667
044477790440000000777000499774997799799044000000000000000000000000000000000000000000000000000000d666656666666566666dddd66666d667
000799400000000009790770449774497449440000000000000000000000000000000000000000000000000000000000d66666666666666666d5555d66675d67
009440000077777747777700049770490040000000000000000000000000000000000000000000000000000000000000dd666666666666666d555555d6667667
040007770977997797799000049900400000000000000000000000000000000000000000000000000000000000000000dddddd6666666666755555555d666667
0000777049774977977770000440000000000000000000000000000000000000000000000000000000000000000000000dd55dd666666666755555555d666670
0009977049774977999900000000000000000000000000000000000000000000000000000000000000000000000000000d5555dd66766666755555555d666670
0044977049977994444000000000000000000000000000000000000000000000000000000000000000000000000000000dd5555d66d76666755555555d666670
00049977779944000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd555d6666666667555555d6666700
000449999440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd5dd666666666675555d66666000
000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddd665666666666777766666d000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddd6666666656666666666d0000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddd666666666666666dd00000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddddd666666666dddd000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddddddddddddddd00000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddddddddddddd000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddddddd000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000750000000000000000000070
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000
00000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000077000000000000000000000000000000000000777777770000000000000000000000
00000000000000000000000000000000000000000000000007700777770770000000000000000000000000000000000777666666667770000000000000000000
00000000000000000000000000000000000000000000000097009799779770000000000000000050000000000000007666666666666667000000000000000000
00000000000000000000000000000000000000070000000477747749779770000000000000000000000000000000776666665666666666770000000000000000
00000000000000000000000000000000000000977700000777097749749970000000000000000000000000000007666666666666666666667000000000000000
00000000000000000000000000000000000004777000009977499077044900007000000000000000000000007076666666666666665666666700000000000000
00000000000000000000000000000000007709977000044997740990004000077000000000000000000000000666666ddd666676666666dd6670000000000000
00000000000000000000000000000000779077997700004499004400000000977000000000000000000000000666667555d6666666666d55d670000000000000
00000000000000000000000000077779770977497777000440000000777774970000000000000000000000006666667555d66666666667d5d667000000000000
000000000000000000070000007997797749774999900000000070077999779000000000000000000000000666666667776666666666667d6666700000000000
00000000000000000077777707749779777770444400000000770779774977007700000000000000000000066666666666666666ddd666666666700000000000
000000000000777779779977977497499799000000000770077097797749770990000000000000000000000666d6666666666667555d66666666700000000000
0000000000079999497749779777774494400007700779779774977977499044000000000000000000000066675d666666d666667dd666666666670000000000
0000000000774447499779977999900400770077707749779774774990440000000000000000000000000066667666666666666666666666d666670000000000
00000000099777707797749944440000097777777977497799779044000000000000000000000000000000666666666666666666666666667666670000000000
00000000449999077499044000000000497777977997777749940000000000000000000000000000000000666666666666666666666666666666670000000000
00000000044477790440000000777000499774997799799044000000000000000000000000000000000000d666656666666566666dddd66666d6670000000000
00000000000799400000000009790770449774497449440000000000000000000000000000000000000000d66666666666666666d5555d66675d670000000000
00000000009440000077777747777700049770490040000000000000000000000000000000000000000000dd666666666666666d555555d66676670000000000
00000000040007770977997797799000049900400000000000000000000000000000000000000000000000dddddd6666666666755555555d6666670000000000
000000000000777049774977977770000440000000000000000000000000000000000000000000000000000dd55dd666666666755555555d6666700000000000
000000000009977049774977999900000000000000000000000000000000000000000000000000000000000d5555dd66766666755555555d6666700000000000
000000000044977049977994444000000000000000000000000000000000000000000000000000000000000dd5555d66d76666755555555d6666700000000000
0000000000049977779944000000000000000000000000000000005000000000000000000000000000000000dd555d6666666667555555d66667000000000000
00000000500449999440000000000000000000000000000000000000000000000000000000000000000000000dd5dd666666666675555d666660000000000000
00000000000044440000000000000000000000000000000000000000000000000000000000000000000000000dddd665666666666777766666d0000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddd6666666656666666666d00000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddd666666666666666dd000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddddd666666666dddd0000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddddddddddddddd000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddddddddddddd0000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddddddd0000000000000000000000
00000000000000005000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000
00000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000007777700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000070000000777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000007777667677777777000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000077676666666666666770000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006766666666ddddd6667000000000000000000000000050000000000000000000000000000000000000000000000
00000000000000000000000000000000000000666666667d666dd666700000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000099999997d61cdd9999a0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000066666667d666dd666660000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000099999997d333dd999940000000000000000000000000000000000000000000000000000000000500000000000
00000000000000000000000000000000000000666666666555556666500000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006566666666666666665000000000000000000000000000000000000000000000000000000000000000000000000
000000005000000000000000000000aaa0aaa5aaa66aa66aa666655aaaaa0000a0a0a00000aaa00aa00000aaa0a000aaa0a0a000000000000000000000000000
000000000000000000000000000000a0a0a0a5a556a565a5555550aa0a0aa00a00a0a000000a00a0a00000a0a0a000a0a0a5a000000000000000000000000000
000000000000000000000000000000aaa0aa00aa55aaa5aaa00000aaa0aaa00a000a0000000a00a0a00000aaa0a000aaa0aaa000000000000000000000000000
000000000000000000000000000000a000a0a0a00000a000a00000aa0a0aa00a00a0a000000a00a0a00000a000a000a0a000a000000000000000000000000000
000000000000000000000000000000a000a0a0aaa0aa00aa0000000aaaaa00a000a0a000000a00aa000000a000aaa0a0a0aaa000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007777000000000000000000000000000000000000000000000000000000000777700000000000000000000000000000000000000000000000000000000
00000076666777000000000000000000000000000000000000000000000000000007666677700000000000000000000000000000000000000000000000000000
00000766666666700000000000000000000000000000000000000000000000000076666666670000000000000000000000000000000000000000000000000000
0000006666d5d6600000000000000000000000000000000000000000000000000006666d5d660000000000000000000000000000000000000000000000000000
0000009999d3d9900000000000000000000000000000000000000000000000000009999d3d990000000000000000000000000000000000000000000000000000
00000566666666500000000000000000000000000000000000000000000000000056666666650000000000000000000000000000000000000000000000000000
00000056666555000000000000000000000000000000000000000000000000000005666655500000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000700000000000000000007000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055555000555550000005550505055000000000000000555550000505050000055505050555055500000000000000555550000505550000050500550555000
00555005505507555005005050505050500000000000005505055075005050050005005050555050500000000000005500055005000050050050505000500000
00550005505500055000005500505050500000000000005550555005000500000005005050505055500000000000005505055005000500000050505550550000
00555005505500555005005050505050500000000000005505055005005050050005005050505050000000000000005500055005005000050050500050500000
00055555000555550000005050055050500000000000000555550050005050000055000550505050000000000000000555550050005550000005505500555000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0001010101010100010101010101010100000000010101010101010000000000000000000101010101010100000000000000000001000000000000000000010101010101010101000000000000000000010101010101010000000000000000000101010101010100000000000000000001010101010101000000000000000000
0000010101010001010000000000000000000101010100000000000000000000000001010101000000000000010101010101010101010101010101010101020000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
bebebebebebebebebebebebebebebebebebebebebebe824040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404083bebebebebebebebebebebebebebebebebebebe
be000000000000000000000000000000000000008240514b4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4d7979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797994408300000000000000000000000000000000be
be000000000000000000000000000082404040409579505b000000000000000000000000000000000000005d7979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797979797979799440830000000000000000000000000000be
be000000000000000000000000824095797979797979505b000000000000000000000000000000000000005d796a79797962404040404040404040404040404040409a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a7979797979797979944083000000000000000000000000be
be0000000000000000000082409579797979898a8a8b505b000000000000000000000000000000000000005d7957797979509a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a79797979797979797994408300000000000000000000be
be0000000000824040404095797979898a8a9a9a9a9c655b0000001800b4a4a4b500000000b4a4a4b500005d7958797979509a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a797979797979797979799440830000000000000000be
be0000000082957979797979898a8a9a9a9a9a9a9a9a556b6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6d7957797979509a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a797979797979797979797979944083000000000000be
be0000008295797979898a8a9a9a9a9a9a9a9a9a9a9a55797979796a797979797979797979797962404040637957797979509a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a797979797979797979797979797994408300000000be
be824040957979898a9a9a9a9a9a9a9a9a9a9a9a9a9a5579794a7b4947477b477c477c7b6862437379799650797a797979509a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a7979797979797979797979797979799440830000be
bea27979797979999a9a9a9a9a9a9a9a9a9a82404445454640404040404040404040404040735779797979507979797979509a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a7979797979797979797979797979797979944083be
bea27979797979a98d9a9a8240404040404073a6a9aaaaab7b797979797979797979797979795879704043517979797979524040404040404040404040404040404040404040404040404040404340404040404040839a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a797979797979797979797979797979797979799483
be92a4a485797979a9aa8d55a6797b79797979797b48484849477b487c79674748484747474849687967785079797979796079797979797979797979794b4c4c4c4c4c4c4c4c4c4d79797979795879797979797979569a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a7979797979797979797979797979797979797979a3
be0000009285797979899d55797979797979797979797979797979795879577979797979796240404040405179797979797979797979797979797979795b5c5c5c5c5c5c5c5c5c5d79797979795779797979797979569a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a7979797979797979797979797979797979797979a3
be0000000092b04040404351674848474848474847484748484747484947787979898a8a8b50a67979797950796a7979797979797979797979797979796b6c6c6c6c6c6c6c6c6c6d79797967476979797979797979569a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a7979797979797979797979797979797979797979a3
b243404040436448477c4953577979797979797979797979797979797979797979a98dac46644868797979507957797970637979797979797979797979797979797979797979797979797958797748474847487968569a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a7979797979797979797979797979797979797979a3
a257797c7958507979797950587979797071797979707179797970717979797979899d9a9c657957797979507958797979c94545454545454545454545454545454545454545454545454545454545454545454545939a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a7979797979797979797979797979797979797979a3
a27b4749477b5271796a7950587979797979797979797979797979797979797979999a9a9a556749487043517958797979569a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a7979797979797979797979797979797979797979a3
a27747477c78507979577950587979797979797979797979797979794b4c4c4d7962404040515779797977537957797979569a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a797979797979797979797979797979797979798493
a279797958797979795779505779797979898b79898a8a8b797979795b5c5c5d7954477b47537979797979544869797979569a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a797979797979797979797979797979797984a493be
92a4a4a4a4a4b0717957795058797979899a9c8a9a9a9a9c8a8a8b796b6c6c6d7950a6797972404071797960795779797952404040404040839a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a79797979797979797979797979797984a4930000be
be0000000082957979577972436379899a9a9a9a9a9a9a9a9a9a9a8b79797979795079797979797979797979795779797950797979797979569a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a7979797979797979797979797984a49300000000be
be0000008295797979597b48697240adac45ad9aac45ad9aac45ad9b70637979797979797979797979797979797a79797950797979797979569a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a797979797979797979797984a493001011121300be
be82404395797979795779797a7979a9aaaaaaaaaaaaaaaaaaaaaaab797240404040404040404040434040637979796a7960797979797979524040404040404040404040839a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a79797979797979797984a4930000002021222300be
bea267497c797979795779797979797979797979797979799679797979797996797979797979967977687950797979587979797979797979504b4c4c4c4d797979797979569a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a7979797979797984a49300101112133031323300be
bea25879797979797957794b4c4c4c4c4c4c4c4c4d797979797979797979797979898a8b7979797979777c53797979577979898a8a8b7996505b5c5c5c5d797979797979569a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a797979797984a493000000202122230000000000be
be92a4a4857979797957795b00000000000000005d79797979797979797979898a9d9a9b797979797979795448484869797044ad9aac4640515b5c6e6c6d797979797979569a9a9a9a9a9a9a9a9a9a7979797979797979797979797979797979797979797979797979797979797984a4930010111213303132330000000000be
be00000092857979797a796b6c6f0000b4a4a4b55d7979898aac46717979899dac45ad9b79898b7979704073797979587979a98d9a9a9c8b505b5c5d7979704040404340b39a9a9a9a9a9a9a9a9a9a797979797979797979797979797979797979797979797979797979797984a49300000020212223000000000000000000be
be0000000092857979797979796b6c6f000000005d7979a98d9a9b7979899d9a9a9a9a9c8a9d9c8b797979797979797a7979899d9a9a8cab506b6c6d7979797c477b494876aa8d9a9a9a9a9a9a9a9a79797979797979797979797979797979797979797979797979797984a493001011121330313233000000000000000000be
be000000000092a4a4a4a4857979796b6c6c6c6c6d7979899d9a9c8b79999a9a9a9a9a9a9a9a9a9c8b797979797979797979999a9a9a9c8b7979797979797958797979795079a98d9a9a9a9a9a9a9a7979797979797979797979797979797979797979797979797984a4930000002021222300000000000000000000000000be
be0000000000000000000092a4857979797979797979899d9a9a9a9c8a9d9a9a9a9a9a9a9a9a9a8cab797979797979797984a4afbfbfaea4a4857979796748787979797d797979999a9a9a9a9a9a9a797979797979797979797979797979797979797979797984a49300000000003031323300000000000000000000000000be
be00000000000000000000000092a4a4a4a4a4a4a4a4a4afbfbfae45afbfaeafbfbfaeafbfbfaea4a4a4a4a4a4a4a4a4a4930000000000000092a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a493000000000000000000000000000000000000000000000000be
bebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebebe
__sfx__
000700080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000a7110a7110e711127111a711227110c7000070000700007000070004700037000370003700037000370000700007000070000700007000f70013700177001b7001b7001a70012700107000070000700
001000001361510615006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
0010081004734047210471100700007140072100731007000c1101311013700131001310000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000100001802000700007010000033020100001300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001802033000000003300033020000000000000000100001000010000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c00001a7502d7501a5302d5301a5102d5100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000e310123000e310123000e310123000e310123000e310123000e310123000e310123000e3100d3000e3200d3000e3200e3000e3300e3000e330034000e340003000e340004000e350004000e35000400
000a00200402004020040101b000040200402004010040000400004000040200402105020050210b0200b0210400004000040000400004000040000c0000c0000c0000b0000b0000c0000c0000c0000000000000
000a002004020040200401000000040200402004010000000000000000040200402105020050210b0200b02100000000000b0200b0200c0200c0200b0200b0200c0200c0200b0200b02007020070210402104001
001000051f045180451b0451a045000051f005180051b0051a005000051f005180051b0051a005000051f005180051b0051a005000051f005180051b0051a005000051f005180051b0051a005000051f00518005
001000051f045190051904516045170051f005190051900516005000051f005190051900516005000051f005190051900516005000051f005190051900516005000051f005190051900516005000051f00500005
001000051d045190051904516045000051d005190051900516005000051d005190051900516005000051d005190051900516005000051d005190051900516005000051d005190051900516005000051d00500005
001000051b0451900517045140450000515705007051700514005000051b005190051700514005000051b005190051700514005000051b005190051700514005000051b005190051700514005000051b00519005
001000040071000710007100071000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
001000040271002710027100271002700027000270002700027000270002700027000270002700027000270002700027000270002700027000270002700027000270002700027000270002700027000270002700
001000040171001710017100171001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700
__music__
01 0a0e4344
01 0b0f4344
01 0c104344
00 0d0e4344
00 4d504344
00 4c4e4344
00 4b4f4344
00 4a4e4344

