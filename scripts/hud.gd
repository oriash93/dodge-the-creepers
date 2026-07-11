extends CanvasLayer

signal start_game
signal quit_game

@onready var is_web: bool = OS.has_feature("web")


func _ready() -> void:
	$VersionLabel.text = str(ProjectSettings.get_setting("application/config/version", ""))
	if is_web:
		$QuitButton.hide()


func show_message(text: String) -> void:
	$Message.text = text
	$Message.show()
	$MessageTimer.start()


func show_game_over() -> void:
	show_message("Game Over")
	await $MessageTimer.timeout

	$Message.text = "Dodge the Creeps!"
	$Message.show()
	await get_tree().create_timer(1.0).timeout

	$StartButton.text = "Restart"
	$StartButton.show()
	if not is_web:
		$QuitButton.show()


func update_score(score: int) -> void:
	$ScoreLabel.text = str(score)


func update_high_score(high_score: int) -> void:
	$HighScoreLabel.text = "Best: " + str(high_score)


func _on_start_button_pressed() -> void:
	$StartButton.hide()
	$QuitButton.hide()
	$VersionLabel.hide()
	start_game.emit()


func _on_quit_button_pressed() -> void:
	quit_game.emit()


func _on_message_timer_timeout() -> void:
	$Message.hide()
