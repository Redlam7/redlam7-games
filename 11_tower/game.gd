extends Node2D

const W:=960.0
const H:=540.0
var path:=PackedVector2Array([Vector2(0,270),Vector2(180,270),Vector2(180,130),Vector2(430,130),Vector2(430,390),Vector2(700,390),Vector2(700,220),Vector2(960,220)])
var towers:Array[Dictionary]=[]
var enemies:Array[Dictionary]=[]
var shots:Array[Dictionary]=[]
var gold:=180
var lives:=20
var wave:=0
var wave_left:=0
var spawn_timer:=0.0
var wave_delay:=1.0
var game_over:=false
var selected_type:=0
var selected_tower:Dictionary={}
var tower_names:=["BLASTER","FROST","CANNON"]
var tower_costs:=[60,80,110]

func _ready()->void:queue_redraw()

func _process(delta:float)->void:
 if game_over:return
 if wave_left>0:
  spawn_timer-=delta
  if spawn_timer<=0:
   spawn_enemy();wave_left-=1;spawn_timer=max(.25,.75-wave*.025)
 elif enemies.is_empty():
  wave_delay-=delta
  if wave_delay<=0:start_wave()
 update_enemies(delta);update_towers(delta);update_shots(delta)
 if lives<=0:game_over=true
 queue_redraw()

func start_wave()->void:
 wave+=1;wave_left=5+wave*2;wave_delay=2.5

func spawn_enemy()->void:
 var boss:=wave%5==0 and wave_left==1
 var hp:=2.0+wave*.8
 var speed:=55.0+wave*2.0
 var reward:=8+wave
 if boss:hp*=7.0;speed*=.65;reward*=8
 enemies.append({"pos":path[0],"seg":0,"hp":hp,"max_hp":hp,"speed":speed,"slow":0.0,"reward":reward,"boss":boss})

func update_enemies(delta:float)->void:
 for i in range(enemies.size()-1,-1,-1):
  var e=enemies[i]
  if e.slow>0:e.slow-=delta
  var target:Vector2=path[min(e.seg+1,path.size()-1)]
  var d:Vector2=target-e.pos
  var sp:float=e.speed*(.55 if e.slow>0 else 1.0)
  if d.length()<=sp*delta:
   e.pos=target;e.seg+=1
   if e.seg>=path.size()-1:
    enemies.remove_at(i);lives-=3 if e.boss else 1;continue
  else:e.pos+=d.normalized()*sp*delta

func update_towers(delta:float)->void:
 for t in towers:
  t.cd-=delta
  if t.cd>0:continue
  var target=-1;var bd=INF
  for i in range(enemies.size()):
   var d:float=t.pos.distance_squared_to(enemies[i].pos)
   if d<t.range*t.range and d<bd:bd=d;target=i
  if target>=0:
   var dmg:float=[1.0,.65,2.6][t.type]*(1.0+(t.level-1)*.45)
   shots.append({"pos":t.pos,"target":enemies[target],"speed":520.0,"damage":dmg,"type":t.type})
   t.cd=[.48,.62,1.15][t.type]/(1.0+(t.level-1)*.12)

func update_shots(delta:float)->void:
 for i in range(shots.size()-1,-1,-1):
  var s=shots[i]
  if not enemies.has(s.target):shots.remove_at(i);continue
  var d:Vector2=s.target.pos-s.pos
  if d.length()<18:
   s.target.hp-=s.damage
   if s.type==1:s.target.slow=1.4
   if s.target.hp<=0:
    gold+=s.target.reward;enemies.erase(s.target)
   shots.remove_at(i)
  else:s.pos+=d.normalized()*s.speed*delta

func can_build(p:Vector2)->bool:
 if p.y<90:return false
 for t in towers:
  if p.distance_to(t.pos)<58:return false
 for i in range(path.size()-1):
  if Geometry2D.get_closest_point_to_segment(p,path[i],path[i+1]).distance_to(p)<48:return false
 return true

func build(p:Vector2)->void:
 var cost:int=tower_costs[selected_type]
 if gold>=cost and can_build(p):
  gold-=cost;towers.append({"pos":p,"type":selected_type,"range":[145.0,125.0,175.0][selected_type],"cd":.1,"level":1})

