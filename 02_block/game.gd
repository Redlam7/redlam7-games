extends Control

const N := 10
var grid: Array = []
var score := 0
var best := 0
var cursor := Vector2i(4,4)
var shapes := [
 [Vector2i(0,0)],
 [Vector2i(0,0),Vector2i(1,0)],
 [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1)],
 [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],
 [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]
]
var shape: Array = []
var rng := RandomNumberGenerator.new()
var game_over := false
var combo := 0

func _ready() -> void:
 rng.randomize()
 best = load_best()
 reset()

func reset() -> void:
 grid = []
 for y in N:
  grid.append([0,0,0,0,0,0,0,0,0,0])
 score = 0
 combo = 0
 cursor = Vector2i(4,4)
 game_over = false
 next_shape()
 queue_redraw()

func next_shape() -> void:
 shape = shapes[rng.randi_range(0, shapes.size()-1)]
 if not any_valid_position():
  game_over = true
 queue_redraw()

func valid(p: Vector2i) -> bool:
 for o in shape:
  var q := p + o
  if q.x < 0 or q.y < 0 or q.x >= N or q.y >= N or grid[q.y][q.x] != 0:
   return false
 return true

func any_valid_position() -> bool:
 for y in N:
  for x in N:
   if valid(Vector2i(x,y)):
    return true
 return false

func place() -> void:
 if game_over or not valid(cursor):
  return
 for o in shape:
  var q := cursor + o
  grid[q.y][q.x] = 1
  score += 1
 var cleared := clear_lines()
 if cleared > 0:
  combo += 1
  score += cleared * 20 + max(0, combo - 1) * 10
 else:
  combo = 0
 if score > best:
  best = score
  save_best()
 next_shape()

func clear_lines() -> int:
 var rows: Array[int] = []
 var cols: Array[int] = []
 for y in N:
  if grid[y].all(func(v): return v == 1):
   rows.append(y)
 for x in N:
  var full := true
  for y in N:
   if grid[y][x] == 0:
    full = false
  if full:
   cols.append(x)
 for y in rows:
  for x in N:
   grid[y][x] = 0
 for x in cols:
  for y in N:
   grid[y][x] = 0
 return rows.size() + cols.size()

func _unhandled_input(e: InputEvent) -> void:
 if e is InputEventKey and e.pressed:
  if game_over:
   if e.keycode in [KEY_R, KEY_SPACE, KEY_ENTER]:
    reset()
   return
  match e.keycode:
   KEY_LEFT: cursor.x = max(0, cursor.x - 1)
   KEY_RIGHT: cursor.x = min(N-1, cursor.x + 1)
   KEY_UP: cursor.y = max(0, cursor.y - 1)
   KEY_DOWN: cursor.y = min(N-1, cursor.y + 1)
   KEY_SPACE, KEY_ENTER: place()
   KEY_R: reset()
  queue_redraw()
 elif e is InputEventScreenTouch and e.pressed:
  if game_over:
   reset()
   return
  var c := cell_at(e.position)
  if c.x >= 0:
   cursor = c
   place()
   queue_redraw()

func cell_at(p: Vector2) -> Vector2i:
 var origin := Vector2(60,250)
 var cell := 60.0
 var q := ((p-origin)/cell).floor()
 if q.x >= 0 and q.y >= 0 and q.x < N and q.y < N:
  return Vector2i(q)
 return Vector2i(-1,-1)

func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("10131c"))
 draw_string(ThemeDB.fallback_font,Vector2(40,80),"REDLAM7 // BLOCK",0,-1,38,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(40,130),"SCORE %d   BEST %d" % [score,best],0,-1,24,Color("aab2c8"))
 if combo > 1:
  draw_string(ThemeDB.fallback_font,Vector2(40,175),"COMBO x%d" % combo,0,-1,21,Color("7bdcf4"))
 var origin := Vector2(60,250)
 var cell := 60.0
 for y in N:
  for x in N:
   var r := Rect2(origin+Vector2(x,y)*cell,Vector2(cell-5,cell-5))
   draw_rect(r,Color("252c3d") if grid[y][x]==0 else Color("3976a8"))
 if not game_over:
  var preview_color := Color("6fa7d1") if valid(cursor) else Color("d45f69")
  for o in shape:
   var q := cursor+o
   if q.x >= 0 and q.y >= 0 and q.x < N and q.y < N:
    draw_rect(Rect2(origin+Vector2(q)*cell,Vector2(cell-5,cell-5)),preview_color,false,4)
 draw_string(ThemeDB.fallback_font,Vector2(40,900),"Arrows + SPACE / tap cell • R restart",0,-1,21,Color("747f99"))
 if game_over:
  draw_rect(Rect2(95,465,530,210),Color(0.04,0.05,0.08,0.94),true)
  draw_string(ThemeDB.fallback_font,Vector2(220,535),"NO MORE SPACE",0,-1,36,Color.WHITE)
  draw_string(ThemeDB.fallback_font,Vector2(255,585),"SCORE %d" % score,0,-1,26,Color("7bdcf4"))
  draw_string(ThemeDB.fallback_font,Vector2(190,630),"Tap / SPACE / R to restart",0,-1,20,Color("aab2c8"))

func save_best() -> void:
 var c := ConfigFile.new()
 c.set_value("score","best",best)
 c.save("user://block.cfg")

func load_best() -> int:
 var c := ConfigFile.new()
 return 0 if c.load("user://block.cfg") != OK else int(c.get_value("score","best",0))
