extends Node2D

const W:=960.0
const H:=540.0
const MAX_WAVES:=20
const PATH:=PackedVector2Array([Vector2(0,270),Vector2(180,270),Vector2(180,130),Vector2(430,130),Vector2(430,390),Vector2(700,390),Vector2(700,220),Vector2(960,220)])
const TOWER_NAMES:=["SCRAP GUN","ICE BOX","WHEEL CANNON"]
const TOWER_COSTS:=[60,80,110]
const TOWER_RANGES:=[145.0,125.0,175.0]
const TOWER_COLORS:=[Color("57c7d9"),Color("7de3cf"),Color("e5a451")]
var towers:Array[Dictionary]=[];var enemies:Array[Dictionary]=[];var shots:Array[Dictionary]=[]
var gold:=180;var lives:=20;var wave:=0;var wave_left:=0;var spawn_timer:=0.0;var wave_delay:=1.5
var game_over:=false;var victory:=false;var paused:=false;var game_speed:=1.0;var selected_type:=0;var selected_tower:Dictionary={}
var kills:=0;var score:=0;var message:="FORTIFY WILBIRD CAMP";var message_timer:=3.0

func _ready()->void:queue_redraw()
func _process(delta:float)->void:
 if paused or game_over:return
 var d:=delta*game_speed;message_timer=max(0.0,message_timer-d)
 if wave_left>0:
  spawn_timer-=d
  if spawn_timer<=0.0:spawn_enemy();wave_left-=1;spawn_timer=max(.18,.72-wave*.018)
 elif enemies.is_empty():
  if wave>=MAX_WAVES:victory=true;game_over=true;message="WILBIRD CAMP SECURED";queue_redraw();return
  wave_delay-=d
  if wave_delay<=0.0:start_wave()
 update_enemies(d);update_towers(d);update_shots(d)
 if lives<=0:lives=0;game_over=true;message="CAMP OVERRUN"
 queue_redraw()
func start_wave()->void:
 if game_over or wave_left>0 or not enemies.is_empty():return
 wave+=1;wave_left=6+wave*2;spawn_timer=.1;wave_delay=2.5;message="SCRAP BOSS INBOUND" if wave%5==0 else "RAIDER WAVE %d"%wave;message_timer=1.8
func spawn_enemy()->void:
 var boss:=wave%5==0 and wave_left==1;var armored:=wave>=8 and wave_left%5==0 and not boss;var hp:=3.0+wave*1.35;var speed:=48.0+wave*2.1;var reward:=8+wave;var leak:=1
 if armored:hp*=2.2;speed*=.82;reward+=8
 if boss:hp*=8.0;speed*=.62;reward*=8;leak=5
 enemies.append({"pos":PATH[0],"seg":0,"hp":hp,"max_hp":hp,"speed":speed,"slow":0.0,"reward":reward,"boss":boss,"armored":armored,"leak":leak})
func update_enemies(delta:float)->void:
 for i in range(enemies.size()-1,-1,-1):
  var e=enemies[i];if e.slow>0:e.slow-=delta
  var target:Vector2=PATH[min(e.seg+1,PATH.size()-1)];var diff:Vector2=target-e.pos;var sp:float=e.speed*(.58 if e.slow>0 else 1.0)
  if diff.length()<=sp*delta:
   e.pos=target;e.seg+=1
   if e.seg>=PATH.size()-1:lives-=e.leak;enemies.remove_at(i);continue
  else:e.pos+=diff.normalized()*sp*delta
func update_towers(delta:float)->void:
 for t in towers:
  t.cd-=delta
  if t.cd>0:continue
  var target=-1;var best_progress:=-1
  for i in range(enemies.size()):
   var e=enemies[i]
   if t.pos.distance_squared_to(e.pos)<=t.range*t.range and e.seg>best_progress:best_progress=e.seg;target=i
  if target>=0:
   var dmg:float=[1.15,.72,3.2][t.type]*(1.0+(t.level-1)*.48);shots.append({"pos":t.pos,"target":enemies[target],"speed":560.0,"damage":dmg,"type":t.type,"splash":42.0+10.0*t.level if t.type==2 else 0.0});t.cd=[.46,.60,1.18][t.type]/(1.0+(t.level-1)*.14)
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
   else:s.target.hp-=s.damage;if s.type==1:s.target.slow=1.55
   cleanup_dead_enemies();shots.remove_at(i)
  else:s.pos+=diff.normalized()*s.speed*delta
func cleanup_dead_enemies()->void:
 for i in range(enemies.size()-1,-1,-1):
  var e=enemies[i]
  if e.hp<=0:gold+=e.reward;kills+=1;score+=e.reward*10;enemies.remove_at(i)
func can_build(p:Vector2)->bool:
 if p.y<92:return false
 for t in towers:
  if p.distance_to(t.pos)<58:return false
 for i in range(PATH.size()-1):
  if Geometry2D.get_closest_point_to_segment(p,PATH[i],PATH[i+1]).distance_to(p)<50:return false
 return true
