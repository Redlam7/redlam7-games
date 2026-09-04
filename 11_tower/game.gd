extends Node2D

const W:=960.0
const H:=540.0
const MAX_WAVES:=20
const PATH:=PackedVector2Array([Vector2(0,270),Vector2(180,270),Vector2(180,130),Vector2(430,130),Vector2(430,390),Vector2(700,390),Vector2(700,220),Vector2(960,220)])
const TOWER_NAMES:=["BLASTER","FROST","CANNON"]
const TOWER_COSTS:=[60,80,110]
const TOWER_RANGES:=[145.0,125.0,175.0]
const TOWER_COLORS:=[Color("55c6e8"),Color("74e0d1"),Color("e6a85d")]

var towers:Array[Dictionary]=[]
var enemies:Array[Dictionary]=[]
var shots:Array[Dictionary]=[]
var gold:=180
var lives:=20
var wave:=0
var wave_left:=0
var spawn_timer:=0.0
var wave_delay:=1.5
var game_over:=false
var victory:=false
var paused:=false
var game_speed:=1.0
var selected_type:=0
var selected_tower:Dictionary={}
var kills:=0
var score:=0
var message:="BUILD YOUR DEFENSE"
var message_timer:=3.0

func _ready()->void:
 queue_redraw()

func _process(delta:float)->void:
 if paused or game_over:return
 var d:=delta*game_speed
 message_timer=max(0.0,message_timer-d)
 if wave_left>0:
  spawn_timer-=d
  if spawn_timer<=0.0:
   spawn_enemy();wave_left-=1;spawn_timer=max(.18,.72-wave*.018)
 elif enemies.is_empty():
  if wave>=MAX_WAVES:
   victory=true;game_over=true;message="FORTRESS SECURED";queue_redraw();return
  wave_delay-=d
  if wave_delay<=0.0:start_wave()
 update_enemies(d);update_towers(d);update_shots(d)
 if lives<=0:
  lives=0;game_over=true;message="BASE LOST"
 queue_redraw()

func start_wave()->void:
 if game_over or wave_left>0 or not enemies.is_empty():return
 wave+=1;wave_left=6+wave*2;spawn_timer=.1;wave_delay=2.5
 message="BOSS WAVE %d"%wave if wave%5==0 else "WAVE %d"%wave
 message_timer=1.8

func spawn_enemy()->void:
 var boss:=wave%5==0 and wave_left==1
 var armored:=wave>=8 and wave_left%5==0 and not boss
 var hp:=3.0+wave*1.35
 var speed:=48.0+wave*2.1
 var reward:=8+wave
 var leak:=1
 if armored:hp*=2.2;speed*=.82;reward+=8
 if boss:hp*=8.0;speed*=.62;reward*=8;leak=5
 enemies.append({"pos":PATH[0],"seg":0,"hp":hp,"max_hp":hp,"speed":speed,"slow":0.0,"reward":reward,"boss":boss,"armored":armored,"leak":leak})

func update_enemies(delta:float)->void:
 for i in range(enemies.size()-1,-1,-1):
  var e=enemies[i]
  if e.slow>0:e.slow-=delta
  var target:Vector2=PATH[min(e.seg+1,PATH.size()-1)]
  var diff:Vector2=target-e.pos
  var sp:float=e.speed*(.58 if e.slow>0 else 1.0)
  if diff.length()<=sp*delta:
   e.pos=target;e.seg+=1
   if e.seg>=PATH.size()-1:
    lives-=e.leak;enemies.remove_at(i);continue
  else:e.pos+=diff.normalized()*sp*delta

func update_towers(delta:float)->void:
 for t in towers:
  t.cd-=delta
  if t.cd>0:continue
  var target=-1
  var best_progress:=-1
  for i in range(enemies.size()):
   var e=enemies[i]
   if t.pos.distance_squared_to(e.pos)<=t.range*t.range:
    var progress:int=e.seg
    if progress>best_progress:best_progress=progress;target=i
  if target>=0:
   var dmg:float=[1.15,.72,3.2][t.type]*(1.0+(t.level-1)*.48)
   shots.append({"pos":t.pos,"target":enemies[target],"speed":560.0,"damage":dmg,"type":t.type,"splash":42.0+10.0*t.level if t.type==2 else 0.0})
   t.cd=[.46,.60,1.18][t.type]/(1.0+(t.level-1)*.14)

func update_shots(delta:float)->void:
 for i in range(shots.size()-1,-1,-1):
  var s=shots[i]
  if not enemies.has(s.target):shots.remove_at(i);continue
  var diff:Vector2=s.target.pos-s.pos
  if diff.length()<20:
   var impact:Vector2=s.target.pos
   if s.type==2:
    for e in enemies:
     if e.pos.distance_to(impact)<=s.splash:e.hp-=s.damage
   else:
    s.target.hp-=s.damage
    if s.type==1:s.target.slow=1.55
   cleanup_dead_enemies()
   shots.remove_at(i)
  else:s.pos+=diff.normalized()*s.speed*delta

