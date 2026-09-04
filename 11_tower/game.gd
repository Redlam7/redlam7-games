extends Node2D

const W := 960.0
const H := 540.0
const MAX_WAVES := 20
var PATH := PackedVector2Array([
 Vector2(0,270), Vector2(180,270), Vector2(180,130), Vector2(430,130),
 Vector2(430,390), Vector2(700,390), Vector2(700,220), Vector2(960,220)
])
const TOWER_NAMES := ["SCRAP GUN", "ICE BOX", "WHEEL CANNON"]
const TOWER_COSTS := [60, 80, 110]
const TOWER_RANGES := [145.0, 125.0, 175.0]
const TOWER_COLORS := [Color("57c7d9"), Color("7de3cf"), Color("e5a451")]

var towers: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var gold := 180
var lives := 20
var wave := 0
var wave_left := 0
var spawn_timer := 0.0
var wave_delay := 1.5
var game_over := false
var victory := false
var paused := false
var game_speed := 1.0
var selected_type := 0
var selected_tower: Dictionary = {}
var kills := 0
var score := 0
var message := "FORTIFY WILBIRD CAMP"
var message_timer := 3.0
var mascot_blink := 0.0

func _ready() -> void:
 queue_redraw()

func _process(delta: float) -> void:
 mascot_blink += delta
 if paused or game_over:
  update_effects(delta)
  queue_redraw()
  return
 var d := delta * game_speed
 message_timer = max(0.0, message_timer - d)
 if wave_left > 0:
  spawn_timer -= d
  if spawn_timer <= 0.0:
   spawn_enemy()
   wave_left -= 1
   spawn_timer = max(0.18, 0.72 - wave * 0.018)
 elif enemies.is_empty():
  if wave >= MAX_WAVES:
   victory = true
   game_over = true
   score += lives * 250 + gold * 5
   message = "WILBIRD CAMP SECURED"
   add_effect(Vector2(925,220), Color("f2d578"), 55.0, 0.8)
   queue_redraw()
   return
  wave_delay -= d
  if wave_delay <= 0.0:
   start_wave()
 update_enemies(d)
 update_towers(d)
 update_shots(d)
 update_effects(d)
 if lives <= 0:
  lives = 0
  game_over = true
  message = "CAMP OVERRUN"
 queue_redraw()

func start_wave() -> void:
 if game_over or wave_left > 0 or not enemies.is_empty(): return
 wave += 1
 wave_left = 6 + wave * 2
 spawn_timer = 0.1
 wave_delay = 2.5
 message = "SCRAP BOSS INBOUND" if wave % 5 == 0 else "RAIDER WAVE %d" % wave
 message_timer = 1.8

func spawn_enemy() -> void:
 var boss := wave % 5 == 0 and wave_left == 1
 var armored := wave >= 8 and wave_left % 5 == 0 and not boss
 var runner := wave >= 4 and wave_left % 4 == 0 and not armored and not boss
 var hp := 3.0 + wave * 1.35
 var speed := 48.0 + wave * 2.1
 var reward := 8 + wave
 var leak := 1
 if runner: hp *= 0.68; speed *= 1.58; reward += 3
 if armored: hp *= 2.2; speed *= 0.82; reward += 8
 if boss: hp *= 8.0; speed *= 0.62; reward *= 8; leak = 5
 enemies.append({"pos":PATH[0],"seg":0,"hp":hp,"max_hp":hp,"speed":speed,"slow":0.0,"reward":reward,"boss":boss,"armored":armored,"runner":runner,"leak":leak})

func update_enemies(delta: float) -> void:
 for i in range(enemies.size()-1,-1,-1):
  var e=enemies[i]
  if e.slow>0.0: e.slow-=delta
  var target:Vector2=PATH[min(e.seg+1,PATH.size()-1)]
  var diff:Vector2=target-e.pos
  var sp:float=e.speed*(0.58 if e.slow>0.0 else 1.0)
  if diff.length()<=sp*delta:
   e.pos=target; e.seg+=1
   if e.seg>=PATH.size()-1:
    lives-=e.leak; add_effect(e.pos,Color("d95d50"),48.0 if e.boss else 28.0,0.45); enemies.remove_at(i); continue
  else: e.pos+=diff.normalized()*sp*delta

