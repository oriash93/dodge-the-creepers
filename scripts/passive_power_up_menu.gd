extends CanvasLayer

signal chosen(effect_id: String)

const FONT: FontFile = preload("res://assets/fonts/Xolonium-Regular.ttf")
const MAX_OPTIONS: int = 3

var option_ids: Array[String] = []


func _ready() -> void:
	for i in MAX_OPTIONS:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(360, 90)
		button.add_theme_font_override("font", FONT)
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(_on_option_pressed.bind(i))
		$Center/Options/Buttons.add_child(button)


func show_options(options: Array, effects: Dictionary) -> void:
	option_ids.clear()
	var buttons: Array[Node] = $Center/Options/Buttons.get_children()
	for i in buttons.size():
		buttons[i].visible = i < options.size()
		if i < options.size():
			var id: String = options[i]
			option_ids.append(id)
			buttons[i].text = "%s\n%s" % [effects[id]["name"], effects[id]["desc"]]
	show()


func _on_option_pressed(index: int) -> void:
	hide()
	chosen.emit(option_ids[index])
