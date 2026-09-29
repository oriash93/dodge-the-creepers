class_name HUD
extends CanvasLayer

signal start_game
signal quit_game

@onready var is_web: bool = OS.has_feature("web")
@onready var message: Label = $Message
@onready var message_timer: Timer = $MessageTimer
@onready var start_button: Button = $StartButton
@onready var quit_button: Button = $QuitButton
@onready var version_label: Label = $VersionLabel
@onready var score_label: Label = $ScoreLabel
@onready var high_score_label: Label = $HighScoreLabel
@onready var active_slot_icon: ColorRect = $ActiveSlotIcon
@onready var active_slot_label: Label = $ActiveSlotLabel


func _ready() -> void:
	version_label.text = str(ProjectSettings.get_setting("application/config/version", ""))
	if is_web:
		quit_button.hide()


func show_message(text: String) -> void:
	message.text = text
	message.show()
	message_timer.start()


func show_game_over() -> void:
	show_message("Game Over")
	await message_timer.timeout

	message.text = "Dodge the Creeps!"
	message.show()
	await get_tree().create_timer(1.0).timeout

	start_button.text = "Restart"
	start_button.show()
	if not is_web:
		quit_button.show()


func show_active_power_up(color: Color) -> void:
	active_slot_icon.color = color
	active_slot_icon.show()
	active_slot_label.show()


func hide_active_power_up() -> void:
	active_slot_icon.hide()
	active_slot_label.hide()


func update_score(score: int) -> void:
	score_label.text = str(score)


func update_high_score(high_score: int) -> void:
	high_score_label.text = "Best: " + str(high_score)


func _on_start_button_pressed() -> void:
	start_button.hide()
	quit_button.hide()
	version_label.hide()
	start_game.emit()


func _on_quit_button_pressed() -> void:
	quit_game.emit()


func _on_message_timer_timeout() -> void:
	message.hide()
