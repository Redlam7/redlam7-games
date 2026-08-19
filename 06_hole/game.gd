extends Node2D

const W:=720.0
const H:=1280.0
var hole_pos:=Vector2(360,720)
var hole_radius:=38.0
var objects:Array[Dictionary]=[]
var score:=0
var best:=0
var time_left:=60.0
var wave:=1
var chain:=0
var chain_timer:=0.0
var eaten:=0
var game_over:=false
var rng:=RandomNumberGenerator.new()

func _ready()->void:
 rng.randomize();best=load_best();restart()

func spawn_world()->void:
 objects.clear()
 var count:=38+min(wave*3,24)
 for i in range(count):
  var min_r:=9.0+min(wave,6)*0.5
  var max_r:=30.0+min(wave,8)*1.5
  var r:=rng.randf_range(min_r,max_r)
  objects.append({"pos":Vector2(rng.randf_range(55,665),rng.randf_range(180,1160)),"r":r})

func _process(delta:float)->void:
 if game_over:return
 time_left=max(0.0,time_left-delta)
 chain_timer=max(0.0,chain_timer-delta)
 if chain_timer<=0.0:chain=0
 if time_left<=0.0:
  finish_game();return
 var dir:=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
 if dir.length()>0.0:
  hole_pos+=dir*(330.0+min(wave,8)*8.0)*delta;clamp_hole()
 absorb_objects()
 if objects.is_empty():
  wave+=1;time_left=min(75.0,time_left+7.0);score+=wave*100;spawn_world()
 queue_redraw()

func absorb_objects()->void:
 for i in range(objects.size()-1,-1,-1):
  var o=objects[i]
  if o.r<=hole_radius*0.72 and hole_pos.distance_to(o.pos)<hole_radius-o.r*0.15:
   chain=chain+1 if chain_timer>0.0 else 1;chain_timer=0.75
   var mult:=min(chain,8)
   score+=int(o.r)*mult;eaten+=1
   hole_radius=min(118.0,hole_radius+o.r*0.05)
   best=max(best,score);objects.remove_at(i)

func clamp_hole()->void:
 hole_pos.x=clamp(hole_pos.x,25.0+hole_radius,W-25.0-hole_radius)
 hole_pos.y=clamp(hole_pos.y,145.0+hole_radius,H-30.0-hole_radius)

func _unhandled_input(event:InputEvent)->void:
 if event is InputEventMouseMotion:
  hole_pos=event.position;clamp_hole()
 elif event is InputEventScreenDrag:
  hole_pos=event.position;clamp_hole()
 elif event is InputEventScreenTouch and event.pressed:
  if game_over:restart()
  else:hole_pos=event.position;clamp_hole()
 elif event is InputEventMouseButton and event.pressed:
  if game_over:restart()
  else:hole_pos=event.position;clamp_hole()
 elif event is InputEventKey and event.pressed and event.keycode==KEY_R:restart()

func finish_game()->void:
 game_over=true;best=max(best,score);save_best();queue_redraw()

func restart()->void:
 score=0;time_left=60.0;wave=1;chain=0;chain_timer=0.0;eaten=0;hole_radius=38.0;hole_pos=Vector2(360,720);game_over=false;spawn_world();queue_redraw()

func _draw()->void:
 draw_rect(Rect2(0,0,W,H),Color("101721"))
 draw_string(ThemeDB.fallback_font,Vector2(38,60),"REDLAM7 // HOLE",0,-1,34,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(38,103),"SCORE %d   BEST %d   TIME %02d"%[score,best,int(ceil(time_left))],0,-1,20,Color("aab5cc"))
 draw_string(ThemeDB.fallback_font,Vector2(38,137),"WAVE %d   SIZE %d   EATEN %d"%[wave,int(hole_radius),eaten],0,-1,18,Color("72d8f2"))
 for o in objects:
  var edible:=o.r<=hole_radius*0.72
  var c:=Color("4fb4d4") if o.r<20 else Color("9d65d5") if o.r<28 else Color("db7859")
  if not edible:c=c.darkened(.42)
  draw_circle(o.pos,o.r,c);draw_circle(o.pos-Vector2(o.r*.25,o.r*.25),max(2.0,o.r*.12),Color(1,1,1,.28))
 draw_circle(hole_pos+Vector2(0,8),hole_radius+7,Color(0,0,0,.30));draw_circle(hole_pos,hole_radius,Color("020407"));draw_arc(hole_pos,hole_radius,0,TAU,64,Color("37b9dc"),4)
 if chain>=2 and chain_timer>0.0:draw_string(ThemeDB.fallback_font,Vector2(hole_pos.x-55,hole_pos.y-hole_radius-22),"CHAIN x%d"%min(chain,8),0,-1,18,Color("8cecff"))
 if time_left<=10.0 and not game_over:draw_string(ThemeDB.fallback_font,Vector2(275,175),"HURRY!",0,-1,24,Color("ff8a8a"))
 if game_over:
  draw_rect(Rect2(105,490,510,225),Color(0.03,0.04,0.07,.94),true)
  draw_string(ThemeDB.fallback_font,Vector2(220,550),"TIME'S UP",0,-1,38,Color.WHITE)
  draw_string(ThemeDB.fallback_font,Vector2(235,600),"SCORE %d"%score,0,-1,26,Color("72d8f2"))
  draw_string(ThemeDB.fallback_font,Vector2(235,640),"WAVE %d"%wave,0,-1,22,Color("aab5cc"))
  draw_string(ThemeDB.fallback_font,Vector2(190,685),"Tap or R to restart",0,-1,22,Color("aab5cc"))

func save_best()->void:
 var c:=ConfigFile.new();c.set_value("score","best",best);c.save("user://hole.cfg")
func load_best()->int:
 var c:=ConfigFile.new();return 0 if c.load("user://hole.cfg")!=OK else int(c.get_value("score","best",0))
