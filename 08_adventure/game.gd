extends Node2D

const W := 960.0
const H := 540.0
const GROUND_Y := 470.0
var player_pos := Vector2(120, GROUND_Y)
var player_vel := Vector2.ZERO
var speed := 220.0
var jump_power := 430.0
var gravity := 980.0
var coins := [Vector2(280,420),Vector2(430,380),Vector2(610,420),Vector2(780,350)]
var hazards := [Rect2(520,445,46,25),Rect2(700,445,46,25)]
var collected := 0
var checkpoint := Vector2(120,GROUND_Y)
var finished := false

func _process(delta: float) -> void:
    if finished: return
    var dir := Input.get_axis("ui_left","ui_right")
    player_vel.x = dir * speed
    if Input.is_action_just_pressed("ui_accept") and abs(player_pos.y-GROUND_Y) < 2.0:
        player_vel.y = -jump_power
    player_vel.y += gravity * delta
    player_pos += player_vel * delta
    if player_pos.y >= GROUND_Y:
        player_pos.y = GROUND_Y
        player_vel.y = 0
    player_pos.x = clamp(player_pos.x, 30.0, W-30.0)
    check_collectibles()
    check_hazards()
    if player_pos.x > 900:
        finished = true
    queue_redraw()

func check_collectibles() -> void:
    for i in range(coins.size()-1,-1,-1):
        if player_pos.distance_to(coins[i]) < 28:
            coins.remove_at(i)
            collected += 1
            if collected == 2:
                checkpoint = player_pos

func check_hazards() -> void:
    var p := Rect2(player_pos.x-14,player_pos.y-34,28,34)
    for h in hazards:
        if p.intersects(h):
            player_pos = checkpoint
            player_vel = Vector2.ZERO
            return

func restart() -> void:
    player_pos = Vector2(120,GROUND_Y)
    player_vel = Vector2.ZERO
    coins = [Vector2(280,420),Vector2(430,380),Vector2(610,420),Vector2(780,350)]
    collected = 0
    checkpoint = Vector2(120,GROUND_Y)
    finished = false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_R:
        restart()
    elif event is InputEventScreenTouch and event.pressed:
        if finished:
            restart()
        elif event.position.y < H*0.5 and abs(player_pos.y-GROUND_Y)<2.0:
            player_vel.y = -jump_power
    elif event is InputEventScreenDrag:
        player_vel.x = clamp(event.relative.x * 12.0,-speed,speed)

func _draw() -> void:
    draw_rect(Rect2(0,0,W,H),Color("0f1620"))
    draw_rect(Rect2(0,GROUND_Y,W,H-GROUND_Y),Color("263448"))
    draw_string(ThemeDB.fallback_font,Vector2(28,44),"REDLAM7 // ADVENTURE",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(28,78),"RELICS %d/4"%collected,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("9fc7d8"))
    draw_rect(Rect2(860,360,55,110),Color("3c596e"),true)
    draw_rect(Rect2(875,330,25,30),Color("69d2e7"),true)
    for c in coins:
        draw_circle(c,10,Color("e0bf56"))
    for h in hazards:
        draw_rect(h,Color("b34b4b"),true)
    draw_rect(Rect2(player_pos.x-14,player_pos.y-34,28,34),Color("55c0da"),true)
    draw_circle(player_pos+Vector2(0,-42),10,Color("d7e8ec"))
    if finished:
        draw_rect(Rect2(220,180,520,150),Color(0.03,0.04,0.07,.95),true)
        draw_string(ThemeDB.fallback_font,Vector2(350,235),"LEVEL CLEAR",HORIZONTAL_ALIGNMENT_LEFT,-1,38,Color.WHITE)
        draw_string(ThemeDB.fallback_font,Vector2(330,285),"Relics: %d / 4"%collected,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("71d6ee"))
