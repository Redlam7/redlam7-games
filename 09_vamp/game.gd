extends Node2D

const W:=720.0
const H:=1280.0
var player_pos:=Vector2(360,640)
var player_radius:=24.0
var hp:=100.0
var xp:=0
var level:=1
var score:=0
var best:=0
var kills:=0
var weapon_level:=1
var enemies:Array[Dictionary]=[]
var projectiles:Array[Dictionary]=[]
var gems:Array[Dictionary]=[]
var spawn_timer:=0.0
var attack_timer:=0.0
var elapsed:=0.0
var game_over:=false
var rng:=RandomNumberGenerator.new()

func _ready()->void:
 rng.randomize();best=load_best();restart()

func _process(delta:float)->void:
 if game_over:return
 elapsed+=delta;spawn_timer-=delta;attack_timer-=delta
 if spawn_timer<=0.0:
  spawn_enemy();spawn_timer=max(.22,1.12-elapsed*.011)
 if attack_timer<=0.0:
  auto_attack();attack_timer=max(.16,.72-weapon_level*.055)
 var dir:=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
 player_pos+=dir*(260.0+level*4.0)*delta
 player_pos.x=clamp(player_pos.x,35.0,W-35.0);player_pos.y=clamp(player_pos.y,145.0,H-35.0)
 update_enemies(delta);update_projectiles(delta);collect_gems()
 if hp<=0.0:finish_game()
 queue_redraw()

func spawn_enemy()->void:
 var side:=rng.randi_range(0,3);var p:=Vector2.ZERO
 match side:
  0:p=Vector2(rng.randf_range(0,W),130)
  1:p=Vector2(W,rng.randf_range(140,H))
  2:p=Vector2(rng.randf_range(0,W),H)
  3:p=Vector2(0,rng.randf_range(140,H))
 var tier:=1+int(elapsed/30.0)
 var elite:=rng.randf()<min(.22,.03+elapsed/900.0)
 enemies.append({"pos":p,"r":(20.0+min(tier,5)*2.0)*(1.35 if elite else 1.0),"hp":(1+int(elapsed/45.0))*(3 if elite else 1),"speed":(58.0+elapsed*.9)*(.78 if elite else 1.0),"elite":elite})

func auto_attack()->void:
 if enemies.is_empty():return
 var target=enemies[0];var best_d:=player_pos.distance_squared_to(target.pos)
 for e in enemies:
  var d:=player_pos.distance_squared_to(e.pos)
  if d<best_d:best_d=d;target=e
 var base_dir:Vector2=(target.pos-player_pos).normalized()
 var shots:=1+int(weapon_level>=4)+int(weapon_level>=7)
 for s in range(shots):
  var spread:=(float(s)-float(shots-1)/2.0)*.14
  projectiles.append({"pos":player_pos,"vel":base_dir.rotated(spread)*(535.0+weapon_level*15.0),"r":7.0+weapon_level*.35,"damage":1+int(weapon_level>=6)})

func update_enemies(delta:float)->void:
 for e in enemies:
  var d:Vector2=player_pos-e.pos
  if d.length()>.001:e.pos+=d.normalized()*e.speed*delta
  if player_pos.distance_to(e.pos)<player_radius+e.r:hp-=22.0*delta*(1.4 if e.elite else 1.0)

func update_projectiles(delta:float)->void:
 for pi in range(projectiles.size()-1,-1,-1):
  var p=projectiles[pi];p.pos+=p.vel*delta
  var remove_p:=p.pos.x<-20 or p.pos.x>W+20 or p.pos.y<100 or p.pos.y>H+20
  if not remove_p:
   for ei in range(enemies.size()-1,-1,-1):
    var e=enemies[ei]
    if p.pos.distance_to(e.pos)<p.r+e.r:
     e.hp-=p.damage;remove_p=true
     if e.hp<=0:
      var value:=3 if e.elite else 1
      gems.append({"pos":e.pos,"value":value});enemies.remove_at(ei);kills+=1;score+=30 if e.elite else 10;best=max(best,score)
     break
  if remove_p:projectiles.remove_at(pi)

func collect_gems()->void:
 for i in range(gems.size()-1,-1,-1):
  var g=gems[i]
  if player_pos.distance_to(g.pos)<player_radius+22.0:
   xp+=g.value;gems.remove_at(i)
   while xp>=xp_needed():
    xp-=xp_needed();level+=1;weapon_level+=1;hp=min(100.0,hp+20.0);score+=level*25

func xp_needed()->int:return 5+level*2
func finish_game()->void:
 game_over=true;best=max(best,score);save_best();queue_redraw()
func restart()->void:
 player_pos=Vector2(360,640);hp=100.0;xp=0;level=1;score=0;kills=0;weapon_level=1;enemies.clear();projectiles.clear();gems.clear();spawn_timer=0.0;attack_timer=0.0;elapsed=0.0;game_over=false;queue_redraw()

func _unhandled_input(event:InputEvent)->void:
 if event is InputEventScreenDrag:player_pos=event.position
 elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):player_pos=event.position
 elif event is InputEventScreenTouch and event.pressed and game_over:restart()
 elif event is InputEventMouseButton and event.pressed and game_over:restart()
 elif event is InputEventKey and event.pressed and event.keycode==KEY_R:restart()

func _draw()->void:
 draw_rect(Rect2(0,0,W,H),Color("120b18"))
 draw_string(ThemeDB.fallback_font,Vector2(38,58),"REDLAM7 // VAMP",0,-1,34,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(38,98),"LV %d  XP %d/%d  WEAPON %d"%[level,xp,xp_needed(),weapon_level],0,-1,20,Color("cbb4d8"))
 draw_string(ThemeDB.fallback_font,Vector2(38,128),"SCORE %d  BEST %d  KILLS %d"%[score,best,kills],0,-1,18,Color("8fe7ff"))
 draw_rect(Rect2(38,145,300,15),Color("34243d"),true);draw_rect(Rect2(38,145,300.0*hp/100.0,15),Color("d34d6f"),true)
 for g in gems:draw_circle(g.pos,9 if g.value>1 else 7,Color("5de0ff"))
 for e in enemies:
  var c:=Color("c24f74") if e.elite else Color("7d2e68");draw_circle(e.pos,e.r,c);draw_circle(e.pos,max(4.0,e.r*.25),Color("ff738f"))
 for p in projectiles:draw_circle(p.pos,p.r,Color("f8f2ff"))
 draw_circle(player_pos,player_radius+6,Color(0,0,0,.35));draw_circle(player_pos,player_radius,Color("37b8d9"));draw_arc(player_pos,player_radius+3,0,TAU,48,Color("a8ecff"),3)
 if game_over:
  draw_rect(Rect2(105,485,510,230),Color(0.03,0.02,0.05,.95),true);draw_string(ThemeDB.fallback_font,Vector2(240,545),"VAMP DOWN",0,-1,36,Color.WHITE);draw_string(ThemeDB.fallback_font,Vector2(235,595),"SCORE %d"%score,0,-1,25,Color("7ee8ff"));draw_string(ThemeDB.fallback_font,Vector2(235,635),"KILLS %d   LV %d"%[kills,level],0,-1,21,Color("cbb4d8"));draw_string(ThemeDB.fallback_font,Vector2(190,680),"Tap or R to restart",0,-1,22,Color("cbb4d8"))

func save_best()->void:
 var c:=ConfigFile.new();c.set_value("score","best",best);c.save("user://vamp.cfg")
func load_best()->int:
 var c:=ConfigFile.new();return 0 if c.load("user://vamp.cfg")!=OK else int(c.get_value("score","best",0))
