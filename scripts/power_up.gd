extends Area2D

signal collected(effect: Effect)
signal expired

enum Effect { INVINCIBILITY, CLEAR_MOBS }

const RADIUS: float = 16.0
const COLORS: Dictionary = {
	Effect.INVINCIBILITY: Color(1.0, 0.85, 0.1),
	Effect.CLEAR_MOBS: Color(0.9, 0.3, 0.9),
}

var effect_type: Effect = Effect.INVINCIBILITY


func _ready() -> void:
	$DespawnTimer.start()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLORS[effect_type])


func _on_area_entered(area: Area2D) -> void:
	if area.name != "Player":
		return
	$DespawnTimer.stop()
	collected.emit(effect_type)
	queue_free()


func _on_despawn_timer_timeout() -> void:
	expired.emit()
	queue_free()
