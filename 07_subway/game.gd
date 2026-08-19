extends Node2D

const W:=720.0
const H:=1280.0
const LANES:=[220.0,360.0,500.0]
const GROUND_Y:=1030.0
var lane:=1
var player_y:=GROUND_Y
var vertical_speed:=0.0
var slide_timer:=0.0
var speed:=420.0
var distance:=0.0
var score:=0
var best:=0
var coins:=0
var combo:=0
var combo_timer:=0.0
var obstacles:Array[Dictionary]=[]
var pickups:Array[Dictionary]=[]
var spawn_timer:=0.8
var coin_timer:=1.2
var rng:=RandomNumberGenerator.new()
var game_over:=false
var touch_start:=Vector2.ZERO

func _ready()->void:
 rng.randomize();best=load_best();restart()

func _process(delta:float)->void:
 if game_over:return
 speed=min(860.0,speed+7.0*delta);distance+=speed*delta*0.02
 combo_timer=max(0.0,combo_timer-delta)
 if combo_timer<=0.0:combo=0
 score=int(distance)+coins*15
 if player_y<GROUND_Y or vertical_speed!=0.0:
  vertical_speed+=1650.0*delta;player_y+=vertical_speed*delta
  if player_y>=GROUND_Y:player_y=GROUND_Y;vertical_speed=0.0
 if slide_timer>0.0:slide_timer-=delta
 spawn_timer-=delta;coin_timer-=delta
 if spawn_timer<=0.0:
  spawn_obstacle();spawn_timer=rng.randf_range(.78,1.28)*clamp(520.0/speed,.60,1.0)
 if coin_timer<=0.0:
  spawn_pickup();coin_timer=rng.randf_range(1.0,1.8)
 for i in range(obstacles.size()-1,-1,-1):
  obstacles[i].y+=speed*delta
  if obstacles[i].y>H+120:
   obstacles.remove_at(i);continue
  if collides(obstacles[i]):finish_game();break
  if not obstacles[i].passed and obstacles[i].y>GROUND_Y+70:
   obstacles[i].passed=true;combo+=1;combo_timer=1.1;distance+=min(combo,8)*2
 for i in range(pickups.size()-1,-1,-1):
  pickups[i].y+=speed*delta
  if pickups[i].y>H+60:pickups.remove_at(i);continue
  if pickups[i].lane==lane and abs(pickups[i].y-player_y)<70.0:
   coins+=1;distance+=5;pickups.remove_at(i)
 best=max(best,score);queue_redraw()

func spawn_obstacle()->void:
 obstacles.append({"lane":rng.randi_range(0,2),"y":150.0,"kind":rng.randi_range(0,2),"passed":false})
func spawn_pickup()->void:
 pickups.append({"lane":rng.randi_range(0,2),"y":130.0})

func collides(o:Dictionary)->bool:
 if o.lane!=lane or abs(o.y-GROUND_Y)>55.0:return false
 if o.kind==1 and player_y<GROUND_Y-45.0:return false
 if o.kind==2 and slide_timer>0.0:return false
 return true
func move_left()->void:lane=max(0,lane-1)
func move_right()->void:lane=min(2,lane+1)
func jump()->void:
 if player_y>=GROUND_Y and slide_timer<=0.0:vertical_speed=-720.0
func slide()->void:
 if player_y>=GROUND_Y:slide_timer=.55

func finish_game()->void:
 game_over=true;best=max(best,score);save_best();queue_redraw()
func restart()->void:
 lane=1;player_y=GROUND_Y;vertical_speed=0.0;slide_timer=0.0;speed=420.0;distance=0.0;score=0;coins=0;combo=0;combo_timer=0.0;obstacles.clear();pickups.clear();spawn_timer=.8;coin_timer=1.2;game_over=false;queue_redraw()

func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed:
  match event.keycode:
   KEY_LEFT,KEY_A:move_left()
   KEY_RIGHT,KEY_D:move_right()
   KEY_UP,KEY_W,KEY_SPACE:jump()
   KEY_DOWN,KEY_S:slide()
   KEY_R:restart()
 elif event is InputEventScreenTouch:
  if event.pressed:
   touch_start=event.position
   if game_over:restart()
  else:
   var d:=event.position-touch_start
   if d.length()>45.0:
    if abs(d.x)>abs(d.y):
     if d.x>0:move_right()
     else:move_left()
    else:
     if d.y<0:jump()
     else:slide()
 elif event is InputEventMouseButton and event.pressed:
  if game_over:restart()

func _draw()->void:
 draw_rect(Rect2(0,0,W,H),Color("0b1118"))
 draw_string(ThemeDB.fallback_font,Vector2(38,58),"REDLAM7 // SUBWAY",0,-1,34,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(38,100),"DIST %04d   BEST %04d   SPEED %03d"%[score,best,int(speed)],0,-1,19,Color("aab5cc"))
 draw_string(ThemeDB.fallback_font,Vector2(38,132),"COINS %d   STREAK x%d"%[coins,combo],0,-1,18,Color("79d9f1"))
 draw_polygon(PackedVector2Array([Vector2(115,H),Vector2(605,H),Vector2(470,180),Vector2(250,180)]),PackedColorArray([Color("182331")]))
 for x in LANES:draw_line(Vector2(x,H),Vector2(360+(x-360)*.28,180),Color("34485c"),5)
 for y in range(240,1200,120):
  var t:=float(y-180)/float(H-180);var half:=lerp(120.0,260.0,t);draw_line(Vector2(360-half,y),Vector2(360+half,y),Color("263848"),2)
 for p in pickups:
  var x:float=LANES[p.lane];draw_circle(Vector2(x,p.y),15,Color("f3c84b"));draw_circle(Vector2(x,p.y),7,Color("fff1a3"))
 for o in obstacles:
  var x:float=LANES[o.lane];var y:float=o.y
  if o.kind==0:draw_rect(Rect2(x-38,y-75,76,75),Color("d15d55"),true)
  elif o.kind==1:draw_rect(Rect2(x-46,y-36,92,36),Color("d08b4b"),true)
  else:draw_rect(Rect2(x-50,y-110,100,34),Color("7f65cf"),true)
 var px:=LANES[lane];var body_h:=42.0 if slide_timer>0.0 else 88.0
 draw_rect(Rect2(px-28,player_y-body_h,56,body_h),Color("43b9dc"),true);draw_circle(Vector2(px,player_y-body_h-18),18,Color("e6f7ff"))
 if combo>=3:draw_string(ThemeDB.fallback_font,Vector2(275,170),"STREAK x%d"%combo,0,-1,22,Color("9be9ff"))
 if game_over:
  draw_rect(Rect2(100,480,520,230),Color(0.03,0.04,0.07,.94),true);draw_string(ThemeDB.fallback_font,Vector2(225,545),"RUN OVER",0,-1,38,Color.WHITE);draw_string(ThemeDB.fallback_font,Vector2(225,595),"SCORE %d"%score,0,-1,27,Color("79d9f1"));draw_string(ThemeDB.fallback_font,Vector2(225,635),"COINS %d"%coins,0,-1,22,Color("aab5cc"));draw_string(ThemeDB.fallback_font,Vector2(185,680),"Tap or R to restart",0,-1,22,Color("aab5cc"))

func save_best()->void:
 var c:=ConfigFile.new();c.set_value("score","best",best);c.save("user://subway.cfg")
func load_best()->int:
 var c:=ConfigFile.new();return 0 if c.load("user://subway.cfg")!=OK else int(c.get_value("score","best",0))
