extends CanvasLayer

signal start_game
signal quit_game

var passive_icons: Dictionary = {}
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


func show_active_power_up(color: Color) -> void:
	$ActiveSlotIcon.color = color
	$ActiveSlotIcon.show()
	$ActiveSlotLabel.show()


func hide_active_power_up() -> void:
	$ActiveSlotIcon.hide()
	$ActiveSlotLabel.hide()


func update_passive_icons(entries: Dictionary) -> void:
	for icon in passive_icons.values():
		icon.hide()
	for id in entries:
		var icon: ColorRect = passive_icons.get(id)
		if icon == null:
			icon = _create_passive_icon()
			passive_icons[id] = icon
		icon.color = entries[id]["color"]
		icon.get_child(0).text = "x%d" % entries[id]["count"]
		icon.show()


func _create_passive_icon() -> ColorRect:
	var icon: ColorRect = ColorRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	var label: Label = Label.new()
	label.add_theme_font_override("font", $ScoreLabel.get_theme_font("font"))
	label.add_theme_font_size_override("font_size", 16)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	icon.add_child(label)
	$PassiveRow.add_child(icon)
	return icon


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
