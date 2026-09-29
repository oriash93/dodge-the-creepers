extends RigidBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("mobs")
	var mob_types: PackedStringArray = sprite.sprite_frames.get_animation_names()
	sprite.animation = mob_types[randi() % mob_types.size()]
	sprite.play()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
