extends Node

const SAVE_PATH: String = "user://highscore.dat"
const TOP_BAR_HEIGHT: float = 80.0
const BOTTOM_BAR_HEIGHT: float = 72.0
const INVINCIBILITY_DURATION: float = 8.0
const NO_EFFECT: int = -1
const PASSIVE_EFFECTS: Dictionary = {
	"speed": {
		"name": "Swift Feet", "desc": "+10% player speed", "max": 5,
		"color": Color(0.3, 0.9, 0.3),
	},
	"slow": {
		"name": "Sluggish Foes", "desc": "Mobs 15% slower", "max": 4,
		"color": Color(0.3, 0.5, 1.0),
	},
	"shield": {
		"name": "Shield", "desc": "Absorbs 1 hit", "max": 3,
		"color": Color(0.4, 1.0, 1.0),
	},
}
const PASSIVE_OPTION_COUNT: int = 3
const SPEED_STEP: float = 0.1
const MOB_SLOW_STEP: float = 0.15
const MOB_SPEED_FLOOR: float = 0.4
const PowerUpScript: GDScript = preload("res://scripts/power_up.gd")

@export var mob_scene: PackedScene
@export var power_up_scene: PackedScene
@export var passive_menu_scene: PackedScene
var score: int = 0
var high_score: int = 0
var power_up: Area2D = null
var standby_effect: int = NO_EFFECT
var play_area: Rect2
var passive_stacks: Dictionary = {}
var mob_speed_multiplier: float = 1.0
var passive_menu: CanvasLayer


func _ready() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	play_area = Rect2(
		Vector2(0, TOP_BAR_HEIGHT),
		viewport_size - Vector2(0, TOP_BAR_HEIGHT + BOTTOM_BAR_HEIGHT)
	)

	if FileAccess.file_exists(SAVE_PATH):
		var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
		high_score = file.get_32()
		file.close()
	$HUD.update_high_score(high_score)

	passive_menu = passive_menu_scene.instantiate() as CanvasLayer
	passive_menu.chosen.connect(_on_passive_chosen)
	add_child(passive_menu)
	$Player.shield_used.connect(_refresh_passive_hud)


func game_over() -> void:
	if score > high_score:
		high_score = score
		var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		file.store_32(high_score)
		file.close()
		$HUD.update_high_score(high_score)

	$HUD.show_game_over()

	$ScoreTimer.stop()
	$MobTimer.stop()
	$PowerUpTimer.stop()
	$PassivePowerUpTimer.stop()

	if is_instance_valid(power_up):
		power_up.queue_free()
		power_up = null

	standby_effect = NO_EFFECT
	$HUD.hide_active_power_up()

	$Music.stop()
	$DeathSound.play()


func new_game() -> void:
	get_tree().call_group("mobs", "queue_free")

	score = 0
	passive_stacks.clear()
	mob_speed_multiplier = 1.0
	$HUD.update_passive_icons({})

	$HUD.update_score(score)
	$HUD.show_message("Get Ready")

	$Player.start($StartPosition.position)
	$Player.play_area = play_area
	$StartTimer.start()

	$Music.play()


func _on_mob_timer_timeout() -> void:
	var mob: RigidBody2D = mob_scene.instantiate() as RigidBody2D

	# Choose a random location on Path2D.
	var mob_spawn_location: PathFollow2D = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()

	mob.position = mob_spawn_location.position

	# Set the mob's direction perpendicular to the path direction.
	var direction: float = mob_spawn_location.rotation + PI / 2

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	var velocity: Vector2 = Vector2(randf_range(150.0, 250.0) * mob_speed_multiplier, 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	add_child(mob)


func _on_score_timer_timeout() -> void:
	score += 1
	$HUD.update_score(score)


func _on_power_up_timer_timeout() -> void:
	power_up = power_up_scene.instantiate() as Area2D
	power_up.effect_type = PowerUpScript.Effect.values().pick_random()
	power_up.collected.connect(_on_power_up_collected)
	power_up.expired.connect(_on_power_up_expired)

	power_up.position = Vector2(
		randf_range(play_area.position.x, play_area.end.x),
		randf_range(play_area.position.y, play_area.end.y)
	)

	add_child(power_up)
	$PowerUpTimer.stop()


func _on_power_up_collected(effect: int) -> void:
	power_up = null
	standby_effect = effect
	$HUD.show_active_power_up(PowerUpScript.COLORS[effect])


func _on_power_up_expired() -> void:
	power_up = null
	$PowerUpTimer.start()


func _on_use_power_up_pressed() -> void:
	if standby_effect == NO_EFFECT:
		return
	match standby_effect:
		PowerUpScript.Effect.INVINCIBILITY:
			$Player.set_invincible(INVINCIBILITY_DURATION)
		PowerUpScript.Effect.CLEAR_MOBS:
			get_tree().call_group("mobs", "queue_free")
	standby_effect = NO_EFFECT
	$HUD.hide_active_power_up()
	$PowerUpTimer.start()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use_power_up"):
		_on_use_power_up_pressed()


func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()
	$PowerUpTimer.start()
	$PassivePowerUpTimer.start()


func _on_hud_quit_game() -> void:
	get_tree().quit()


func _stack_count(id: String) -> int:
	if id == "shield":
		return $Player.shield_charges
	return passive_stacks.get(id, 0)


func _roll_passive_options() -> Array:
	var pool: Array = PASSIVE_EFFECTS.keys().filter(
		func(id: String) -> bool: return _stack_count(id) < PASSIVE_EFFECTS[id]["max"]
	)
	pool.shuffle()
	return pool.slice(0, PASSIVE_OPTION_COUNT)


func _on_passive_power_up_timer_timeout() -> void:
	var options: Array = _roll_passive_options()
	if options.is_empty():
		return
	passive_menu.show_options(options, PASSIVE_EFFECTS)
	get_tree().paused = true


func _on_passive_chosen(id: String) -> void:
	if id == "shield":
		$Player.shield_charges += 1
	else:
		passive_stacks[id] = _stack_count(id) + 1
		_apply_passive_stacks()
	_refresh_passive_hud()
	get_tree().paused = false


func _apply_passive_stacks() -> void:
	$Player.speed_multiplier = 1.0 + SPEED_STEP * passive_stacks.get("speed", 0)
	mob_speed_multiplier = maxf(MOB_SPEED_FLOOR, 1.0 - MOB_SLOW_STEP * passive_stacks.get("slow", 0))


func _refresh_passive_hud() -> void:
	var entries: Dictionary = {}
	for id in PASSIVE_EFFECTS:
		var count: int = _stack_count(id)
		if count > 0:
			entries[id] = {"color": PASSIVE_EFFECTS[id]["color"], "count": count}
	$HUD.update_passive_icons(entries)