func tower_at(p:Vector2)->Dictionary:
 for t in towers:
  if p.distance_to(t.pos)<28:return t
 return {}

func upgrade_selected()->void:
 if selected_tower.is_empty():return
 var cost:int=45+selected_tower.level*35
 if selected_tower.level<4 and gold>=cost:
  gold-=cost;selected_tower.level+=1;selected_tower.range+=12

func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed:
  if event.keycode==KEY_1:selected_type=0;selected_tower={}
  elif event.keycode==KEY_2:selected_type=1;selected_tower={}
  elif event.keycode==KEY_3:selected_type=2;selected_tower={}
  elif event.keycode==KEY_U:upgrade_selected()
  elif event.keycode==KEY_R and game_over:get_tree().reload_current_scene()
 elif event is InputEventMouseButton and event.pressed:
  if event.position.y<80:
   selected_type=clamp(int(event.position.x/180.0),0,2);selected_tower={}
  elif game_over:get_tree().reload_current_scene()
  else:
   var hit:=tower_at(event.position)
   if not hit.is_empty():selected_tower=hit
   else:selected_tower={};build(event.position)
 elif event is InputEventScreenTouch and event.pressed:
  if event.position.y<80:selected_type=clamp(int(event.position.x/180.0),0,2);selected_tower={}
  elif game_over:get_tree().reload_current_scene()
  else:
   var hit:=tower_at(event.position)
   if not hit.is_empty():
    selected_tower=hit;upgrade_selected()
   else:selected_tower={};build(event.position)
 queue_redraw()

func _draw()->void:
 draw_rect(Rect2(0,0,W,H),Color("101722"))
 for i in range(path.size()-1):draw_line(path[i],path[i+1],Color("34475b"),64,true)
 draw_string(ThemeDB.fallback_font,Vector2(20,34),"REDLAM7 // TOWER",0,-1,25,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(550,34),"GOLD %d   LIVES %d   WAVE %d"%[gold,lives,wave],0,-1,18,Color("9fdcf0"))
 for i in range(3):
  var x:=20+i*170;var c:=Color("26384b") if i!=selected_type else Color("42647d");draw_rect(Rect2(x,48,155,32),c,true);draw_string(ThemeDB.fallback_font,Vector2(x+8,70),"%d %s $%d"%[i+1,tower_names[i],tower_costs[i]],0,-1,13,Color.WHITE)
 for t in towers:
  var c:=[Color("55c6e8"),Color("74e0d1"),Color("e6a85d")][t.type];draw_circle(t.pos,18+2*t.level,c);draw_string(ThemeDB.fallback_font,t.pos+Vector2(-5,5),str(t.level),0,-1,13,Color("101722"));draw_arc(t.pos,t.range,0,TAU,48,Color(c,.12),1)
  if t==selected_tower:draw_arc(t.pos,26+2*t.level,0,TAU,32,Color.WHITE,2)
 for e in enemies:
  draw_circle(e.pos,24 if e.boss else 15,Color("f0a34b") if e.boss else Color("cf536d"));draw_rect(Rect2(e.pos+Vector2(-20 if e.boss else -16,-32 if e.boss else -24),Vector2(40 if e.boss else 32,4)),Color("44252c"),true);draw_rect(Rect2(e.pos+Vector2(-20 if e.boss else -16,-32 if e.boss else -24),Vector2((40 if e.boss else 32)*max(0.0,e.hp/e.max_hp),4)),Color("78d88a"),true)
 for s in shots:draw_circle(s.pos,4,[Color.WHITE,Color("8ff5ef"),Color("ffc46b")][s.type])
 if not selected_tower.is_empty():
  var uc:=45+selected_tower.level*35;draw_string(ThemeDB.fallback_font,Vector2(600,72),"TOWER LV%d  UPGRADE U: $%d"%[selected_tower.level,uc],0,-1,14,Color.WHITE)
 if game_over:
  draw_rect(Rect2(260,190,440,150),Color(0.03,0.04,0.07,.94),true);draw_string(ThemeDB.fallback_font,Vector2(365,245),"BASE LOST",0,-1,34,Color.WHITE);draw_string(ThemeDB.fallback_font,Vector2(350,290),"Tap or R to restart",0,-1,19,Color("9fdcf0"))