func update_towers(delta: float) -> void:
 for t in towers:
  t.cd-=delta
  if t.cd>0.0: continue
  var target_index:=-1
  var best_progress:=-1
  var best_distance:float=INF
  for i in range(enemies.size()):
   var e=enemies[i]
   var dist:float=t.pos.distance_squared_to(e.pos)
   if dist<=t.range*t.range and (e.seg>best_progress or (e.seg==best_progress and dist<best_distance)):
    best_progress=e.seg; best_distance=dist; target_index=i
  if target_index>=0:
   var dmg:float=[1.15,0.72,3.2][t.type]*(1.0+(t.level-1)*0.48)
   shots.append({"pos":t.pos,"target":enemies[target_index],"speed":560.0,"damage":dmg,"type":t.type,"splash":42.0+10.0*t.level if t.type==2 else 0.0})
   t.cd=[0.46,0.60,1.18][t.type]/(1.0+(t.level-1)*0.14)
   add_effect(t.pos,TOWER_COLORS[t.type],10.0,0.16)

func update_shots(delta: float) -> void:
 for i in range(shots.size()-1,-1,-1):
  var s=shots[i]
  if not enemies.has(s.target): shots.remove_at(i); continue
  var diff:Vector2=s.target.pos-s.pos
  if diff.length()<20.0:
   var impact:Vector2=s.target.pos
   if s.type==2:
    for e in enemies:
     if e.pos.distance_to(impact)<=s.splash: e.hp-=s.damage
    add_effect(impact,Color("ffb55e"),s.splash,0.28)
   else:
    s.target.hp-=s.damage
    if s.type==1: s.target.slow=1.55; add_effect(impact,Color("8ff5ef"),25.0,0.24)
    else: add_effect(impact,Color("f5e8bb"),16.0,0.16)
   cleanup_dead_enemies(); shots.remove_at(i)
  else: s.pos+=diff.normalized()*s.speed*delta

func cleanup_dead_enemies() -> void:
 for i in range(enemies.size()-1,-1,-1):
  var e=enemies[i]
  if e.hp<=0.0:
   gold+=e.reward; kills+=1; score+=e.reward*10
   add_effect(e.pos,Color("efcf78") if e.boss else Color("d56a54"),45.0 if e.boss else 22.0,0.42)
   if e.boss: gold+=50; score+=500; message="BOSS SCRAPPED +50"; message_timer=1.6
   enemies.remove_at(i)

func add_effect(p:Vector2,color:Color,radius:float,duration:float)->void: effects.append({"pos":p,"color":color,"radius":radius,"life":duration,"max_life":duration})
func update_effects(delta:float)->void:
 for i in range(effects.size()-1,-1,-1):
  effects[i].life-=delta
  if effects[i].life<=0.0: effects.remove_at(i)

func can_build(p:Vector2)->bool:
 if p.y<92.0:return false
 for t in towers:
  if p.distance_to(t.pos)<58.0:return false
 for i in range(PATH.size()-1):
  if Geometry2D.get_closest_point_to_segment(p,PATH[i],PATH[i+1]).distance_to(p)<50.0:return false
 return true

func build(p:Vector2)->void:
 var cost:int=TOWER_COSTS[selected_type]
 if gold>=cost and can_build(p):
  gold-=cost; towers.append({"pos":p,"type":selected_type,"range":TOWER_RANGES[selected_type],"cd":0.1,"level":1,"spent":cost}); message="%s BUILT"%TOWER_NAMES[selected_type]
 elif gold<cost: message="NEED MORE SCRAP"
 else: message="ROAD MUST STAY CLEAR"
 message_timer=1.1

