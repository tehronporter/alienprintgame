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
	print("ENDURANCE_SMOKE_PASS simulated_seconds=600 pool=", pool_size_before, " active=", active_count)
	game.queue_free()
	await process_frame
	await process_frame
	quit(0)
