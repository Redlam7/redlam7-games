extends Node2D

const W := 720.0
const H := 1280.0
const LANES := [220.0, 360.0, 500.0]
const GROUND_Y := 1030.0

var lane := 1
var player_y := GROUND_Y
var vertical_speed := 0.0
var slide_timer := 0.0
var speed := 420.0
var distance := 0.0
var score := 0
var obstacles: Array[Dictionary] = []
var spawn_timer := 0.8
var rng := RandomNumberGenerator.new()
var game_over := false
var touch_start := Vector2.ZERO

func _ready() -> void:
    rng.randomize()
    queue_redraw()

func _process(delta: float) -> void:
    if game_over: return
    speed = min(820.0, speed + 6.0 * delta)
    distance += speed * delta * 0.02
    score = int(distance)
    if player_y < GROUND_Y or vertical_speed != 0.0:
        vertical_speed += 1650.0 * delta
        player_y += vertical_speed * delta
        if player_y >= GROUND_Y:
            player_y = GROUND_Y
            vertical_speed = 0.0
    if slide_timer > 0.0:
        slide_timer -= delta
    spawn_timer -= delta
    if spawn_timer <= 0.0:
        spawn_obstacle()
        spawn_timer = rng.randf_range(0.8, 1.35) * clamp(520.0 / speed, 0.62, 1.0)
    for i in range(obstacles.size() - 1, -1, -1):
        obstacles[i].y += speed * delta
        if obstacles[i].y > H + 120:
            obstacles.remove_at(i)
            continue
        if collides(obstacles[i]):
            game_over = true
            break
    queue_redraw()

func spawn_obstacle() -> void:
    var kind := rng.randi_range(0, 2) # 0 normal, 1 jump, 2 slide
    obstacles.append({"lane": rng.randi_range(0, 2), "y": 150.0, "kind": kind})

func collides(o: Dictionary) -> bool:
    if o.lane != lane: return false
    if abs(o.y - GROUND_Y) > 55.0: return false
    if o.kind == 1 and player_y < GROUND_Y - 45.0: return false
    if o.kind == 2 and slide_timer > 0.0: return false
    return true

func move_left() -> void:
    lane = max(0, lane - 1)

func move_right() -> void:
    lane = min(2, lane + 1)

func jump() -> void:
    if player_y >= GROUND_Y and slide_timer <= 0.0:
        vertical_speed = -720.0

func slide() -> void:
    if player_y >= GROUND_Y:
        slide_timer = 0.55

func restart() -> void:
    lane = 1
    player_y = GROUND_Y
    vertical_speed = 0.0
    slide_timer = 0.0
    speed = 420.0
    distance = 0.0
    score = 0
    obstacles.clear()
    spawn_timer = 0.8
    game_over = false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_LEFT, KEY_A: move_left()
            KEY_RIGHT, KEY_D: move_right()
            KEY_UP, KEY_W, KEY_SPACE: jump()
            KEY_DOWN, KEY_S: slide()
            KEY_R: restart()
    elif event is InputEventScreenTouch:
        if event.pressed:
            touch_start = event.position
            if game_over: restart()
        else:
            var d := event.position - touch_start
            if d.length() > 45.0:
                if abs(d.x) > abs(d.y):
                    if d.x > 0: move_right()
                    else: move_left()
                else:
                    if d.y < 0: jump()
                    else: slide()
    elif event is InputEventMouseButton and event.pressed and game_over:
        restart()

func _draw() -> void:
    draw_rect(Rect2(0, 0, W, H), Color("0b1118"))
    draw_string(ThemeDB.fallback_font, Vector2(38, 58), "REDLAM7 // SUBWAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(38, 100), "DIST %04d   SPEED %03d" % [score, int(speed)], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("aab5cc"))

    # track perspective
    draw_polygon(PackedVector2Array([Vector2(115, H), Vector2(605, H), Vector2(470, 180), Vector2(250, 180)]), PackedColorArray([Color("182331")]))
    for x in LANES:
        draw_line(Vector2(x, H), Vector2(360 + (x - 360) * 0.28, 180), Color("34485c"), 5)
    for y in range(240, 1200, 120):
        var t := float(y - 180) / float(H - 180)
        var half := lerp(120.0, 260.0, t)
        draw_line(Vector2(360 - half, y), Vector2(360 + half, y), Color("263848"), 2)

    for o in obstacles:
        var x: float = LANES[o.lane]
        var y: float = o.y
        if o.kind == 0:
            draw_rect(Rect2(x - 38, y - 75, 76, 75), Color("d15d55"), true)
        elif o.kind == 1:
            draw_rect(Rect2(x - 46, y - 36, 92, 36), Color("d08b4b"), true)
        else:
            draw_rect(Rect2(x - 50, y - 110, 100, 34), Color("7f65cf"), true)

    var px := LANES[lane]
    var body_h := 42.0 if slide_timer > 0.0 else 88.0
    draw_rect(Rect2(px - 28, player_y - body_h, 56, body_h), Color("43b9dc"), true)
    draw_circle(Vector2(px, player_y - body_h - 18), 18, Color("e6f7ff"))

    if game_over:
        draw_rect(Rect2(100, 500, 520, 200), Color(0.03, 0.04, 0.07, 0.94), true)
        draw_string(ThemeDB.fallback_font, Vector2(225, 565), "RUN OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(230, 615), "DIST %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("79d9f1"))
        draw_string(ThemeDB.fallback_font, Vector2(185, 665), "Tap or R to restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("aab5cc"))
