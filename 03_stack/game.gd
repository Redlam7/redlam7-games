extends Control
var blocks=[]
var moving=Rect2()
var dir:=1.0
var speed:=220.0
var score:=0
var best:=0
var over:=false
func _ready():
 best=load_best();reset()
func reset():
 blocks=[Rect2(210,1050,300,55)];score=0;speed=220;over=false;spawn();queue_redraw()
func spawn():
 var prev:Rect2=blocks[-1];moving=Rect2(20,prev.position.y-65,prev.size.x,55);dir=1.0
func _process(d):
 if over:return
 moving.position.x+=dir*speed*d
 if moving.position.x<20:moving.position.x=20;dir=1
 if moving.end.x>700:moving.position.x=700-moving.size.x;dir=-1
 queue_redraw()
func drop():
 if over:return
 var prev:Rect2=blocks[-1];var left=max(moving.position.x,prev.position.x);var right=min(moving.end.x,prev.end.x);var overlap=right-left
 if overlap<=8:
  over=true;best=max(best,score);save_best();queue_redraw();return
 var perfect=abs(moving.position.x-prev.position.x)<8
 var placed=Rect2(prev.position.x if perfect else left,moving.position.y,prev.size.x if perfect else overlap,55)
 blocks.append(placed);score+=2 if perfect else 1;speed=min(520.0,speed+10.0)
 if blocks.size()>12:
  for i in blocks.size():blocks[i].position.y+=65
 spawn();queue_redraw()
func _unhandled_input(e):
 if (e is InputEventKey and e.pressed and (e.keycode==KEY_SPACE or e.keycode==KEY_ENTER)) or (e is InputEventScreenTouch and e.pressed):
  if over:reset()
  else:drop()
func _draw():
 draw_rect(Rect2(Vector2.ZERO,size),Color("10131c"));draw_string(ThemeDB.fallback_font,Vector2(40,80),"REDLAM7 // STACK",0,-1,38,Color.WHITE);draw_string(ThemeDB.fallback_font,Vector2(40,130),"STACK %d   BEST %d"%[score,best],0,-1,24,Color("aab2c8"))
 for i in blocks.size():draw_rect(blocks[i],Color(0.18+min(i,10)*0.02,0.35,0.55))
 if not over:draw_rect(moving,Color("78b8df"))
 else:
  draw_string(ThemeDB.fallback_font,Vector2(220,520),"GAME OVER",0,-1,44,Color.WHITE);draw_string(ThemeDB.fallback_font,Vector2(170,580),"Tap / SPACE to restart",0,-1,24,Color("aab2c8"))
func save_best():
 var c=ConfigFile.new();c.set_value("score","best",best);c.save("user://stack.cfg")
func load_best():
 var c=ConfigFile.new();return 0 if c.load("user://stack.cfg")!=OK else int(c.get_value("score","best",0))