func tower_at(p:Vector2)->Dictionary:
 for t in towers:
  if p.distance_to(t.pos)<30.0:return t
 return {}
func upgrade_cost(t:Dictionary)->int:return 55+t.level*40
func upgrade_selected()->void:
 if selected_tower.is_empty():return
 if selected_tower.level>=4:message="MAXED OUT";message_timer=1.0;return
 var cost:=upgrade_cost(selected_tower)
 if gold<cost:message="NEED MORE SCRAP";message_timer=1.0;return
 gold-=cost;selected_tower.level+=1;selected_tower.range+=14.0;selected_tower.spent+=cost;add_effect(selected_tower.pos,Color("f2cc67"),42.0,0.45);message="SCRAP UPGRADE LV%d"%selected_tower.level;message_timer=1.0
func sell_selected()->void:
 if selected_tower.is_empty():return
 var refund:=int(selected_tower.spent*0.65);gold+=refund;add_effect(selected_tower.pos,Color("d4b66c"),32.0,0.3);towers.erase(selected_tower);selected_tower={};message="SALVAGED +%d"%refund;message_timer=1.0

func restart()->void:
 towers.clear();enemies.clear();shots.clear();effects.clear();gold=180;lives=20;wave=0;wave_left=0;spawn_timer=0.0;wave_delay=1.5;game_over=false;victory=false;paused=false;game_speed=1.0;selected_type=0;selected_tower={};kills=0;score=0;message="FORTIFY WILBIRD CAMP";message_timer=3.0;queue_redraw()

func handle_press(p:Vector2)->void:
 if game_over:restart();return
 if p.y<82.0:
  if p.x<500.0:selected_type=clamp(int((p.x-15.0)/160.0),0,2);selected_tower={}
  elif p.x<670.0:
   if not selected_tower.is_empty():upgrade_selected()
   else:start_wave()
  elif p.x<790.0:
   if not selected_tower.is_empty():sell_selected()
  elif p.x<875.0:game_speed=2.0 if game_speed<2.0 else 1.0
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
 var p:Vector2=t.pos;var c:Color=TOWER_COLORS[t.type];var lv:int=t.level
 draw_circle(p,23+2*lv,Color("22201b"));draw_circle(p,19+2*lv,Color("705b43"));draw_circle(p,13+2*lv,c.darkened(0.25))
 if t.type==0:draw_rect(Rect2(p+Vector2(-5,-27-lv*2),Vector2(10,29+lv*2)),c,true);draw_rect(Rect2(p+Vector2(2,-29-lv*2),Vector2(17+lv*3,7)),Color("b6a174"),true)
 elif t.type==1:draw_rect(Rect2(p+Vector2(-13-lv,-18-lv),Vector2(26+lv*2,28+lv*2)),Color("c8e5dd"),true);draw_line(p+Vector2(-9,-12),p+Vector2(9,-12),c,4+lv);draw_circle(p+Vector2(0,-21-lv),7+lv,c)
 else:draw_circle(p,14+lv,Color("3b3a35"));draw_circle(p,8,Color("151719"));draw_rect(Rect2(p+Vector2(-5,-30-lv*2),Vector2(10+lv,28+lv*2)),c,true)
 for n in range(lv-1):draw_circle(p+Vector2(-18+n*12,18),4,Color("f2cc67"))

func draw_raider(e:Dictionary)->void:
 var p:Vector2=e.pos
 var c:=Color("d56d45") if e.boss else (Color("7e7463") if e.armored else (Color("d9b66f") if e.runner else Color("b44f42")))
 var r:=30.0 if e.boss else (17.0 if e.armored else 13.0)
 draw_circle(p,r,Color("25231f"));draw_circle(p,r-4,c);draw_circle(p+Vector2(0,-r*0.35),r*0.35,Color("d6b08b"))
 if e.boss:draw_rect(Rect2(p-Vector2(34,20),Vector2(68,40)),Color("493d32"),false,5.0)
 var ratio:float=max(0.0,e.hp/e.max_hp);draw_rect(Rect2(p+Vector2(-20,-r-10),Vector2(40,5)),Color("311d1b"),true);draw_rect(Rect2(p+Vector2(-20,-r-10),Vector2(40*ratio,5)),Color("77b86a"),true)

