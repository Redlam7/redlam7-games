extends Control

var blocks: Array[Rect2] = []
var moving := Rect2()
var dir := 1.0
var speed := 220.0
var score := 0
var best := 0
var combo := 0
var perfects := 0
var over := false
var flash := 0.0

func _ready() -> void:
    best = load_best()
    reset()

func reset() -> void:
    blocks = [Rect2(210,1050,300,55)]
    score = 0
    combo = 0
    perfects = 0
    speed = 220.0
    over = false
    flash = 0.0
    spawn()
    queue_redraw()

func spawn() -> void:
    var prev: Rect2 = blocks[-1]
    moving = Rect2(20, prev.position.y - 65, prev.size.x, 55)
    dir = 1.0

func _process(delta: float) -> void:
    flash = max(0.0, flash - delta)
    if over:
        queue_redraw()
        return
    moving.position.x += dir * speed * delta
    if moving.position.x < 20:
        moving.position.x = 20
        dir = 1
    if moving.end.x > 700:
        moving.position.x = 700 - moving.size.x
        dir = -1
    queue_redraw()

func drop() -> void:
    if over: return
    var prev: Rect2 = blocks[-1]
    var left := max(moving.position.x, prev.position.x)
    var right := min(moving.end.x, prev.end.x)
    var overlap := right - left
    if overlap <= 8:
        finish_game()
        return
    var tolerance := max(5.0, min(12.0, prev.size.x * 0.035))
    var perfect := abs(moving.position.x - prev.position.x) <= tolerance
    var placed: Rect2
    if perfect:
        placed = Rect2(prev.position.x, moving.position.y, prev.size.x, 55)
        combo += 1
        perfects += 1
        score += 2 + min(combo, 5)
        flash = 0.22
    else:
        placed = Rect2(left, moving.position.y, overlap, 55)
        combo = 0
        score += 1
    blocks.append(placed)
    best = max(best, score)
    speed = min(570.0, speed + 9.0 + min(score, 80) * 0.08)
    if blocks.size() > 12:
        for i in blocks.size(): blocks[i].position.y += 65
    spawn()
    queue_redraw()

func finish_game() -> void:
    over = true
    best = max(best, score)
    save_best()
    queue_redraw()

func _unhandled_input(e: InputEvent) -> void:
    if e is InputEventKey and e.pressed:
        if e.keycode == KEY_R:
            reset()
        elif e.keycode == KEY_SPACE or e.keycode == KEY_ENTER:
            if over: reset()
            else: drop()
    elif e is InputEventScreenTouch and e.pressed:
        if over: reset()
        else: drop()
    elif e is InputEventMouseButton and e.pressed:
        if over: reset()
        else: drop()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,size), Color("10131c"))
    if flash > 0.0:
        draw_rect(Rect2(Vector2.ZERO,size), Color(0.35,0.75,1.0,flash * 0.35))
    draw_string(ThemeDB.fallback_font,Vector2(40,80),"REDLAM7 // STACK",0,-1,38,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(40,130),"STACK %d   BEST %d" % [score,best],0,-1,24,Color("aab2c8"))
    draw_string(ThemeDB.fallback_font,Vector2(40,170),"PERFECT %d   COMBO x%d" % [perfects,combo],0,-1,20,Color("78b8df"))
    for i in blocks.size():
        var glow := min(i,10) * 0.02
        draw_rect(blocks[i], Color(0.18+glow,0.35+glow*0.4,0.55+glow*0.7))
    if not over:
        draw_rect(moving, Color("78b8df"))
        if combo >= 2:
            draw_string(ThemeDB.fallback_font,Vector2(250,230),"PERFECT STREAK!",0,-1,22,Color("bcecff"))
    else:
        draw_rect(Rect2(125,455,470,190),Color(0.04,0.055,0.09,.94),true)
        draw_string(ThemeDB.fallback_font,Vector2(220,520),"GAME OVER",0,-1,44,Color.WHITE)
        draw_string(ThemeDB.fallback_font,Vector2(235,565),"SCORE %d" % score,0,-1,25,Color("78b8df"))
        draw_string(ThemeDB.fallback_font,Vector2(170,610),"Tap / SPACE to restart",0,-1,24,Color("aab2c8"))

func save_best() -> void:
    var c := ConfigFile.new()
    c.set_value("score","best",best)
    c.save("user://stack.cfg")

func load_best() -> int:
    var c := ConfigFile.new()
    return 0 if c.load("user://stack.cfg") != OK else int(c.get_value("score","best",0))
