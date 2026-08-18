extends Node2D

const W := 720.0
const H := 1280.0
const COLS := 5
const ROWS := 6
const CELL := 100.0
const ORIGIN := Vector2(110, 300)

var board: Array[int] = []
var selected := -1
var score := 0
var moves := 24
var target := 1200
var game_over := false
var won := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    new_board()
    queue_redraw()

func new_board() -> void:
    board.clear()
    for i in range(COLS * ROWS):
        board.append(rng.randi_range(0, 4))
    remove_initial_matches()

func remove_initial_matches() -> void:
    var guard := 0
    while not find_matches().is_empty() and guard < 100:
        for idx in find_matches(): board[idx] = rng.randi_range(0, 4)
        guard += 1

func index_at(pos: Vector2) -> int:
    var local := pos - ORIGIN
    if local.x < 0 or local.y < 0: return -1
    var c := int(local.x / CELL)
    var r := int(local.y / CELL)
    if c < 0 or c >= COLS or r < 0 or r >= ROWS: return -1
    return r * COLS + c

func adjacent(a: int, b: int) -> bool:
    if a < 0 or b < 0: return false
    var ar := a / COLS
    var ac := a % COLS
    var br := b / COLS
    var bc := b % COLS
    return abs(ar - br) + abs(ac - bc) == 1

func choose(idx: int) -> void:
    if game_over or idx < 0: return
    if selected < 0:
        selected = idx
    elif idx == selected:
        selected = -1
    elif adjacent(selected, idx):
        swap(selected, idx)
        var matches := find_matches()
        if matches.is_empty():
            swap(selected, idx)
        else:
            moves -= 1
            resolve_board(matches)
            if score >= target:
                won = true
                game_over = true
            elif moves <= 0:
                game_over = true
        selected = -1
    else:
        selected = idx
    queue_redraw()

func swap(a: int, b: int) -> void:
    var t := board[a]
    board[a] = board[b]
    board[b] = t

func find_matches() -> Array[int]:
    var found: Dictionary = {}
    for r in range(ROWS):
        var run := 1
        for c in range(1, COLS + 1):
            if c < COLS and board[r*COLS+c] == board[r*COLS+c-1]:
                run += 1
            else:
                if run >= 3:
                    for k in range(run): found[r*COLS+c-1-k] = true
                run = 1
    for c in range(COLS):
        var run := 1
        for r in range(1, ROWS + 1):
            if r < ROWS and board[r*COLS+c] == board[(r-1)*COLS+c]:
                run += 1
            else:
                if run >= 3:
                    for k in range(run): found[(r-1-k)*COLS+c] = true
                run = 1
    return found.keys()

func resolve_board(matches: Array[int]) -> void:
    while not matches.is_empty():
        score += matches.size() * 25
        for idx in matches: board[idx] = -1
        for c in range(COLS):
            var values: Array[int] = []
            for r in range(ROWS - 1, -1, -1):
                var v := board[r*COLS+c]
                if v >= 0: values.append(v)
            for r in range(ROWS - 1, -1, -1):
                var offset := ROWS - 1 - r
                board[r*COLS+c] = values[offset] if offset < values.size() else rng.randi_range(0,4)
        matches = find_matches()

func restart() -> void:
    score = 0
    moves = 24
    selected = -1
    game_over = false
    won = false
    new_board()
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if game_over: restart()
        else: choose(index_at(event.position))
    elif event is InputEventScreenTouch and event.pressed:
        if game_over: restart()
        else: choose(index_at(event.position))
    elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
        restart()

func gem_color(v: int) -> Color:
    var colors := [Color("e2b84f"), Color("b96ad9"), Color("55b7d9"), Color("e36c78"), Color("6bc486")]
    return colors[v]

func _draw() -> void:
    draw_rect(Rect2(0,0,W,H), Color("100c19"))
    draw_string(ThemeDB.fallback_font, Vector2(42,65), "REDLAM7 // ROYAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("f3df9a"))
    draw_string(ThemeDB.fallback_font, Vector2(42,112), "SCORE %d / %d    MOVES %d" % [score,target,moves], HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("c9bfd8"))
    draw_string(ThemeDB.fallback_font, Vector2(42,165), "Match 3+ royal gems", HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("8f84a5"))
    for r in range(ROWS):
        for c in range(COLS):
            var idx := r*COLS+c
            var rect := Rect2(ORIGIN + Vector2(c*CELL,r*CELL), Vector2(CELL-8,CELL-8))
            draw_rect(rect, Color("21182f"), true)
            var center := rect.get_center()
            draw_circle(center, 31, gem_color(board[idx]))
            draw_circle(center, 19, gem_color(board[idx]).lightened(.12))
            if idx == selected: draw_arc(center, 42,0,TAU,48,Color.WHITE,5)
    if game_over:
        draw_rect(Rect2(100,930,520,190),Color(0.04,0.025,0.07,.95),true)
        var title := "CROWN CLAIMED" if won else "OUT OF MOVES"
        draw_string(ThemeDB.fallback_font,Vector2(185,995),title,HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("f3df9a"))
        draw_string(ThemeDB.fallback_font,Vector2(205,1050),"Final score: %d" % score,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
        draw_string(ThemeDB.fallback_font,Vector2(205,1090),"Tap or R to restart",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("b9a9cc"))
