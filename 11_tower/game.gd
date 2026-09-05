extends Node2D

const W := 960.0
const H := 540.0
const MAX_WAVES := 20
var PATH := PackedVector2Array([
 Vector2(0,285), Vector2(120,285), Vector2(120,175), Vector2(300,175),
 Vector2(300,365), Vector2(500,365), Vector2(500,205), Vector2(690,205),
 Vector2(690,335), Vector2(820,335), Vector2(820,255), Vector2(960,255)
])
var BUILD_SLOTS := PackedVector2Array([
 Vector2(65,190),Vector2(190,110),Vector2(230,255),Vector2(205,410),
 Vector2(365,105),Vector2(390,285),Vector2(420,440),Vector2(565,125),
 Vector2(585,285),Vector2(610,420),Vector2(755,145),Vector2(760,270),
 Vector2(755,430),Vector2(875,165),Vector2(885,380)
])
const TOWER_NAMES := ["SCRAP GUN","ICE BOX","WHEEL CANNON"]
const TOWER_COSTS := [60,80,110]
const TOWER_RANGES := [145.0,125.0,175.0]
const TOWER_COLORS := [Color("57c7d9"),Color("7de3cf"),Color("e5a451")]

var towers:Array[Dictionary]=[]
var enemies:Array[Dictionary]=[]
var shots:Array[Dictionary]=[]
var effects:Array[Dictionary]=[]
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
var message:="FORTIFY WILBIRD CAMP"
var message_timer:=3.0

func _ready()->void: queue_redraw()
func _process(delta:float)->void:
 if paused or game_over: update_effects(delta);queue_redraw();return
 var d:=delta*game_speed
 message_timer=max(0.0,message_timer-d)
 if wave_left>0:
  spawn_timer-=d
  if spawn_timer<=0.0: spawn_enemy();wave_left-=1;spawn_timer=max(0.18,0.72-wave*0.018)
 elif enemies.is_empty():
  if wave>=MAX_WAVES: victory=true;game_over=true;score+=lives*250+gold*5;message="WILBIRD CAMP SECURED";queue_redraw();return
  wave_delay-=d
  if wave_delay<=0.0:start_wave()
 update_enemies(d);update_towers(d);update_shots(d);update_effects(d)
 if lives<=0:lives=0;game_over=true;message="CAMP OVERRUN"
 queue_redraw()

func start_wave()->void:
 if game_over or wave_left>0 or not enemies.is_empty():return
 wave+=1;wave_left=6+wave*2;spawn_timer=0.1;wave_delay=2.5
 message="SCRAP BOSS INBOUND" if wave%5==0 else "RAIDER WAVE %d"%wave;message_timer=1.8
func spawn_enemy()->void:
 var boss:=wave%5==0 and wave_left==1;var armored:=wave>=8 and wave_left%5==0 and not boss;var runner:=wave>=4 and wave_left%4==0 and not armored and not boss
 var hp:=3.0+wave*1.35;var speed:=48.0+wave*2.1;var reward:=8+wave;var leak:=1
 if runner:hp*=0.68;speed*=1.58;reward+=3
 if armored:hp*=2.2;speed*=0.82;reward+=8
 if boss:hp*=8.0;speed*=0.62;reward*=8;leak=5
 enemies.append({"pos":PATH[0],"seg":0,"hp":hp,"max_hp":hp,"speed":speed,"slow":0.0,"reward":reward,"boss":boss,"armored":armored,"runner":runner,"leak":leak})
func update_enemies(delta:float)->void:
 for i in range(enemies.size()-1,-1,-1):
  var e=enemies[i];if e.slow>0.0:e.slow-=delta
  var target:Vector2=PATH[min(e.seg+1,PATH.size()-1)];var diff:Vector2=target-e.pos;var sp:float=e.speed*(0.58 if e.slow>0.0 else 1.0)
  if diff.length()<=sp*delta:
   e.pos=target;e.seg+=1
   if e.seg>=PATH.size()-1:lives-=e.leak;add_effect(e.pos,Color("d95d50"),40.0,0.4);enemies.remove_at(i);continue
  else:e.pos+=diff.normalized()*sp*delta
func update_towers(delta:float)->void:
 for t in towers:
  t.cd-=delta
  if t.cd>0.0:continue
  var target_index:=-1;var best:=-1
  for i in range(enemies.size()):
   var e=enemies[i]
   if t.pos.distance_to(e.pos)<=t.range and e.seg>best:best=e.seg;target_index=i
  if target_index>=0:
   var dmg:float=[1.15,0.72,3.2][t.type]*(1.0+(t.level-1)*0.55)
   shots.append({"pos":t.pos,"target":enemies[target_index],"speed":560.0,"damage":dmg,"type":t.type,"splash":42.0+12.0*t.level if t.type==2 else 0.0})
   t.cd=[0.46,0.60,1.18][t.type]/(1.0+(t.level-1)*0.16)
