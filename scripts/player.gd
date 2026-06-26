extends Area2D

signal hit

@export var speed: int = 400
var screen_size: Vector2
var touch_active: bool = false
var touch_target: Vector2 = Vector2.ZERO


func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		touch_active = event.pressed
		if event.pressed:
			touch_target = get_viewport().get_screen_transform().affine_inverse() * event.position
	elif event is InputEventScreenDrag:
		touch_target = get_viewport().get_screen_transform().affine_inverse() * event.position


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

	if touch_active and velocity == Vector2.ZERO:
		var to_target: Vector2 = touch_target - position
		if to_target.length() > 4.0:
			velocity = to_target.normalized()

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0


func _on_body_entered(_body: Node2D) -> void:
	hide()
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)


func start(pos: Vector2) -> void:
	position = pos
	touch_active = false
	show()
	$CollisionShape2D.disabled = false
