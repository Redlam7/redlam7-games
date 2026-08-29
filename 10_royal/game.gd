extends Node2D

const W:=720.0
const H:=1280.0
const COLS:=5
const ROWS:=6
const CELL:=100.0
const ORIGIN:=Vector2(110,300)
var board:Array[int]=[]
var selected:=-1
var score:=0
var best:=0
var moves:=24
var target:=1200
var stage:=1
var combo:=0
var last_cascade:=0
var crowns:=0
var reshuffles:=0
var game_over:=false
var won:=false
var rng:=RandomNumberGenerator.new()

func _ready()->void:
 rng.randomize();best=load_best();restart()

func new_board()->void:
 board.clear()
 for i in range(COLS*ROWS):board.append(rng.randi_range(0,4))
 remove_initial_matches()
 ensure_playable()

func remove_initial_matches()->void:
 var guard:=0
 while not find_matches().is_empty() and guard<100:
  for idx in find_matches():board[idx]=rng.randi_range(0,4)
  guard+=1

func index_at(pos:Vector2)->int:
 var local:=pos-ORIGIN
 if local.x<0 or local.y<0:return -1
 var c:=int(local.x/CELL);var r:=int(local.y/CELL)
 if c<0 or c>=COLS or r<0 or r>=ROWS:return -1
 return r*COLS+c

func adjacent(a:int,b:int)->bool:
 if a<0 or b<0:return false
 return abs(a/COLS-b/COLS)+abs(a%COLS-b%COLS)==1

func choose(idx:int)->void:
 if game_over or idx<0:return
 if selected<0:selected=idx
 elif idx==selected:selected=-1
 elif adjacent(selected,idx):
  swap(selected,idx);var matches:=find_matches()
  if matches.is_empty():swap(selected,idx);combo=0
  else:
   moves-=1;resolve_board(matches);ensure_playable()
   if score>=target:
    won=true;game_over=true;best=max(best,score);save_best()
   elif moves<=0:
    game_over=true;best=max(best,score);save_best()
  selected=-1
 else:selected=idx
 queue_redraw()

func swap(a:int,b:int)->void:
 var t:=board[a];board[a]=board[b];board[b]=t

func find_matches()->Array[int]:
 var found:Dictionary={}
 for r in range(ROWS):
  var run:=1
  for c in range(1,COLS+1):
   if c<COLS and board[r*COLS+c]==board[r*COLS+c-1]:run+=1
   else:
    if run>=3:
     for k in range(run):found[r*COLS+c-1-k]=true
    run=1
 for c in range(COLS):
  var run:=1
  for r in range(1,ROWS+1):
   if r<ROWS and board[r*COLS+c]==board[(r-1)*COLS+c]:run+=1
   else:
    if run>=3:
     for k in range(run):found[(r-1-k)*COLS+c]=true
    run=1
 return found.keys()

func has_valid_move()->bool:
 for r in range(ROWS):
  for c in range(COLS):
   var a:=r*COLS+c
   if c+1<COLS:
    var b:=a+1;swap(a,b);var ok:=not find_matches().is_empty();swap(a,b)
    if ok:return true
   if r+1<ROWS:
    var b:=a+COLS;swap(a,b);var ok:=not find_matches().is_empty();swap(a,b)
    if ok:return true
 return false

func ensure_playable()->void:
 var guard:=0
 while not has_valid_move() and guard<50:
  board.shuffle();remove_initial_matches();guard+=1
  reshuffles+=1

func resolve_board(matches:Array[int])->void:
 var cascade:=1
 last_cascade=0
 while not matches.is_empty():
  last_cascade=cascade;combo=max(combo,cascade)
  score+=matches.size()*25*cascade
  if matches.size()>=4:
   score+=50*matches.size();crowns+=1
   if crowns%3==0:moves+=1
  if cascade>=3:
   crowns+=1
   if crowns%3==0:moves+=1
  for idx in matches:board[idx]=-1
  for c in range(COLS):
   var values:Array[int]=[]
   for r in range(ROWS-1,-1,-1):
    var v:=board[r*COLS+c]
    if v>=0:values.append(v)
   for r in range(ROWS-1,-1,-1):
    var off:=ROWS-1-r;board[r*COLS+c]=values[off] if off<values.size() else rng.randi_range(0,4)
  cascade+=1;matches=find_matches()
 best=max(best,score)