func build(p:Vector2)->void:
 var cost:int=TOWER_COSTS[selected_type]
 if gold>=cost and can_build(p):gold-=cost;towers.append({"pos":p,"type":selected_type,"range":TOWER_RANGES[selected_type],"cd":.1,"level":1,"spent":cost});message="%s BUILT"%TOWER_NAMES[selected_type];message_timer=1.1
 elif gold<cost:message="NEED MORE SCRAP";message_timer=1.1
 else:message="ROAD MUST STAY CLEAR";message_timer=1.1
func tower_at(p:Vector2)->Dictionary:
 for t in towers:
  if p.distance_to(t.pos)<30:return t
 return {}
func upgrade_cost(t:Dictionary)->int:return 55+t.level*40
func upgrade_selected()->void:
 if selected_tower.is_empty():return
 if selected_tower.level>=4:message="MAXED OUT";message_timer=1.0;return
 var cost:=upgrade_cost(selected_tower)
 if gold<cost:message="NEED MORE SCRAP";message_timer=1.0;return
 gold-=cost;selected_tower.level+=1;selected_tower.range+=14;selected_tower.spent+=cost;message="SCRAP UPGRADE LV%d"%selected_tower.level;message_timer=1.0
func sell_selected()->void:
 if selected_tower.is_empty():return
 var refund:=int(selected_tower.spent*.65);gold+=refund;towers.erase(selected_tower);selected_tower={};message="SALVAGED +%d"%refund;message_timer=1.0
func restart()->void:
 towers.clear();enemies.clear();shots.clear();gold=180;lives=20;wave=0;wave_left=0;spawn_timer=0.0;wave_delay=1.5;game_over=false;victory=false;paused=false;game_speed=1.0;selected_type=0;selected_tower={};kills=0;score=0;message="FORTIFY WILBIRD CAMP";message_timer=3.0;queue_redraw()
func handle_press(p:Vector2)->void:
 if game_over:restart();return
 if p.y<82:
  if p.x<500:selected_type=clamp(int((p.x-15.0)/160.0),0,2);selected_tower={}
  elif p.x<670:
   if not selected_tower.is_empty():upgrade_selected()
   else:start_wave()
  elif p.x<790:
   if not selected_tower.is_empty():sell_selected()
  elif p.x<875:game_speed=2.0 if game_speed<2.0 else 1.0
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

func draw_scrap_tower(t:Dictionary)->void:
 var p:Vector2=t.pos;var c:TOWER_COLORS[t.type];draw_circle(p,23+2*t.level,Color("22201b"));draw_circle(p,19+2*t.level,Color("705b43"));draw_circle(p,13+2*t.level,c.darkened(.25))
 if t.type==0:draw_rect(Rect2(p+Vector2(-5,-27),Vector2(10,29)),c,true);draw_rect(Rect2(p+Vector2(2,-29),Vector2(17,7)),Color("b6a174"),true)
 elif t.type==1:draw_rect(Rect2(p+Vector2(-13,-18),Vector2(26,28)),Color("c8e5dd"),true);draw_line(p+Vector2(-9,-12),p+Vector2(9,-12),c,4);draw_circle(p+Vector2(0,-21),7,c)
 else:draw_circle(p,14,Color("3b3a35"));draw_circle(p,8,Color("151719"));draw_rect(Rect2(p+Vector2(-5,-30),Vector2(10,28)),c,true)
 for n in range(t.level-1):draw_circle(p+Vector2(-18+n*12,18),4,Color("f2cc67"))
func draw_raider(e:Dictionary)->void:
 var p:Vector2=e.pos
 if e.boss:
  draw_rect(Rect2(p-Vector2(31,19),Vector2(62,38)),Color("493d32"),true);draw_rect(Rect2(p+Vector2(-17,-25),Vector2(34,17)),Color("75624b"),true);draw_circle(p+Vector2(-22,20),9,Color("17191a"));draw_circle(p+Vector2(22,20),9,Color("17191a"));draw_rect(Rect2(p+Vector2(16,-15),Vector2(22,8)),Color("d56d45"),true)
 else:
  var ec:=Color("9b718a") if e.armored else Color("c65a54");draw_circle(p,17 if e.armored else 14,Color("292420"));draw_circle(p,13 if e.armored else 10,ec);draw_line(p+Vector2(-12,0),p+Vector2(12,0),Color("d6b16d"),3)
 if e.slow>0:draw_arc(p,31 if e.boss else 21,0,TAU,28,Color("8ff5ef"),2)
 var bw:=54.0 if e.boss else 32.0;var by:=-36 if e.boss else -25;draw_rect(Rect2(p+Vector2(-bw/2,by),Vector2(bw,4)),Color("452a31"),true);draw_rect(Rect2(p+Vector2(-bw/2,by),Vector2(bw*max(0.0,e.hp/e.max_hp),4)),Color("76dc8a"),true)
