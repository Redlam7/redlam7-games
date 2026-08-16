extends Node2D

const W := 720.0
const H := 1280.0
var paddle := Rect2(270, 1130, 180, 24)
var ball_pos := Vector2(360, 1050)
var ball_vel := Vector2(290, -390)
var radius := 14.0
var bricks: Array[Rect2] = []
var score := 0
var lives := 3
var game_over := false

func _ready() -> void:
    make_level()
    queue_redraw()

func make_level() -> void:
    bricks.clear()
    for row in range(7):
        for col in range(8):
            bricks.append(Rect2(42 + col * 80, 190 + row * 48, 68, 32))

func _process(delta: float) -> void:
    if game_over: return
    ball_pos += ball_vel * delta
    if ball_pos.x < radius or ball_pos.x > W - radius:
        ball_vel.x *= -1
        ball_pos.x = clamp(ball_pos.x, radius, W - radius)
    if ball_pos.y < 130 + radius:
        ball_vel.y = abs(ball_vel.y)
    if ball_vel.y > 0 and circle_rect(ball_pos, radius, paddle):
        ball_pos.y = paddle.position.y - radius
        var offset := (ball_pos.x - paddle.get_center().x) / (paddle.size.x * 0.5)
        ball_vel = Vector2(offset * 430.0, -abs(ball_vel.y)).normalized() * max(ball_vel.length(), 480.0)
    for i in range(bricks.size() - 1, -1, -1):
        if circle_rect(ball_pos, radius, bricks[i]):
            bricks.remove_at(i)
            ball_vel.y *= -1
            score += 10
            break
    if ball_pos.y > H + 30:
        lives -= 1
        if lives <= 0:
            game_over = true
        else:
            reset_ball()
    if bricks.is_empty():
        make_level()
        ball_vel *= 1.08
        reset_ball()
    queue_redraw()

func circle_rect(p: Vector2, r: float, rect: Rect2) -> bool:
    var closest := Vector2(clamp(p.x, rect.position.x, rect.end.x), clamp(p.y, rect.position.y, rect.end.y))
    return p.distance_squared_to(closest) <= r * r

func reset_ball() -> void:
    ball_pos = Vector2(paddle.get_center().x, 1050)
    ball_vel = Vector2(290 if randi() % 2 == 0 else -290, -390)

func restart() -> void:
    score = 0
    lives = 3
    game_over = false
    paddle.position.x = 270
    make_level()
    reset_ball()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        paddle.position.x = clamp(event.position.x - paddle.size.x / 2.0, 20.0, W - 20.0 - paddle.size.x)
    elif event is InputEventScreenDrag:
        paddle.position.x = clamp(event.position.x - paddle.size.x / 2.0, 20.0, W - 20.0 - paddle.size.x)
    elif event is InputEventScreenTouch and event.pressed:
        if game_over: restart()
        else: paddle.position.x = clamp(event.position.x - paddle.size.x / 2.0, 20.0, W - 20.0 - paddle.size.x)
    elif event is InputEventMouseButton and event.pressed and game_over:
        restart()
    elif event is InputEventKey and event.pressed:
        if event.keycode == KEY_LEFT: paddle.position.x = max(20.0, paddle.position.x - 45.0)
        elif event.keycode == KEY_RIGHT: paddle.position.x = min(W - 20.0 - paddle.size.x, paddle.position.x + 45.0)
        elif event.keycode == KEY_R: restart()

func _draw() -> void:
    draw_rect(Rect2(0, 0, W, H), Color("0c111b"))
    draw_string(ThemeDB.fallback_font, Vector2(38, 62), "REDLAM7 // BRICK", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(38, 105), "SCORE %d    LIVES %d" % [score, lives], HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("aab5cc"))
    for i in range(bricks.size()):
        var hue := float((i / 8) % 7) / 8.0 + 0.48
        draw_rect(bricks[i], Color.from_hsv(fmod(hue, 1.0), 0.62, 0.88), true)
    draw_rect(paddle, Color("43b9dc"), true)
    draw_circle(ball_pos, radius, Color.WHITE)
    if game_over:
        draw_rect(Rect2(110, 520, 500, 170), Color(0.03, 0.04, 0.07, 0.94), true)
        draw_string(ThemeDB.fallback_font, Vector2(235, 585), "GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(205, 635), "Tap or R to restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("83d9f2"))