func update_shots(delta:float)->void:
 for i in range(shots.size()-1,-1,-1):
  var s=shots[i]
  if not enemies.has(s.target):shots.remove_at(i);continue
  var diff:Vector2=s.target.pos-s.pos
  if diff.length()<20.0:
   var impact:Vector2=s.target.pos
   if s.type==2:
    for e in enemies:
     if e.pos.distance_to(impact)<=s.splash:e.hp-=s.damage
    add_effect(impact,Color("ffb55e"),s.splash,0.28)
   else:s.target.hp-=s.damage;if s.type==1:s.target.slow=1.55
   cleanup_dead_enemies();shots.remove_at(i)
  else:s.pos+=diff.normalized()*s.speed*delta
func cleanup_dead_enemies()->void:
 for i in range(enemies.size()-1,-1,-1):
  var e=enemies[i]
  if e.hp<=0.0:
   gold+=e.reward;kills+=1;score+=e.reward*10;add_effect(e.pos,Color("efcf78") if e.boss else Color("d56a54"),42.0 if e.boss else 20.0,0.4)
   if e.boss:gold+=50;score+=500;message="BOSS SCRAPPED +50"
   enemies.remove_at(i)
func add_effect(p:Vector2,c:Color,r:float,d:float)->void:effects.append({"pos":p,"color":c,"radius":r,"life":d,"max_life":d})
func update_effects(delta:float)->void:
 for i in range(effects.size()-1,-1,-1):effects[i].life-=delta;if effects[i].life<=0.0:effects.remove_at(i)

func slot_index_at(p:Vector2)->int:
 for i in range(BUILD_SLOTS.size()):
  if p.distance_to(BUILD_SLOTS[i])<28.0:return i
 return -1
func tower_for_slot(idx:int)->Dictionary:
 for t in towers:
  if t.slot==idx:return t
 return {}
func build_slot(idx:int)->void:
 if idx<0:return
 if not tower_for_slot(idx).is_empty():selected_tower=tower_for_slot(idx);return
 var cost:int=TOWER_COSTS[selected_type]
 if gold<cost:message="NEED MORE SCRAP";message_timer=1.0;return
 gold-=cost;towers.append({"pos":BUILD_SLOTS[idx],"slot":idx,"type":selected_type,"range":TOWER_RANGES[selected_type],"cd":0.1,"level":1,"spent":cost});message="%s ONLINE"%TOWER_NAMES[selected_type];message_timer=1.0
func tower_at(p:Vector2)->Dictionary:
 for t in towers:
  if p.distance_to(t.pos)<30.0:return t
 return {}
func upgrade_cost(t:Dictionary)->int:return 45+t.level*45
func upgrade_selected()->void:
 if selected_tower.is_empty():return
 if selected_tower.level>=4:message="MAX LEVEL";return
 var cost:=upgrade_cost(selected_tower)
 if gold<cost:message="NEED MORE SCRAP";return
 gold-=cost;selected_tower.level+=1;selected_tower.range+=16.0;selected_tower.spent+=cost;add_effect(selected_tower.pos,Color("f2cc67"),45.0,0.45);message="UPGRADE LV%d"%selected_tower.level
func sell_selected()->void:
 if selected_tower.is_empty():return
 var refund:=int(selected_tower.spent*0.65);gold+=refund;towers.erase(selected_tower);selected_tower={};message="SALVAGED +%d"%refund
func restart()->void:towers.clear();enemies.clear();shots.clear();effects.clear();gold=180;lives=20;wave=0;wave_left=0;wave_delay=1.5;game_over=false;victory=false;paused=false;selected_tower={};kills=0;score=0;message="FORTIFY WILBIRD CAMP";queue_redraw()
func handle_press(p:Vector2)->void:
 if game_over:restart();return
 if p.y<82.0:
  if p.x<500.0:selected_type=clamp(int((p.x-15.0)/160.0),0,2);selected_tower={}
  elif p.x<670.0:
   if selected_tower.is_empty():start_wave()
   else:upgrade_selected()
  elif p.x<790.0:sell_selected()
  elif p.x<875.0:game_speed=2.0 if game_speed<2.0 else 1.0
  else:paused=not paused
  return
 var hit:=tower_at(p)
 if not hit.is_empty():selected_tower=hit;return
 selected_tower={};build_slot(slot_index_at(p))
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

