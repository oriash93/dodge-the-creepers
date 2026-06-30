extends Node

const SAVE_PATH: String = "user://highscore.dat"

@export var mob_scene: PackedScene
var score: int = 0
var high_score: int = 0


func _ready() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
		high_score = file.get_32()
		file.close()
	$HUD.update_high_score(high_score)


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

	$Music.stop()
	$DeathSound.play()


func new_game() -> void:
	get_tree().call_group("mobs", "queue_free")

	score = 0

	$HUD.update_score(score)
	$HUD.show_message("Get Ready")

	$Player.start($StartPosition.position)
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

	var velocity: Vector2 = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	add_child(mob)


func _on_score_timer_timeout() -> void:
	score += 1
	$HUD.update_score(score)


func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()
