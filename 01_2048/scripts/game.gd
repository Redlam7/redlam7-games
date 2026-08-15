extends Control

const SIZE := 4
var board: Array = []
var score := 0
var best := 0
var touch_start := Vector2.ZERO
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    best = int(load_value("best", 0))
    new_game()
    queue_redraw()

func new_game() -> void:
    board.clear()
    for y in SIZE:
        board.append([0, 0, 0, 0])
    score = 0
    spawn_tile()
    spawn_tile()
    queue_redraw()

func spawn_tile() -> void:
    var empty: Array[Vector2i] = []
    for y in SIZE:
        for x in SIZE:
            if board[y][x] == 0:
                empty.append(Vector2i(x, y))
    if empty.is_empty(): return
    var p := empty[rng.randi_range(0, empty.size() - 1)]
    board[p.y][p.x] = 4 if rng.randf() < 0.1 else 2

func compress(line: Array) -> Array:
    var values := line.filter(func(v): return v != 0)
    var result: Array = []
    var i := 0
    while i < values.size():
        if i + 1 < values.size() and values[i] == values[i + 1]:
            var merged: int = values[i] * 2
            result.append(merged)
            score += merged
            i += 2
        else:
            result.append(values[i])
            i += 1
    while result.size() < SIZE: result.append(0)
    return result

func move(dir: Vector2i) -> void:
    var old := str(board)
    if dir.x != 0:
        for y in SIZE:
            var line: Array = board[y].duplicate()
            if dir.x > 0: line.reverse()
            line = compress(line)
            if dir.x > 0: line.reverse()
            board[y] = line
    else:
        for x in SIZE:
            var line: Array = []
            for y in SIZE: line.append(board[y][x])
            if dir.y > 0: line.reverse()
            line = compress(line)
            if dir.y > 0: line.reverse()
            for y in SIZE: board[y][x] = line[y]
    if str(board) != old:
        spawn_tile()
        if score > best:
            best = score
            save_value("best", best)
        queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_LEFT, KEY_A: move(Vector2i.LEFT)
            KEY_RIGHT, KEY_D: move(Vector2i.RIGHT)
            KEY_UP, KEY_W: move(Vector2i.UP)
            KEY_DOWN, KEY_S: move(Vector2i.DOWN)
            KEY_R: new_game()
    elif event is InputEventScreenTouch:
        if event.pressed: touch_start = event.position
        else:
            var delta := event.position - touch_start
            if delta.length() > 40.0:
                if abs(delta.x) > abs(delta.y): move(Vector2i.RIGHT if delta.x > 0 else Vector2i.LEFT)
                else: move(Vector2i.DOWN if delta.y > 0 else Vector2i.UP)

func _draw() -> void:
    var w := size.x
    draw_rect(Rect2(Vector2.ZERO, size), Color("10131c"))
    draw_string(ThemeDB.fallback_font, Vector2(40, 90), "REDLAM7 // 2048", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color("f4f4f6"))
    draw_string(ThemeDB.fallback_font, Vector2(40, 140), "SCORE %d    BEST %d" % [score, best], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("aab2c8"))
    var gap := 12.0
    var grid_w := min(w - 80.0, 640.0)
    var cell := (grid_w - gap * 5.0) / 4.0
    var origin := Vector2((w - grid_w) / 2.0, 230.0)
    draw_rect(Rect2(origin, Vector2(grid_w, grid_w)), Color("1b2130"), true)
    for y in SIZE:
        for x in SIZE:
            var rect := Rect2(origin + Vector2(gap + x * (cell + gap), gap + y * (cell + gap)), Vector2(cell, cell))
            var value: int = board[y][x]
            var intensity := clamp(log(float(max(value, 2))) / log(2048.0), 0.08, 1.0)
            draw_rect(rect, Color(0.12 + intensity * 0.18, 0.15 + intensity * 0.25, 0.22 + intensity * 0.38), true)
            if value > 0:
                var text := str(value)
                var font_size := 40 if value < 1000 else 30
                var text_size := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
                draw_string(ThemeDB.fallback_font, rect.position + (rect.size - text_size) / 2.0 + Vector2(0, text_size.y * 0.78), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(40, origin.y + grid_w + 70), "Swipe / arrows • R = restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("747f99"))

func save_value(key: String, value: Variant) -> void:
    var cfg := ConfigFile.new()
    cfg.load("user://redlam7_2048.cfg")
    cfg.set_value("scores", key, value)
    cfg.save("user://redlam7_2048.cfg")

func load_value(key: String, fallback: Variant) -> Variant:
    var cfg := ConfigFile.new()
    if cfg.load("user://redlam7_2048.cfg") != OK: return fallback
    return cfg.get_value("scores", key, fallback)
