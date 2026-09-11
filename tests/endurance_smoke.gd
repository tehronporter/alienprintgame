extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	game._start_game()
	var pool_size_before: int = game.enemy_pool.size()
	for step in range(6000):
		game.survival_time = float(step) * 0.1
		game.director._process(0.1)
	var active_count := 0
	for enemy in game.enemy_pool:
		if enemy.active:
			active_count += 1
	if game.enemy_pool.size() != pool_size_before or active_count > 42:
		push_error("Endurance smoke test failed: pool grew or active cap was exceeded")
		quit(1)
		return
	# Newly arriving aliens keep scaling beyond the ten-minute population test.
	var target = game.enemy_pool[0]
	target.activate("standard", Vector3(0, 0.35, 0), 1)
	var first_health: int = target.health
	var first_speed: float = target.move_speed
	var first_size: float = target.visual_root.scale.y
	target.activate("standard", Vector3(0, 0.35, 0), 100)
	if target.health <= first_health or target.move_speed <= first_speed or target.visual_root.scale.y <= first_size:
		push_error("Endurance smoke failed: wave 100 did not grow stronger, faster, and larger")
		quit(1)
		return
	# A full arena must defer, not discard, an overdue overlord.
	game.director.elite_timer = -1.0
	for enemy in game.enemy_pool: enemy.deactivate()
	game.director._process(0.1)
	if game.enemy_pool[0].enemy_type != "elite" or not game.enemy_pool[0].active:
		push_error("Endurance smoke failed: overdue overlord did not spawn")
		quit(1)
		return
	await create_timer(0.1).timeout
	print("ENDURANCE_SMOKE_PASS simulated_seconds=600 pool=", pool_size_before, " active=", active_count)
	game.queue_free()
	await process_frame
	await process_frame
	quit(0)
