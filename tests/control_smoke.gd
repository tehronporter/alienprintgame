extends SceneTree

func _init() -> void:
	call_deferred("run")

func touch(controls: Node, id: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = at
	event.pressed = pressed
	controls._input(event)

func drag(controls: Node, id: int, at: Vector2, delta: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = at
	event.relative = delta
	controls._input(event)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	assert(not InputMap.action_has_event("fire", key), "Firing should use the pointing hand")
	assert(InputMap.action_has_event("jump", key), "Space is an optional jump shortcut")
	key.physical_keycode = KEY_UP
	assert(InputMap.action_has_event("move_forward", key), "Arrow keys must move")
	game._start_game()
	game.director.set_process(false)
	for enemy in game.enemy_pool: enemy.deactivate()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	assert(InputMap.action_has_event("fire", click), "Trackpad click must fire")
	var desktop_ammo: int = game.player.ammo
	Input.parse_input_event(click)
	for frame in range(24): await physics_frame
	assert(game.player.ammo <= desktop_ammo - 2, "Holding click must repeatedly fire")
	click.pressed = false
	Input.parse_input_event(click)
	var released_ammo: int = game.player.ammo
	for frame in range(12): await physics_frame
	assert(game.player.ammo == released_ammo, "Release must stop firing")
	game.mobile_controls_visible = true
	var controls = game.hud.get_node("Control/MobileControls")
	controls.visible = true
	controls._update_button_rects()
	touch(controls, 0, Vector2(130, 500), true)
	drag(controls, 0, Vector2(130, 390), Vector2(0, -110))
	var fire_at: Vector2 = controls.fire_rect.get_center()
	touch(controls, 1, fire_at, true)
	drag(controls, 1, fire_at + Vector2(35, -10), Vector2(35, -10))
	assert(game.mobile_fire and game.mobile_look_delta.x > 0, "Fire thumb must also aim")
	controls._process(0.016)
	assert(game.mobile_move_vector.y < -0.9 and game.mobile_sprint, "Left thumb must move and sprint independently")
	var ammo_before: int = game.player.ammo
	for frame in range(4): await physics_frame
	assert(game.player.ammo < ammo_before and game.player.yaw < 0, "Touch input must fire and turn player")
	touch(controls, 1, fire_at, false)
	assert(not game.mobile_fire, "Releasing fire must stop shots")
	touch(controls, 2, controls.pause_rect.get_center(), true)
	assert(game.paused and controls.left_touch_id == -1 and game.mobile_move_vector == Vector2.ZERO, "Pause must clear held touches")
	touch(controls, 3, Vector2(500, 300), true)
	assert(not game.paused, "Touch resumes")
	game.player.shield = 50
	game.player.shield_recovery = 6.1
	await physics_frame
	await physics_frame
	assert(game.player.shield > 50, "Shield must recover outside combat")
	print("CONTROL_SMOKE_PASS arrows_hold_click=1 multitouch=1 fire_drag=1 pause_reset=1 shield_recovery=1")
	game.queue_free()
	await process_frame
	quit()
