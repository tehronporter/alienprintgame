extends SceneTree
## Native-renderer visual review, including each calibrated viewmodel and ADS.
func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._start_game()
	await create_timer(0.6).timeout
	game.set_process(false)
	game.player.set_physics_process(false)
	game.director.set_process(false)
	for enemy in game.enemy_pool: enemy.set_physics_process(false)
	for index in range(3):
		game.player.switch_weapon(index)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/alien-weapon-%d.png" % index)
	game.player.switch_weapon(0)
	game.player.is_aiming = true
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/alien-ads.png")
	game.player.is_aiming = false
	game.enemy_pool[0].activate("bruiser", Vector3(-4, 0.35, 6), 4)
	game.enemy_pool[1].activate("elite", Vector3(4, 0.35, 5), 4)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/alien-heavy-wave.png")
	print("VISUAL_CAPTURE_PASS weapons=3 ads=1 heavy_variants=2")
	quit()
