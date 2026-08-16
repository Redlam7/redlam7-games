extends Node2D

const W := 720.0
const H := 1280.0
var hole_pos := Vector2(360, 720)
var hole_radius := 38.0
var objects: Array[Dictionary] = []
var score := 0
var time_left := 60.0
var game_over := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    spawn_world()
    queue_redraw()

func spawn_world() -> void:
    objects.clear()
    for i in range(42):
        var r := rng.randf_range(10.0, 34.0)
        objects.append({"pos": Vector2(rng.randf_range(55, 665), rng.randf_range(180, 1160)), "r": r})

func _process(delta: float) -> void:
    if game_over: return
    time_left = max(0.0, time_left - delta)
    if time_left <= 0.0:
        game_over = true
    var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if dir.length() > 0.0:
        hole_pos += dir * 330.0 * delta
        clamp_hole()
    absorb_objects()
    if objects.is_empty():
        spawn_world()
    queue_redraw()

func absorb_objects() -> void:
    for i in range(objects.size() - 1, -1, -1):
        var o = objects[i]
        if o.r <= hole_radius * 0.72 and hole_pos.distance_to(o.pos) < hole_radius - o.r * 0.15:
            score += int(o.r)
            hole_radius = min(105.0, hole_radius + o.r * 0.045)
            objects.remove_at(i)

func clamp_hole() -> void:
    hole_pos.x = clamp(hole_pos.x, 25.0 + hole_radius, W - 25.0 - hole_radius)
    hole_pos.y = clamp(hole_pos.y, 145.0 + hole_radius, H - 30.0 - hole_radius)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        hole_pos = event.position
        clamp_hole()
    elif event is InputEventScreenDrag:
        hole_pos = event.position
        clamp_hole()
    elif event is InputEventScreenTouch and event.pressed:
        if game_over: restart()
        else:
            hole_pos = event.position
            clamp_hole()
    elif event is InputEventMouseButton and event.pressed and game_over:
        restart()
    elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
        restart()

func restart() -> void:
    score = 0
    time_left = 60.0
    hole_radius = 38.0
    hole_pos = Vector2(360, 720)
    game_over = false
    spawn_world()

func _draw() -> void:
    draw_rect(Rect2(0, 0, W, H), Color("101721"))
    draw_string(ThemeDB.fallback_font, Vector2(38, 60), "REDLAM7 // HOLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(38, 103), "SCORE %d    TIME %02d" % [score, int(ceil(time_left))], HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("aab5cc"))
    for o in objects:
        var c := Color("4fb4d4") if o.r < 20 else Color("9d65d5") if o.r < 28 else Color("db7859")
        draw_circle(o.pos, o.r, c)
        draw_circle(o.pos - Vector2(o.r * .25, o.r * .25), max(2.0, o.r * .12), Color(1,1,1,.35))
    draw_circle(hole_pos + Vector2(0, 8), hole_radius + 6, Color(0,0,0,.28))
    draw_circle(hole_pos, hole_radius, Color("020407"))
    draw_arc(hole_pos, hole_radius, 0, TAU, 64, Color("37b9dc"), 4)
    if game_over:
        draw_rect(Rect2(105, 510, 510, 190), Color(0.03,0.04,0.07,.94), true)
        draw_string(ThemeDB.fallback_font, Vector2(220, 575), "TIME'S UP", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(255, 625), "SCORE %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("72d8f2"))
        draw_string(ThemeDB.fallback_font, Vector2(190, 670), "Tap or R to restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("aab5cc"))