func next_stage()->void:
 stage+=1;target+=800+stage*250;moves=22+min(stage,5);selected=-1;combo=0;last_cascade=0;game_over=false;won=false;new_board();queue_redraw()

func restart()->void:
 score=0;moves=24;target=1200;stage=1;selected=-1;combo=0;last_cascade=0;crowns=0;reshuffles=0;game_over=false;won=false;new_board();queue_redraw()

func _unhandled_input(event:InputEvent)->void:
 if event is InputEventMouseButton and event.pressed:
  if game_over:
   if won:next_stage()
   else:restart()
  else:choose(index_at(event.position))
 elif event is InputEventScreenTouch and event.pressed:
  if game_over:
   if won:next_stage()
   else:restart()
  else:choose(index_at(event.position))
 elif event is InputEventKey and event.pressed:
  if event.keycode==KEY_R:restart()
  elif event.keycode==KEY_ENTER and game_over and won:next_stage()

func gem_color(v:int)->Color:
 var colors:=[Color("e2b84f"),Color("b96ad9"),Color("55b7d9"),Color("e36c78"),Color("6bc486")];return colors[v]

func _draw()->void:
 draw_rect(Rect2(0,0,W,H),Color("100c19"))
 draw_string(ThemeDB.fallback_font,Vector2(42,65),"REDLAM7 // ROYAL",0,-1,34,Color("f3df9a"))
 draw_string(ThemeDB.fallback_font,Vector2(42,108),"STAGE %d   SCORE %d / %d"%[stage,score,target],0,-1,21,Color("c9bfd8"))
 draw_string(ThemeDB.fallback_font,Vector2(42,145),"MOVES %d   BEST %d   CROWNS %d"%[moves,best,crowns],0,-1,18,Color("8f84a5"))
 draw_string(ThemeDB.fallback_font,Vector2(42,180),"Every 3 crowns: +1 move   RESHUFFLES %d"%reshuffles,0,-1,17,Color("b9a9cc"))
 if last_cascade>=2:draw_string(ThemeDB.fallback_font,Vector2(265,220),"ROYAL CASCADE x%d"%last_cascade,0,-1,20,Color("f3df9a"))
 for r in range(ROWS):
  for c in range(COLS):
   var idx:=r*COLS+c;var rect:=Rect2(ORIGIN+Vector2(c*CELL,r*CELL),Vector2(CELL-8,CELL-8));draw_rect(rect,Color("21182f"),true);var center:=rect.get_center();draw_circle(center,31,gem_color(board[idx]));draw_circle(center,19,gem_color(board[idx]).lightened(.12));
   if idx==selected:draw_arc(center,42,0,TAU,48,Color.WHITE,5)
 if game_over:
  draw_rect(Rect2(100,930,520,205),Color(0.04,0.025,0.07,.95),true);var title:="CROWN CLAIMED" if won else "OUT OF MOVES";draw_string(ThemeDB.fallback_font,Vector2(185,990),title,0,-1,34,Color("f3df9a"));draw_string(ThemeDB.fallback_font,Vector2(205,1040),"Score %d   Best %d"%[score,best],0,-1,22,Color.WHITE);var hint:="Tap / ENTER: next stage" if won else "Tap / R: restart";draw_string(ThemeDB.fallback_font,Vector2(195,1090),hint,0,-1,20,Color("b9a9cc"))

func save_best()->void:
 var c:=ConfigFile.new();c.set_value("score","best",best);c.save("user://royal.cfg")
func load_best()->int:
 var c:=ConfigFile.new();return 0 if c.load("user://royal.cfg")!=OK else int(c.get_value("score","best",0))