func _draw()->void:
 draw_rect(Rect2(0,0,W,H),Color("17231d"),true)
 for x in range(0,960,80):
  draw_circle(Vector2(x+35,110+(x%5)*75),24,Color("24382a"));draw_circle(Vector2(x+55,470-(x%4)*55),18,Color("2c432e"))
 for i in range(PATH.size()-1):draw_line(PATH[i],PATH[i+1],Color("6c5c49"),70.0);draw_line(PATH[i],PATH[i+1],Color("87745b"),50.0)
 draw_rect(Rect2(870,165,80,110),Color("4a493d"),true);draw_string(ThemeDB.fallback_font,Vector2(878,205),"WILBIRD",HORIZONTAL_ALIGNMENT_LEFT,70,15,Color("f0cf72"));draw_string(ThemeDB.fallback_font,Vector2(884,230),"CAMP",HORIZONTAL_ALIGNMENT_LEFT,60,18,Color.WHITE)
 for t in towers:draw_scrap_tower(t)
 for e in enemies:draw_raider(e)
 for s in shots:draw_circle(s.pos,5.0,TOWER_COLORS[s.type])
 for fx in effects:
  var a:float=clamp(fx.life/fx.max_life,0.0,1.0);var cc:Color=fx.color;cc.a=a;draw_circle(fx.pos,fx.radius*(1.0-a*0.4),cc,false,3.0)
 draw_rect(Rect2(0,0,W,82),Color("101612"),true)
 draw_string(ThemeDB.fallback_font,Vector2(15,25),"WILBIRD // SCRAPLINE",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("f0cf72"))
 for i in range(3):draw_string(ThemeDB.fallback_font,Vector2(15+i*160,55),"%d %s %d"%[i+1,TOWER_NAMES[i],TOWER_COSTS[i]],HORIZONTAL_ALIGNMENT_LEFT,155,13,TOWER_COLORS[i])
 draw_string(ThemeDB.fallback_font,Vector2(500,25),"SCRAP %d   CAMP %d   WAVE %d/%d"%[gold,lives,wave,MAX_WAVES],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(500,53),"KILLS %d  SCORE %d  [SPACE] WAVE  [F] x%.0f  [P] PAUSE"%[kills,score,game_speed],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("b9c5b6"))
 if not selected_tower.is_empty():
  draw_arc(selected_tower.pos,selected_tower.range,0,TAU,64,Color(1,1,1,0.28),2.0);draw_string(ThemeDB.fallback_font,Vector2(500,75),"SELECTED LV%d  [U] UPGRADE %d  [S] SELL"%[selected_tower.level,upgrade_cost(selected_tower)],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f2cc67"))
 if message_timer>0.0:draw_string(ThemeDB.fallback_font,Vector2(330,105),message,HORIZONTAL_ALIGNMENT_CENTER,300,20,Color("f2cc67"))
 if game_over:
  draw_rect(Rect2(250,180,460,170),Color(0.04,0.06,0.05,0.92),true);draw_string(ThemeDB.fallback_font,Vector2(300,235),"WILBIRD CAMP SECURED" if victory else "CAMP OVERRUN",HORIZONTAL_ALIGNMENT_CENTER,360,30,Color("f0cf72") if victory else Color("d95d50"));draw_string(ThemeDB.fallback_font,Vector2(300,280),"FINAL SCORE %d"%score,HORIZONTAL_ALIGNMENT_CENTER,360,22,Color.WHITE);draw_string(ThemeDB.fallback_font,Vector2(300,320),"R / TAP TO RESTART",HORIZONTAL_ALIGNMENT_CENTER,360,16,Color("c7d2c2"))
