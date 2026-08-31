extends Node2D

const W:=960.0
const H:=540.0
const GROUND_Y:=470.0
const START:=Vector2(120,GROUND_Y)
const RELICS_START:=[Vector2(280,390),Vector2(430,350),Vector2(610,390),Vector2(780,350)]
var platforms:=[Rect2(235,420,95,14),Rect2(385,380,95,14),Rect2(565,420,95,14),Rect2(735,380,95,14)]
var player_pos:=START
var player_vel:=Vector2.ZERO
var speed:=220.0
var jump_power:=430.0
var gravity:=980.0
var relics:Array[Vector2]=[]
var hazards:=[Rect2(520,445,46,25),Rect2(700,445,46,25)]
var collected:=0
var checkpoint:=START
var checkpoint_active:=false
var health:=3
var score:=0
var best:=0
var elapsed:=0.0
var finished:=false
var dead:=false
var touch_dir:=0.0
var grounded:=true

func _ready()->void:
 best=load_best();restart()

func _process(delta:float)->void:
 if finished or dead:return
 elapsed+=delta
 var dir:=0.0
 if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_Q):dir-=1.0
 if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):dir+=1.0
 if abs(touch_dir)>0.01:dir=touch_dir
 player_vel.x=dir*speed
 if Input.is_action_just_pressed("ui_accept") and on_ground():player_vel.y=-jump_power;grounded=false
 var old_y:=player_pos.y
 player_vel.y+=gravity*delta;player_pos+=player_vel*delta;grounded=false
 if player_pos.y>=GROUND_Y:player_pos.y=GROUND_Y;player_vel.y=0;grounded=true
 elif player_vel.y>=0:
  for p in platforms:
   if player_pos.x>p.position.x-12 and player_pos.x<p.end.x+12 and old_y<=p.position.y and player_pos.y>=p.position.y:
    player_pos.y=p.position.y;player_vel.y=0;grounded=true;break
 player_pos.x=clamp(player_pos.x,30.0,W-30.0)
 check_collectibles();check_hazards()
 if player_pos.x>900:
  finished=true;score+=max(0,1000-int(elapsed*12.0))+health*150+collected*200;best=max(best,score);save_best()
 queue_redraw()

func on_ground()->bool:return grounded

func check_collectibles()->void:
 for i in range(relics.size()-1,-1,-1):
  if player_pos.distance_to(relics[i])<35:
   relics.remove_at(i);collected+=1;score+=200
   if collected==2 and not checkpoint_active:
    checkpoint=Vector2(470,GROUND_Y);checkpoint_active=true;score+=100

func check_hazards()->void:
 var p:=Rect2(player_pos.x-14,player_pos.y-34,28,34)
 for h in hazards:
  if p.intersects(h):
   health-=1
   if health<=0:dead=true;best=max(best,score);save_best()
   else:player_pos=checkpoint;player_vel=Vector2.ZERO;grounded=true
   queue_redraw();return

func restart()->void:
 player_pos=START;player_vel=Vector2.ZERO;relics=[]
 for r in RELICS_START:relics.append(r)
 collected=0;checkpoint=START;checkpoint_active=false;health=3;score=0;elapsed=0.0;finished=false;dead=false;touch_dir=0.0;grounded=true;queue_redraw()

func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed:
  if event.keycode==KEY_R:restart()
  elif (event.keycode==KEY_SPACE or event.keycode==KEY_UP or event.keycode==KEY_W or event.keycode==KEY_Z) and on_ground():player_vel.y=-jump_power;grounded=false
 elif event is InputEventScreenTouch:
  if event.pressed:
   if finished or dead:restart()
   elif event.position.y<H*.52 and on_ground():player_vel.y=-jump_power;grounded=false
   elif event.position.x<W*.5:touch_dir=-1.0
   else:touch_dir=1.0
  else:touch_dir=0.0
 elif event is InputEventScreenDrag:touch_dir=clamp(event.relative.x/12.0,-1.0,1.0)
 elif event is InputEventMouseButton and event.pressed and (finished or dead):restart()

func _draw()->void:
 draw_rect(Rect2(0,0,W,H),Color("0b1720"));draw_rect(Rect2(0,GROUND_Y,W,H-GROUND_Y),Color("253747"))
 draw_circle(Vector2(780,100),55,Color("183b4c"));draw_circle(Vector2(780,100),38,Color("d9b85a"))
 for x in range(0,960,80):draw_polygon(PackedVector2Array([Vector2(x,GROUND_Y),Vector2(x+55,310+(x%160)),Vector2(x+120,GROUND_Y)]),PackedColorArray([Color("142936")]))
 draw_string(ThemeDB.fallback_font,Vector2(28,44),"REDLAM7 // ADVENTURE",0,-1,30,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(28,78),"RELICS %d/4   HP %d   SCORE %d   BEST %d"%[collected,health,score,best],0,-1,18,Color("9fc7d8"))
 draw_string(ThemeDB.fallback_font,Vector2(28,108),"MOVE: arrows / QD / AD   JUMP: Space / Z / W / Up",0,-1,15,Color("718fa0"))
 for p in platforms:
  draw_rect(p,Color("426070"),true);draw_line(p.position,p.position+Vector2(p.size.x,0),Color("76b6c8"),3)
 draw_rect(Rect2(860,360,55,110),Color("3c596e"),true);draw_rect(Rect2(875,330,25,30),Color("69d2e7"),true)
 if checkpoint_active:
  draw_line(Vector2(470,GROUND_Y),Vector2(470,390),Color("69d2e7"),4);draw_polygon(PackedVector2Array([Vector2(470,390),Vector2(520,405),Vector2(470,420)]),PackedColorArray([Color("69d2e7")]))
 for c in relics:draw_circle(c,13,Color("e0bf56"));draw_circle(c,6,Color("fff0a0"))
 for h in hazards:
  draw_polygon(PackedVector2Array([Vector2(h.position.x,h.end.y),Vector2(h.position.x+12,h.position.y),Vector2(h.position.x+24,h.end.y),Vector2(h.position.x+36,h.position.y),Vector2(h.end.x,h.end.y)]),PackedColorArray([Color("b34b4b")]))
 draw_rect(Rect2(player_pos.x-14,player_pos.y-34,28,34),Color("55c0da"),true);draw_circle(player_pos+Vector2(0,-42),10,Color("d7e8ec"));draw_line(player_pos+Vector2(-8,-20),player_pos+Vector2(-17,0),Color("d7e8ec"),4);draw_line(player_pos+Vector2(8,-20),player_pos+Vector2(17,0),Color("d7e8ec"),4)
 if finished or dead:
  draw_rect(Rect2(220,165,520,185),Color(0.03,0.04,0.07,.95),true);var title:="LEVEL CLEAR" if finished else "ADVENTURE OVER";draw_string(ThemeDB.fallback_font,Vector2(330,225),title,0,-1,36,Color.WHITE);draw_string(ThemeDB.fallback_font,Vector2(330,270),"Relics %d/4   Score %d"%[collected,score],0,-1,22,Color("71d6ee"));draw_string(ThemeDB.fallback_font,Vector2(335,315),"Tap or R to restart",0,-1,20,Color("9fc7d8"))

func save_best()->void:
 var c:=ConfigFile.new();c.set_value("score","best",best);c.save("user://adventure.cfg")
func load_best()->int:
 var c:=ConfigFile.new();return 0 if c.load("user://adventure.cfg")!=OK else int(c.get_value("score","best",0))