func cleanup_dead_enemies()->void:
 for i in range(enemies.size()-1,-1,-1):
  var e=enemies[i]
  if e.hp<=0:
   gold+=e.reward;kills+=1;score+=e.reward*10
   enemies.remove_at(i)

func can_build(p:Vector2)->bool:
 if p.y<92:return false
 for t in towers:
  if p.distance_to(t.pos)<58:return false
 for i in range(PATH.size()-1):
  if Geometry2D.get_closest_point_to_segment(p,PATH[i],PATH[i+1]).distance_to(p)<50:return false
 return true

func build(p:Vector2)->void:
 var cost:int=TOWER_COSTS[selected_type]
 if gold>=cost and can_build(p):
  gold-=cost
  towers.append({"pos":p,"type":selected_type,"range":TOWER_RANGES[selected_type],"cd":.1,"level":1,"spent":cost})
  message="%s ONLINE"%TOWER_NAMES[selected_type];message_timer=1.1
 elif gold<cost:
  message="NOT ENOUGH GOLD";message_timer=1.1
 else:
  message="INVALID POSITION";message_timer=1.1

func tower_at(p:Vector2)->Dictionary:
 for t in towers:
  if p.distance_to(t.pos)<30:return t
 return {}

func upgrade_cost(t:Dictionary)->int:
 return 55+t.level*40

func upgrade_selected()->void:
 if selected_tower.is_empty():return
 if selected_tower.level>=4:
  message="MAX LEVEL";message_timer=1.0;return
 var cost:=upgrade_cost(selected_tower)
 if gold<cost:
  message="NOT ENOUGH GOLD";message_timer=1.0;return
 gold-=cost;selected_tower.level+=1;selected_tower.range+=14;selected_tower.spent+=cost
 message="TOWER LEVEL %d"%selected_tower.level;message_timer=1.0

func sell_selected()->void:
 if selected_tower.is_empty():return
 var refund:=int(selected_tower.spent*.65)
 gold+=refund;towers.erase(selected_tower);selected_tower={}
 message="SOLD +%d"%refund;message_timer=1.0

func restart()->void:
 towers.clear();enemies.clear();shots.clear();gold=180;lives=20;wave=0;wave_left=0;spawn_timer=0.0;wave_delay=1.5;game_over=false;victory=false;paused=false;game_speed=1.0;selected_type=0;selected_tower={};kills=0;score=0;message="BUILD YOUR DEFENSE";message_timer=3.0;queue_redraw()

func handle_press(p:Vector2)->void:
 if game_over:restart();return
 if p.y<82:
  if p.x<500:
   selected_type=clamp(int((p.x-15.0)/160.0),0,2);selected_tower={}
  elif p.x<670:
   if not selected_tower.is_empty():upgrade_selected()
   else:start_wave()
  elif p.x<790:
   if not selected_tower.is_empty():sell_selected()
  elif p.x<875:
   game_speed=2.0 if game_speed<2.0 else 1.0
  else:paused=not paused
  return
 var hit:=tower_at(p)
 if not hit.is_empty():selected_tower=hit
 else:selected_tower={};build(p)

func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed:
  if event.keycode==KEY_1:selected_type=0;selected_tower={}
  elif event.keycode==KEY_2:selected_type=1;selected_tower={}
  elif event.keycode==KEY_3:selected_type=2;selected_tower={}
  elif event.keycode==KEY_U:upgrade_selected()
  elif event.keycode==KEY_S:sell_selected()
  elif event.keycode==KEY_SPACE:start_wave()
  elif event.keycode==KEY_F:game_speed=2.0 if game_speed<2.0 else 1.0
  elif event.keycode==KEY_P:paused=not paused
  elif event.keycode==KEY_R:restart()
 elif event is InputEventMouseButton and event.pressed:handle_press(event.position)
 elif event is InputEventScreenTouch and event.pressed:handle_press(event.position)
 queue_redraw()