func _draw()->void:
 draw_rect(Rect2(0,0,W,H),Color("16241f"));draw_rect(Rect2(0,82,W,H-82),Color("324a36"))
 for x in range(35,930,95):draw_circle(Vector2(x,110+(x*29)%390),10+(x%9),Color("263e2d"));draw_line(Vector2(x,470),Vector2(x+20,430),Color("486746"),3)
 for i in range(PATH.size()-1):draw_line(PATH[i],PATH[i+1],Color("665d4e"),70,true);draw_line(PATH[i],PATH[i+1],Color("96846b"),3,true)
 # abandoned road markings and wrecks
 for x in range(20,900,110):draw_line(Vector2(x,270),Vector2(x+32,270),Color("b5a775"),2)
 draw_rect(Rect2(45,390,65,32),Color("6d4938"),true);draw_circle(Vector2(58,424),8,Color("1c2020"));draw_circle(Vector2(98,424),8,Color("1c2020"));draw_rect(Rect2(55,378,35,15),Color("3d5e5b"),true)
 # WilBird camp / improvised gate
 draw_rect(Rect2(900,174,58,92),Color("564735"),true);draw_rect(Rect2(908,185,42,68),Color("263d38"),true);draw_line(Vector2(910,184),Vector2(945,155),Color("d3b45e"),5);draw_circle(Vector2(947,153),7,Color("e4c765"));draw_string(ThemeDB.fallback_font,Vector2(884,290),"WILBIRD CAMP",0,-1,12,Color("e8dba9"))
 draw_string(ThemeDB.fallback_font,Vector2(18,29),"WILBIRD // SCRAPLINE",0,-1,23,Color("f0dfaa"));draw_string(ThemeDB.fallback_font,Vector2(525,29),"SCRAP %d  CAMP %d  WAVE %d/%d"%[gold,lives,wave,MAX_WAVES],0,-1,17,Color("c8e2cf"))
 for i in range(3):
  var x:=15+i*160;var active:=i==selected_type and selected_tower.is_empty();draw_rect(Rect2(x,43,145,32),Color("58705a") if active else Color("293c32"),true);draw_string(ThemeDB.fallback_font,Vector2(x+6,65),"%d %s $%d"%[i+1,TOWER_NAMES[i],TOWER_COSTS[i]],0,-1,11,Color("f4e9c7"))
 if selected_tower.is_empty():draw_rect(Rect2(505,43,155,32),Color("3c5144"),true);draw_string(ThemeDB.fallback_font,Vector2(518,65),"SPACE SEND RAID",0,-1,12,Color.WHITE)
 else:
  var uc:=upgrade_cost(selected_tower);draw_rect(Rect2(505,43,155,32),Color("496451"),true);draw_string(ThemeDB.fallback_font,Vector2(516,65),"U UPGRADE $%d"%uc,0,-1,12,Color.WHITE);draw_rect(Rect2(670,43,110,32),Color("694844"),true);draw_string(ThemeDB.fallback_font,Vector2(682,65),"S SALVAGE",0,-1,11,Color.WHITE)
 draw_rect(Rect2(790,43,75,32),Color("3c5144"),true);draw_string(ThemeDB.fallback_font,Vector2(808,65),"x%.0f"%game_speed,0,-1,13,Color.WHITE);draw_rect(Rect2(875,43,70,32),Color("3c5144"),true);draw_string(ThemeDB.fallback_font,Vector2(890,65),"PAUSE",0,-1,11,Color.WHITE)
 for t in towers:draw_scrap_tower(t);if t==selected_tower:draw_arc(t.pos,t.range,0,TAU,64,Color(TOWER_COLORS[t.type],.35),2);draw_arc(t.pos,30+2*t.level,0,TAU,32,Color.WHITE,2)
 for e in enemies:draw_raider(e)
 for s in shots:draw_circle(s.pos,5,[Color("f5e8bb"),Color("8ff5ef"),Color("ffb55e")][s.type])
 draw_string(ThemeDB.fallback_font,Vector2(18,520),"RAIDERS %d   SCORE %d   [1-3] build  [U] upgrade  [S] salvage  [F] speed"%[kills,score],0,-1,13,Color("b2c4ad"))
 if message_timer>0 and not game_over:draw_rect(Rect2(335,92,290,38),Color(0.07,0.10,0.08,.88),true);draw_string(ThemeDB.fallback_font,Vector2(370,118),message,0,-1,17,Color("f2dda0"))
 if paused and not game_over:draw_rect(Rect2(360,215,240,90),Color(0.06,0.08,0.07,.94),true);draw_string(ThemeDB.fallback_font,Vector2(427,270),"PAUSED",0,-1,30,Color.WHITE)
 if game_over:
  draw_rect(Rect2(250,170,460,190),Color(0.05,0.07,0.06,.96),true);draw_string(ThemeDB.fallback_font,Vector2(315,228),"CAMP SAVED" if victory else "CAMP OVERRUN",0,-1,34,Color("f2d578") if victory else Color("e7b0a0"));draw_string(ThemeDB.fallback_font,Vector2(330,275),"Wave %d   Raiders %d   Score %d"%[wave,kills,score],0,-1,18,Color("c8e2cf"));draw_string(ThemeDB.fallback_font,Vector2(335,320),"Tap / click / R to restart",0,-1,17,Color("b2c4ad"))
