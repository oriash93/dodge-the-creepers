extends Area2D

signal hit

@export var speed: int = 400
var play_area: Rect2
var invincible: bool = false
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
		velocity = velocity.normalized() * speed
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


func _on_invincibility_timer_timeout() -> void:
	_end_invincibility()


func _on_body_entered(_body: Node2D) -> void:
	if invincible:
		return
	hide()
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)


func start(pos: Vector2) -> void:
	position = pos
	_end_invincibility()
	$InvincibilityTimer.stop()
	show()
	$CollisionShape2D.disabled = false
