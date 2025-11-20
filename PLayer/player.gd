extends CharacterBody2D
@onready var animate: AnimatedSprite2D = $AnimatedSprite2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0


func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_direction = Vector2.ZERO
	if Input.is_action_pressed("left"):
		input_direction.x -= 1
		animate.flip_h = true
	if Input.is_action_pressed("right"):
		input_direction.x += 1
		animate.flip_h = false
	if Input.is_action_pressed("up"):
		input_direction.y -= 1
		animate.flip_v = false
	if Input.is_action_pressed("down"):
		input_direction.y += 1
		animate.flip_v = true
	if input_direction != Vector2.ZERO:
		input_direction = input_direction.normalized()
	velocity = input_direction * 500	
	move_and_slide()
