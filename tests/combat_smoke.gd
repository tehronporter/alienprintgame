extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	game._start_game()
	for pooled_enemy in game.enemy_pool:
		pooled_enemy.deactivate()
	game.player.global_position = Vector3(0, 0, 18)
	game.player.rotation = Vector3.ZERO
	game.player.camera.rotation = Vector3.ZERO
	var target: Node = game.enemy_pool[0]
	target.activate("standard", Vector3(0, 0, 10), 1)
	await physics_frame
	var ray_start: Vector3 = game.player.camera.global_position
	var ray_end: Vector3 = ray_start - game.player.camera.global_transform.basis.z * 100.0
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [game.player]
	var result: Dictionary = game.player.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty() or result.collider != target:
		push_error("Combat smoke test failed: camera ray did not hit pooled alien")
		quit(1)
		return
	var kills_before: int = game.kills
	target.take_damage(1000)
	if target.active or game.kills != kills_before + 1:
		push_error("Combat smoke test failed: damage/death/score pipeline did not complete")
		quit(1)
		return
	print("COMBAT_SMOKE_PASS collider=", result.collider.name, " kills=", game.kills, " score=", game.score)
	await create_timer(0.5).timeout
	game.queue_free()
	await process_frame
	quit(0)
