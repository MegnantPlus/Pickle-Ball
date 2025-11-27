extends CharacterBody2D
@onready var animate: AnimatedSprite2D = $AnimatedCharacter

const SPEED = 500.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 1000.0  # THÊM: Tốc độ dash
const DASH_DURATION = 0.15  # THÊM: Thời gian dash

var is_dashing = false  # THÊM: Trạng thái dash
var can_dash = true  # THÊM: Có thể dash hay không

func _physics_process(delta: float) -> void:
	move()
	move_and_slide()
	
	
func move():
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
	# THÊM: Xử lý dash
	if Input.is_action_just_pressed("dash") and can_dash and input_direction != Vector2.ZERO:
		start_dash()
	# THÊM: Áp dụng tốc độ dựa trên trạng thái dash
	if is_dashing:
		velocity = input_direction * DASH_SPEED
	else:
		velocity = input_direction * SPEED
		
# THÊM: Hàm dash
func start_dash():
	is_dashing = true
	can_dash = false
	# Timer kết thúc dash
	get_tree().create_timer(DASH_DURATION).timeout.connect(_on_dash_timeout)
	# Timer cooldown dash
	get_tree().create_timer(0.5).timeout.connect(_on_dash_cooldown_timeout)

func _on_dash_timeout():
	is_dashing = false

func _on_dash_cooldown_timeout():
	can_dash = true
