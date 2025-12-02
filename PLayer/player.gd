extends CharacterBody2D
@onready var animate: AnimatedSprite2D = $AnimatedCharacter
@onready var hit_box: Area2D = $HitBox 


const SPEED = 500.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 2000.0
const DASH_DURATION = 0.15


var is_dashing = false
var can_dash = true

# Biến lưu trữ quả bóng hiện tại đang nằm trong tầm đánh
var ball_in_range: RigidBody2D = null
func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	move()
	handle_hit_input()
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
func handle_hit_input():
	# Chỉ đánh khi bấm J và có bóng
	if Input.is_action_just_pressed("hit") and ball_in_range != null:
		print("Smash!")
		
		# 1. Tính hướng đánh (Logic cũ của bạn vẫn ổn)
		# Hoặc nâng cấp lên logic hướng chuột/phím di chuyển như bài trước tôi dạy
		var direction = (ball_in_range.global_position - global_position).normalized()
		
		# 2. GỌI HÀM MỚI BÊN BALL
		# Thay vì apply_impulse, ta gọi hàm set direction
		# Kiểm tra để tránh lỗi crash nếu ball_in_range không có hàm đó
		if ball_in_range.has_method("set_ball_direction"):
			ball_in_range.set_ball_direction(direction)


func _on_dash_timeout():
	is_dashing = false

func _on_dash_cooldown_timeout():
	can_dash = true


func _on_hit_box_body_entered(body: Node2D) -> void:
# "The Godot Way": Kiểm tra bằng Group
	# Dễ đọc hơn nhiều so với check layer bitmask
	if body.is_in_group("ball"): 
		ball_in_range = body
		print("Bóng (Group 'ball') đã vào tầm đánh!")


func _on_hit_box_body_exited(body: Node2D) -> void:
# Cũng kiểm tra group hoặc so sánh trực tiếp
	if body == ball_in_range:
		ball_in_range = null
		print("Bóng đã rời đi!")
