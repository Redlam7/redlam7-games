extends Node2D

const WIDTH := 720.0
const FLOOR_Y := 1130.0
const LEFT := 70.0
const RIGHT := 650.0
const DROP_Y := 180.0
const DANGER_Y := 145.0
const RADII := [24.0,31.0,40.0,51.0,64.0,80.0,98.0,120.0]
const VALUES := [2,4,8,16,32,64,128,256]

var balls: Array[Dictionary] = []
var next_level := 0
var cursor_x := WIDTH / 2.0
var score := 0
var best := 0
var combo := 0
var combo_timer := 0.0
var danger_timer := 0.0
var game_over := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    best = load_best()
    restart()

func _process(delta: float) -> void:
    combo_timer = max(0.0,combo_timer-delta)
    if combo_timer <= 0.0: combo = 0
    if game_over:
        queue_redraw()
        return
    for b in balls:
        b.vel.y += 980.0 * delta
        b.pos += b.vel * delta
        var r: float = RADII[b.level]
        if b.pos.x-r < LEFT:
            b.pos.x=LEFT+r;b.vel.x*=-0.35
        if b.pos.x+r > RIGHT:
            b.pos.x=RIGHT-r;b.vel.x*=-0.35
        if b.pos.y+r > FLOOR_Y:
            b.pos.y=FLOOR_Y-r;b.vel.y*=-0.22;b.vel.x*=0.96
    solve_collisions()
    update_danger(delta)
    queue_redraw()

func solve_collisions() -> void:
    var i:=0
    while i<balls.size():
        var j:=i+1
        while j<balls.size():
            var a=balls[i];var b=balls[j]
            var delta:Vector2=b.pos-a.pos
            var dist:=delta.length()
            var min_dist:float=RADII[a.level]+RADII[b.level]
            if dist<min_dist and dist>0.001:
                if a.level==b.level and a.level<RADII.size()-1:
                    var p:Vector2=(a.pos+b.pos)*0.5
                    var level:int=a.level+1
                    balls.remove_at(j);balls.remove_at(i)
                    balls.append({"pos":p,"vel":Vector2(0,-140),"level":level})
                    combo = combo+1 if combo_timer>0.0 else 1
                    combo_timer=1.15
                    score += VALUES[level]*combo
                    if score>best:best=score;save_best()
                    i=-1;break
                var n:=delta/dist
                var push:=(min_dist-dist)*0.5
                a.pos-=n*push;b.pos+=n*push
                var rel:float=(b.vel-a.vel).dot(n)
                if rel<0.0:
                    var impulse:=n*rel*0.55
                    a.vel+=impulse;b.vel-=impulse
            j+=1
        i+=1

func drop_ball() -> void:
    if game_over:return
    var r:float=RADII[next_level]
    balls.append({"pos":Vector2(clamp(cursor_x,LEFT+r,RIGHT-r),DROP_Y),"vel":Vector2.ZERO,"level":next_level})
    next_level=rng.randi_range(0,2)

func update_danger(delta:float) -> void:
    var danger:=false
    for b in balls:
        if b.pos.y-RADII[b.level]<DANGER_Y and b.vel.length()<45.0:
            danger=true;break
    danger_timer = danger_timer+delta if danger else max(0.0,danger_timer-delta*2.5)
    if danger_timer>=1.6:
        game_over=true
        best=max(best,score);save_best()

func restart() -> void:
    balls.clear();score=0;combo=0;combo_timer=0.0;danger_timer=0.0;game_over=false
    next_level=rng.randi_range(0,2);cursor_x=WIDTH/2.0;queue_redraw()

func _unhandled_input(event:InputEvent) -> void:
    if event is InputEventMouseMotion:cursor_x=event.position.x
    elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
        cursor_x=event.position.x
        if game_over:restart()
        else:drop_ball()
    elif event is InputEventScreenDrag:cursor_x=event.position.x
    elif event is InputEventScreenTouch and event.pressed:
        cursor_x=event.position.x
        if game_over:restart()
        else:drop_ball()
    elif event is InputEventKey and event.pressed:
        if event.keycode==KEY_LEFT:cursor_x-=30.0
        elif event.keycode==KEY_RIGHT:cursor_x+=30.0
        elif event.keycode==KEY_SPACE:
            if game_over:restart()
            else:drop_ball()
        elif event.keycode==KEY_R:restart()

func _draw() -> void:
    draw_rect(Rect2(0,0,720,1280),Color("0e121b"))
    draw_string(ThemeDB.fallback_font,Vector2(45,65),"REDLAM7 // SUIKA",0,-1,34,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(45,105),"SCORE %d   BEST %d"%[score,best],0,-1,22,Color("aab2c8"))
    draw_line(Vector2(LEFT,DANGER_Y),Vector2(RIGHT,DANGER_Y),Color("7d3848") if danger_timer>0 else Color("30394c"),3)
    draw_line(Vector2(LEFT,125),Vector2(LEFT,FLOOR_Y),Color("46516a"),5);draw_line(Vector2(RIGHT,125),Vector2(RIGHT,FLOOR_Y),Color("46516a"),5);draw_line(Vector2(LEFT,FLOOR_Y),Vector2(RIGHT,FLOOR_Y),Color("46516a"),5)
    var nr:float=RADII[next_level]
    var px:=clamp(cursor_x,LEFT+nr,RIGHT-nr)
    draw_line(Vector2(px,DROP_Y+nr+8),Vector2(px,FLOOR_Y),Color(0.3,0.55,0.7,0.12),2)
    draw_circle(Vector2(px,DROP_Y),nr,ball_color(next_level))
    for b in balls:
        draw_circle(b.pos,RADII[b.level],ball_color(b.level))
        var text:=str(VALUES[b.level]);var fs:=18+b.level*2
        var ts:=ThemeDB.fallback_font.get_string_size(text,0,-1,fs)
        draw_string(ThemeDB.fallback_font,b.pos-Vector2(ts.x/2.0,-ts.y/3.0),text,0,-1,fs,Color.WHITE)
    if combo>=2 and combo_timer>0:
        draw_string(ThemeDB.fallback_font,Vector2(275,210),"COMBO x%d"%combo,0,-1,24,Color("8fd8ff"))
    if danger_timer>0:
        draw_string(ThemeDB.fallback_font,Vector2(250,155),"DANGER %.1f"%max(0.0,1.6-danger_timer),0,-1,20,Color("ff8090"))
    if game_over:
        draw_rect(Rect2(100,480,520,190),Color(0.04,0.05,0.08,0.94),true)
        draw_string(ThemeDB.fallback_font,Vector2(225,545),"GAME OVER",0,-1,38,Color.WHITE)
        draw_string(ThemeDB.fallback_font,Vector2(245,590),"SCORE %d"%score,0,-1,24,Color("8fd8ff"))
        draw_string(ThemeDB.fallback_font,Vector2(180,635),"Tap / SPACE / R",0,-1,24,Color("aab2c8"))

func ball_color(level:int)->Color:
    var palette:=[Color("2496c8"),Color("3475c5"),Color("635fc7"),Color("a64fc0"),Color("d04d89"),Color("d96a55"),Color("d89b43"),Color("c9c24c")]
    return palette[level]

func save_best()->void:
    var cfg:=ConfigFile.new();cfg.set_value("score","best",best);cfg.save("user://redlam7_suika.cfg")
func load_best()->int:
    var cfg:=ConfigFile.new()
    if cfg.load("user://redlam7_suika.cfg")==OK:return int(cfg.get_value("score","best",0))
    return 0
