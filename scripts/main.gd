extends Node

const SAVE_PATH: String = "user://highscore.dat"
const TOP_BAR_HEIGHT: float = 80.0
const BOTTOM_BAR_HEIGHT: float = 72.0
const INVINCIBILITY_DURATION: float = 8.0
const NO_EFFECT: int = -1

@export var mob_scene: PackedScene
@export var power_up_scene: PackedScene
var score: int = 0
var high_score: int = 0
var power_up: PowerUp = null
var standby_effect: int = NO_EFFECT
var play_area: Rect2

@onready var hud: HUD = $HUD
@onready var player: Player = $Player
@onready var start_position: Marker2D = $StartPosition
@onready var mob_spawn_location: PathFollow2D = $MobPath/MobSpawnLocation
@onready var start_timer: Timer = $StartTimer
@onready var score_timer: Timer = $ScoreTimer
@onready var mob_timer: Timer = $MobTimer
@onready var power_up_timer: Timer = $PowerUpTimer
@onready var music: AudioStreamPlayer2D = $Music
@onready var death_sound: AudioStreamPlayer2D = $DeathSound


func _ready() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	play_area = Rect2(
		Vector2(0, TOP_BAR_HEIGHT), viewport_size - Vector2(0, TOP_BAR_HEIGHT + BOTTOM_BAR_HEIGHT)
	)

	if FileAccess.file_exists(SAVE_PATH):
		var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
		high_score = file.get_32()
		file.close()
	hud.update_high_score(high_score)


func game_over() -> void:
	if score > high_score:
		high_score = score
		var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		file.store_32(high_score)
		file.close()
		hud.update_high_score(high_score)

	hud.show_game_over()

	score_timer.stop()
	mob_timer.stop()
	power_up_timer.stop()

	if is_instance_valid(power_up):
		power_up.queue_free()
		power_up = null

	standby_effect = NO_EFFECT
	hud.hide_active_power_up()

	music.stop()
	death_sound.play()


func new_game() -> void:
	get_tree().call_group("mobs", "queue_free")

	score = 0

	hud.update_score(score)
	hud.show_message("Get Ready")

	player.start(start_position.position)
	player.play_area = play_area
	start_timer.start()

	music.play()


func _on_mob_timer_timeout() -> void:
	var mob: RigidBody2D = mob_scene.instantiate() as RigidBody2D

	# Choose a random location on Path2D.
	mob_spawn_location.progress_ratio = randf()

	mob.position = mob_spawn_location.position

	# Set the mob's direction perpendicular to the path direction.
	var direction: float = mob_spawn_location.rotation + PI / 2

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	var velocity: Vector2 = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	add_child(mob)


func _on_score_timer_timeout() -> void:
	score += 1
	hud.update_score(score)


func _on_power_up_timer_timeout() -> void:
	power_up = power_up_scene.instantiate() as PowerUp
	power_up.effect_type = PowerUp.Effect.values().pick_random()
	power_up.collected.connect(_on_power_up_collected)
	power_up.expired.connect(_on_power_up_expired)

	power_up.position = Vector2(
		randf_range(play_area.position.x, play_area.end.x),
		randf_range(play_area.position.y, play_area.end.y)
	)

	add_child(power_up)
	power_up_timer.stop()


func _on_power_up_collected(effect: int) -> void:
	power_up = null
	standby_effect = effect
	hud.show_active_power_up(PowerUp.COLORS[effect])


func _on_power_up_expired() -> void:
	power_up = null
	power_up_timer.start()


func _on_use_power_up_pressed() -> void:
	if standby_effect == NO_EFFECT:
		return
	match standby_effect:
		PowerUp.Effect.INVINCIBILITY:
			player.set_invincible(INVINCIBILITY_DURATION)
		PowerUp.Effect.CLEAR_MOBS:
			get_tree().call_group("mobs", "queue_free")
	standby_effect = NO_EFFECT
	hud.hide_active_power_up()
	power_up_timer.start()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use_power_up"):
		_on_use_power_up_pressed()


func _on_start_timer_timeout() -> void:
	mob_timer.start()
	score_timer.start()
	power_up_timer.start()


func _on_hud_quit_game() -> void:
	get_tree().quit()