func _draw()->void:
 draw_rect(Rect2(0,0,W,H),Color("0c1520"))
 draw_rect(Rect2(0,82,W,H-82),Color("13222d"))
 for x in range(20,960,70):draw_circle(Vector2(x,105+(x*37)%400),2,Color("1f3946"))
 for i in range(PATH.size()-1):
  draw_line(PATH[i],PATH[i+1],Color("263b4b"),68,true)
  draw_line(PATH[i],PATH[i+1],Color("3c5668"),3,true)
 draw_circle(Vector2(925,220),34,Color("1e5160"));draw_circle(Vector2(925,220),22,Color("75d8e8"))
 draw_string(ThemeDB.fallback_font,Vector2(18,30),"REDLAM7 // TOWER",0,-1,24,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(525,29),"GOLD %d  LIVES %d  WAVE %d/%d"%[gold,lives,wave,MAX_WAVES],0,-1,17,Color("a9ddeb"))
 for i in range(3):
  var x:=15+i*160;var active:=i==selected_type and selected_tower.is_empty();var c:=Color("42647d") if active else Color("233848")
  draw_rect(Rect2(x,43,145,32),c,true);draw_string(ThemeDB.fallback_font,Vector2(x+7,65),"%d %s $%d"%[i+1,TOWER_NAMES[i],TOWER_COSTS[i]],0,-1,12,Color.WHITE)
 if selected_tower.is_empty():
  draw_rect(Rect2(505,43,155,32),Color("294253"),true);draw_string(ThemeDB.fallback_font,Vector2(518,65),"SPACE START WAVE",0,-1,12,Color.WHITE)
 else:
  var uc:=upgrade_cost(selected_tower);draw_rect(Rect2(505,43,155,32),Color("355a52"),true);draw_string(ThemeDB.fallback_font,Vector2(516,65),"U UPGRADE $%d"%uc,0,-1,12,Color.WHITE)
  draw_rect(Rect2(670,43,110,32),Color("5b3b42"),true);draw_string(ThemeDB.fallback_font,Vector2(682,65),"S SELL",0,-1,12,Color.WHITE)
 draw_rect(Rect2(790,43,75,32),Color("294253"),true);draw_string(ThemeDB.fallback_font,Vector2(808,65),"x%.0f"%game_speed,0,-1,13,Color.WHITE)
 draw_rect(Rect2(875,43,70,32),Color("294253"),true);draw_string(ThemeDB.fallback_font,Vector2(890,65),"PAUSE",0,-1,11,Color.WHITE)
 for t in towers:
  var c:TOWER_COLORS[t.type]
  draw_circle(t.pos,21+2*t.level,Color("0b1016"));draw_circle(t.pos,17+2*t.level,c)
  draw_circle(t.pos,7,c.lightened(.2));draw_string(ThemeDB.fallback_font,t.pos+Vector2(-4,5),str(t.level),0,-1,12,Color("10202a"))
  if t==selected_tower:
   draw_arc(t.pos,t.range,0,TAU,64,Color(c,.35),2);draw_arc(t.pos,27+2*t.level,0,TAU,32,Color.WHITE,2)
 for e in enemies:
  var radius:=25 if e.boss else (18 if e.armored else 14)
  var ec:=Color("f3a04d") if e.boss else (Color("a66a8f") if e.armored else Color("d8556f"))
  draw_circle(e.pos,radius,Color("241b26"));draw_circle(e.pos,radius-3,ec)
  if e.slow>0:draw_arc(e.pos,radius+4,0,TAU,28,Color("8ff5ef"),2)
  var bw:=46.0 if e.boss else 32.0;var by:=-radius-10
  draw_rect(Rect2(e.pos+Vector2(-bw/2,by),Vector2(bw,4)),Color("452a31"),true)
  draw_rect(Rect2(e.pos+Vector2(-bw/2,by),Vector2(bw*max(0.0,e.hp/e.max_hp),4)),Color("76dc8a"),true)
 for s in shots:draw_circle(s.pos,5,[Color.WHITE,Color("8ff5ef"),Color("ffc46b")][s.type])
 draw_string(ThemeDB.fallback_font,Vector2(18,520),"KILLS %d   SCORE %d   [1-3] tower  [U] upgrade  [S] sell  [F] speed  [P] pause"%[kills,score],0,-1,13,Color("7898a8"))
 if message_timer>0 and not game_over:
  draw_rect(Rect2(345,92,270,38),Color(0.02,0.04,0.06,.82),true);draw_string(ThemeDB.fallback_font,Vector2(390,118),message,0,-1,18,Color("d8f5ff"))
 if paused and not game_over:
  draw_rect(Rect2(360,215,240,90),Color(0.02,0.03,0.05,.92),true);draw_string(ThemeDB.fallback_font,Vector2(427,270),"PAUSED",0,-1,30,Color.WHITE)
 if game_over:
  draw_rect(Rect2(260,175,440,185),Color(0.02,0.03,0.05,.95),true)
  draw_string(ThemeDB.fallback_font,Vector2(330,230),"VICTORY" if victory else "BASE LOST",0,-1,36,Color("f3df9a") if victory else Color.WHITE)
  draw_string(ThemeDB.fallback_font,Vector2(330,275),"Wave %d   Kills %d   Score %d"%[wave,kills,score],0,-1,18,Color("a9ddeb"))
  draw_string(ThemeDB.fallback_font,Vector2(335,320),"Tap / click / R to restart",0,-1,17,Color("9fb8c5"))
