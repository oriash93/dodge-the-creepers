extends Area2D

signal collected

const RADIUS: float = 16.0
const COLOR: Color = Color(1.0, 0.85, 0.1)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)


func _on_area_entered(area: Area2D) -> void:
	if area.name != "Player":
		return
	print("Power-up collected!")
	collected.emit()
	queue_free()
