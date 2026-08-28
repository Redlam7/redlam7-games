extends Node2D

const W:=960.0
const H:=540.0
const GROUND_Y:=470.0
const START:=Vector2(120,GROUND_Y)
const RELICS_START:=[Vector2(280,420),Vector2(430,380),Vector2(610,420),Vector2(780,350)]
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
 if Input.is_action_just_pressed("ui_accept") and on_ground():player_vel.y=-jump_power
 player_vel.y+=gravity*delta;player_pos+=player_vel*delta
 if player_pos.y>=GROUND_Y:player_pos.y=GROUND_Y;player_vel.y=0
 player_pos.x=clamp(player_pos.x,30.0,W-30.0)
 check_collectibles();check_hazards()
 if player_pos.x>900:
  finished=true;score+=max(0,1000-int(elapsed*12.0))+health*150+collected*200;best=max(best,score);save_best()
 queue_redraw()

func on_ground()->bool:return abs(player_pos.y-GROUND_Y)<2.0

func check_collectibles()->void:
 for i in range(relics.size()-1,-1,-1):
  if player_pos.distance_to(relics[i])<30:
   relics.remove_at(i);collected+=1;score+=200
   if collected==2 and not checkpoint_active:
    checkpoint=Vector2(470,GROUND_Y);checkpoint_active=true;score+=100

func check_hazards()->void:
 var p:=Rect2(player_pos.x-14,player_pos.y-34,28,34)
 for h in hazards:
  if p.intersects(h):
   health-=1
   if health<=0:dead=true;best=max(best,score);save_best()
   else:player_pos=checkpoint;player_vel=Vector2.ZERO
   queue_redraw();return

func restart()->void:
 player_pos=START;player_vel=Vector2.ZERO;relics=[]
 for r in RELICS_START:relics.append(r)
 collected=0;checkpoint=START;checkpoint_active=false;health=3;score=0;elapsed=0.0;finished=false;dead=false;touch_dir=0.0;queue_redraw()

func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed:
  if event.keycode==KEY_R:restart()
  elif (event.keycode==KEY_SPACE or event.keycode==KEY_UP or event.keycode==KEY_W or event.keycode==KEY_Z) and on_ground():player_vel.y=-jump_power
 elif event is InputEventScreenTouch:
  if event.pressed:
   if finished or dead:restart()
   elif event.position.y<H*.52 and on_ground():player_vel.y=-jump_power
   elif event.position.x<W*.5:touch_dir=-1.0
   else:touch_dir=1.0
  else:touch_dir=0.0
 elif event is InputEventScreenDrag:
  touch_dir=clamp(event.relative.x/12.0,-1.0,1.0)
 elif event is InputEventMouseButton and event.pressed and (finished or dead):restart()

func _draw()->void:
 draw_rect(Rect2(0,0,W,H),Color("0f1620"));draw_rect(Rect2(0,GROUND_Y,W,H-GROUND_Y),Color("263448"))
 draw_string(ThemeDB.fallback_font,Vector2(28,44),"REDLAM7 // ADVENTURE",0,-1,30,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(28,78),"RELICS %d/4   HP %d   SCORE %d   BEST %d"%[collected,health,score,best],0,-1,18,Color("9fc7d8"))
 draw_string(ThemeDB.fallback_font,Vector2(28,108),"MOVE: arrows / QD / AD   JUMP: Space / Z / W / Up",0,-1,15,Color("718fa0"))
 draw_rect(Rect2(860,360,55,110),Color("3c596e"),true);draw_rect(Rect2(875,330,25,30),Color("69d2e7"),true)
 if checkpoint_active:
  draw_line(Vector2(470,GROUND_Y),Vector2(470,390),Color("69d2e7"),4);draw_polygon(PackedVector2Array([Vector2(470,390),Vector2(520,405),Vector2(470,420)]),PackedColorArray([Color("69d2e7")]))
 for c in relics:draw_circle(c,11,Color("e0bf56"));draw_circle(c,5,Color("fff0a0"))
 for h in hazards:draw_rect(h,Color("b34b4b"),true)
 draw_rect(Rect2(player_pos.x-14,player_pos.y-34,28,34),Color("55c0da"),true);draw_circle(player_pos+Vector2(0,-42),10,Color("d7e8ec"))
 if finished or dead:
  draw_rect(Rect2(220,165,520,185),Color(0.03,0.04,0.07,.95),true)
  var title:="LEVEL CLEAR" if finished else "ADVENTURE OVER"
  draw_string(ThemeDB.fallback_font,Vector2(330,225),title,0,-1,36,Color.WHITE)
  draw_string(ThemeDB.fallback_font,Vector2(330,270),"Relics %d/4   Score %d"%[collected,score],0,-1,22,Color("71d6ee"))
  draw_string(ThemeDB.fallback_font,Vector2(335,315),"Tap or R to restart",0,-1,20,Color("9fc7d8"))

func save_best()->void:
 var c:=ConfigFile.new();c.set_value("score","best",best);c.save("user://adventure.cfg")
func load_best()->int:
 var c:=ConfigFile.new();return 0 if c.load("user://adventure.cfg")!=OK else int(c.get_value("score","best",0))
