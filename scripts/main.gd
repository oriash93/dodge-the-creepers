extends Node

@export var mob_scene: PackedScene
var score
var high_score := 0
const SAVE_PATH = "user://highscore.dat"


func _ready():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		high_score = file.get_32()
		file.close()
	$HUD.update_high_score(high_score)


func game_over():
	if score > high_score:
		high_score = score
		var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		file.store_32(high_score)
		file.close()
		$HUD.update_high_score(high_score)

	$HUD.show_game_over()

	$ScoreTimer.stop()
	$MobTimer.stop()

	$Music.stop()
	$DeathSound.play()

func new_game():
	get_tree().call_group("mobs", "queue_free")

	score = 0

	$HUD.update_score(score)
	$HUD.show_message("Get Ready")

	$Player.start($StartPosition.position)
	$StartTimer.start()

	$Music.play()

func _on_mob_timer_timeout():
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()

	# Set the mob's position to the random location.
	mob.position = mob_spawn_location.position

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)


func _on_score_timer_timeout():
	score += 1
	$HUD.update_score(score)

func _on_start_timer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