func draw_tower(t:Dictionary)->void:
 var p:Vector2=t.pos;var c:Color=TOWER_COLORS[t.type];var lv:int=t.level
 draw_circle(p,22.0+lv*2,Color("29251f"));draw_circle(p,17.0+lv*2,c.darkened(0.35))
 if t.type==0:
  for n in range(lv):draw_rect(Rect2(p+Vector2(-3+n*5,-27-lv*2),Vector2(5,28+lv*2)),c,true)
  draw_rect(Rect2(p+Vector2(0,-29-lv*2),Vector2(18+lv*5,7+lv)),Color("c5ad78"),true)
 elif t.type==1:
  draw_rect(Rect2(p+Vector2(-13-lv*2,-17-lv*2),Vector2(26+lv*4,30+lv*3)),Color("d6efea"),true);draw_circle(p+Vector2(0,-20-lv*2),6+lv*2,c)
  for n in range(lv):draw_line(p,p+Vector2(cos(n*1.57)*25,sin(n*1.57)*25),c,2.0)
 else:
  draw_circle(p,12+lv*2,Color("17191a"));draw_rect(Rect2(p+Vector2(-5-lv,-31-lv*3),Vector2(10+lv*2,32+lv*3)),c,true)
  if lv>=3:draw_rect(Rect2(p+Vector2(-17,-18),Vector2(34,8)),Color("8d7555"),true)
 for n in range(lv):draw_circle(p+Vector2(-15+n*10,20),3.0,Color("f2cc67"))
func draw_enemy(e:Dictionary)->void:
 var p:Vector2=e.pos;var c:=Color("d56d45") if e.boss else (Color("77736b") if e.armored else (Color("e0b75e") if e.runner else Color("b94e42")));var r:=28.0 if e.boss else (16.0 if e.armored else 12.0)
 draw_circle(p,r,Color("201d1a"));draw_circle(p,r-4,c);var ratio:float=max(0.0,e.hp/e.max_hp);draw_rect(Rect2(p+Vector2(-18,-r-9),Vector2(36,4)),Color("321d1b"),true);draw_rect(Rect2(p+Vector2(-18,-r-9),Vector2(36*ratio,4)),Color("78b768"),true)
func _draw()->void:
 draw_rect(Rect2(0,0,W,H),Color("17231d"),true)
 for x in range(25,960,95):draw_circle(Vector2(x,120+(x%4)*95),18,Color("29402d"));draw_circle(Vector2(x+35,465-(x%3)*80),15,Color("24382a"))
 # route: accotement, asphalte use, ligne centrale
 for i in range(PATH.size()-1):
  draw_line(PATH[i],PATH[i+1],Color("3a332b"),76.0);draw_line(PATH[i],PATH[i+1],Color("625a50"),58.0);draw_line(PATH[i],PATH[i+1],Color("c0a96b"),3.0)
 for p in BUILD_SLOTS:
  var idx:=BUILD_SLOTS.find(p)
  if tower_for_slot(idx).is_empty():draw_circle(p,23.0,Color("78654b"));draw_circle(p,17.0,Color("2b2b25"));draw_string(ThemeDB.fallback_font,p+Vector2(-6,6),"+",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("d9c278"))
 draw_rect(Rect2(900,210,58,90),Color("4a493d"),true);draw_string(ThemeDB.fallback_font,Vector2(904,240),"CAMP",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f0cf72"))
 for t in towers:draw_tower(t)
 for e in enemies:draw_enemy(e)
 for s in shots:draw_circle(s.pos,5.0,TOWER_COLORS[s.type])
 for fx in effects:
  var a:float=clamp(fx.life/fx.max_life,0.0,1.0);var cc:Color=fx.color;cc.a=a;draw_circle(fx.pos,fx.radius*(1.0-a*0.5),cc,false,3.0)
 if not selected_tower.is_empty():draw_circle(selected_tower.pos,selected_tower.range,Color(1,1,1,0.16),false,2.0)
 draw_rect(Rect2(0,0,W,82),Color("0d1511"),true);draw_string(ThemeDB.fallback_font,Vector2(15,25),"WILBIRD // SCRAPLINE",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("f0cf72"));draw_string(ThemeDB.fallback_font,Vector2(510,24),"SCRAP %d   CAMP %d   WAVE %d/%d"%[gold,lives,wave,MAX_WAVES],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(15,62),"1 SCRAP GUN 60       2 ICE BOX 80       3 WHEEL CANNON 110",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("a9ddd4"));draw_string(ThemeDB.fallback_font,Vector2(510,58),"KILLS %d  SCORE %d  [SPACE] WAVE  [U] UPGRADE  [S] SELL"%[kills,score],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("c4c9c2"))
 if message_timer>0.0 or game_over:draw_string(ThemeDB.fallback_font,Vector2(330,105),message,HORIZONTAL_ALIGNMENT_CENTER,300,18,Color("f0cf72"))
