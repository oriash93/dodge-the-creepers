extends Area2D

signal hit
signal shield_used

const SHIELD_COLORS: Array[Color] = [
	Color(0.4, 1.0, 1.0),
	Color(0.5, 0.8, 1.0),
	Color(0.9, 0.6, 1.0),
]
const SHIELD_BASE_RADIUS: float = 32.0
const SHIELD_RING_GAP: float = 6.0

@export var speed: int = 400
var play_area: Rect2
var invincible: bool = false
var speed_multiplier: float = 1.0
var shield_charges: int = 0:
	set(value):
		shield_charges = value
		queue_redraw()
var pop: float = 0.0:
	set(value):
		pop = value
		queue_redraw()
var blink_tween: Tween


func _ready() -> void:
	play_area = Rect2(Vector2.ZERO, get_viewport_rect().size)
	hide()


func _process(delta: float) -> void:
	var velocity: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed * speed_multiplier
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	position = position.clamp(play_area.position, play_area.end)

	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0


func set_invincible(duration: float) -> void:
	invincible = true
	$InvincibilityTimer.start(duration)
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(self, "modulate:a", 0.35, 0.15)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	blink_tween = tween


func _end_invincibility() -> void:
	invincible = false
	if blink_tween:
		blink_tween.kill()
		blink_tween = null
	modulate.a = 1.0


func _draw() -> void:
	for i in mini(shield_charges, SHIELD_COLORS.size()):
		var radius: float = SHIELD_BASE_RADIUS + i * SHIELD_RING_GAP
		var color: Color = SHIELD_COLORS[i]
		draw_circle(Vector2.ZERO, radius, Color(color, 0.08))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color, 0.85), 2.5)
	if pop > 0.0 and pop < 1.0:
		var pop_radius: float = SHIELD_BASE_RADIUS + pop * 40.0
		draw_arc(Vector2.ZERO, pop_radius, 0.0, TAU, 48, Color(1, 1, 1, 1.0 - pop), 4.0)


func _pop_shield() -> void:
	pop = 0.0
	create_tween().tween_property(self, "pop", 1.0, 0.3)


func _on_invincibility_timer_timeout() -> void:
	_end_invincibility()


func _on_body_entered(_body: Node2D) -> void:
	if invincible:
		return
	if shield_charges > 0:
		shield_charges -= 1
		shield_used.emit()
		_pop_shield()
		return
	hide()
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)


func start(pos: Vector2) -> void:
	position = pos
	speed_multiplier = 1.0
	shield_charges = 0
	_end_invincibility()
	$InvincibilityTimer.stop()
	show()
	$CollisionShape2D.disabled = false
