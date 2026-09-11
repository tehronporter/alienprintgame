extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game._start_game()
	game.player.switch_weapon(1)
	if game.player.current_weapon != 1 or game.player.get_weapon_name() != "MARKER SCATTERGUN":
		push_error("Gameplay systems smoke failed: weapon switching")
		quit(1)
		return
	var damage_before: float = game.player.damage_multiplier
	game.player.apply_upgrade("damage")
	if game.player.damage_multiplier <= damage_before:
		push_error("Gameplay systems smoke failed: upgrade application")
		quit(1)
		return
	game.fire_enemy_projectile(Vector3(0, 1, 10), Vector3(0, 1, 0), 5)
	var projectile_active := false
	for projectile in game.projectile_pool:
		if projectile.active:
			projectile_active = true
			break
	if not projectile_active:
		push_error("Gameplay systems smoke failed: projectile pool")
		quit(1)
		return
	var reserve_before: int = game.player.reserve_ammo
	game.player.apply_pickup("ammo")
	if game.player.reserve_ammo <= reserve_before:
		push_error("Gameplay systems smoke failed: pickup reward")
		quit(1)
		return
	game._show_upgrade_choice()
	game.select_upgrade(0)
	if game.upgrade_pending or game.paused:
		push_error("Gameplay systems smoke failed: field mod flow")
		quit(1)
		return
	for enemy in game.enemy_pool: enemy.deactivate()
	game.director.set_process(false)
	game.player.position = Vector3(0, 0, 18)
	Input.action_press("move_forward")
	Input.action_press("sprint")
	for frame in range(12): await physics_frame
	if not game.player.is_sprinting or game.player.position.z >= 18.0:
		push_error("Gameplay systems smoke failed: forward sprint")
		quit(1)
		return
	Input.action_release("sprint")
	Input.action_release("move_forward")
	Input.action_press("aim")
	for frame in range(3): await physics_frame
	if not game.player.is_aiming:
		push_error("Gameplay systems smoke failed: aim input")
		quit(1)
		return
	Input.action_release("aim")
	print("GAMEPLAY_SYSTEMS_SMOKE_PASS weapons=3 projectiles=", game.projectile_pool.size(), " pickups=", game.pickup_pool.size())
	await create_timer(0.7).timeout
	game.queue_free()
	await process_frame
	quit(0)
