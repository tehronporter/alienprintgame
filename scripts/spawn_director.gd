extends Node

var main: Node
var spawn_timer := 0.0
var elite_timer := 180.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 13371337

func reset_director() -> void:
	spawn_timer = 0.3
	elite_timer = 180.0
	for enemy in main.enemy_pool:
		enemy.deactivate()

func _process(delta: float) -> void:
	if not main.game_started or main.game_over or main.paused:
		return
	spawn_timer -= delta
	elite_timer -= delta
	var tier := int(main.survival_time / 60.0) + 1
	var active_count := _active_count()
	var cap: int = min(42, 7 + int(main.survival_time / 60.0) * 2)
	if spawn_timer <= 0.0 and active_count < cap:
		_spawn_one(tier)
		spawn_timer = max(0.28, 1.8 - main.survival_time * 0.008)
	if elite_timer <= 0.0:
		if active_count < cap:
			_spawn_one(tier, true)
		elite_timer = max(105.0, 180.0 - main.survival_time * 0.04)

func _active_count() -> int:
	var count := 0
	for enemy in main.enemy_pool:
		if enemy.active:
			count += 1
	return count

func _spawn_one(tier: int, force_elite := false) -> void:
	var enemy = main.get_free_enemy()
	if enemy == null:
		return
	var angle := rng.randf_range(0.0, TAU)
	var radius := rng.randf_range(26.0, 43.0)
	var spawn_position: Vector3 = main.player.global_position + Vector3(cos(angle) * radius, 0, sin(angle) * radius)
	spawn_position.x = clamp(spawn_position.x, -46.0, 46.0)
	spawn_position.z = clamp(spawn_position.z, -46.0, 46.0)
	var kind := "standard"
	if force_elite:
		kind = "elite"
	elif main.survival_time > 60.0 and rng.randf() < min(0.4, 0.08 + main.survival_time * 0.002):
		kind = "bruiser"
	elif rng.randf() < 0.28:
		kind = "scout"
	enemy.activate(kind, spawn_position, tier)
