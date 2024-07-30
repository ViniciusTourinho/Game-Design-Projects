extends CharacterBody2D


@export var speed = 100

@onready var sprite: Sprite2D = Sprite2D


func _physics_process(delta: float) -> void:
	
	move_and_slide()


func rotate_sprite() -> void:
	# Girar Sprite
	if input_vector.x > 0:
		sprite.flip_h = false
	elif input_vector.x < 0:
		sprite.flip_h = true
