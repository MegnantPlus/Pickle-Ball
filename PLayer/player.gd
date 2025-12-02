extends CharacterBody2D
@onready var animate: AnimatedSprite2D = $AnimatedCharacter
@onready var hit_box: Area2D = $HitBox 
@export var steer_influence: float = 1.0

const SPEED = 500.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 2000.0
const DASH_DURATION = 0.15


var is_dashing = false
var can_dash = true


var ball_in_range: RigidBody2D = null # Biến lưu trữ quả bóng hiện tại đang nằm trong tầm đánh
var aim_marker: Node2D = null # Biến để nhớ cái AimPoint đang ở đâu
func _ready() -> void:
# TỰ ĐỘNG TÌM MARKER KHI GAME BẮT ĐẦU
	# Lệnh này tìm node đầu tiên trong nhóm "p1_aim" (chính là cái bạn vừa tạo ở Main)
	aim_marker = get_tree().get_first_node_in_group("p1_aim")
	
	if aim_marker == null:
		print("LỖI: Không tìm thấy AimPoint! Hãy chắc chắn bạn đã tạo Marker2D và gán Group 'p1_aim'.")

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
	if Input.is_action_pressed("down"):
		input_direction.y += 1
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
	# Bước 2B: Logic đánh bóng mới
	if Input.is_action_just_pressed("hit") and ball_in_range != null:
		print("Smash!")
		
		# 1. Xác định Đích đến (Vị trí của AimPoint)
		var target_pos = Vector2.ZERO
		if aim_marker != null:
			target_pos = aim_marker.global_position
		else:
			# Fallback: Nếu lỡ quên đặt AimPoint thì đánh thẳng lên trên
			target_pos = ball_in_range.global_position + Vector2(0, -500)
			
		# 2. Tính Vector Cơ Bản (Từ Bóng -> Đích AimPoint)
		var base_direction = (target_pos - ball_in_range.global_position).normalized()
		
		# 3. Tính Vector Phím Bấm (Người chơi muốn bẻ lái đi đâu?)
		var input_steer = Vector2.ZERO
		if Input.is_action_pressed("left"): input_steer.x -= 1
		if Input.is_action_pressed("right"): input_steer.x += 1
		# Nếu muốn chỉnh độ cao thấp bóng thì thêm up/down, còn không thì thôi
		
		# 4. TRỘN HAI VECTOR (Phần quan trọng nhất)
		# Công thức: Hướng cuối = Hướng về đích + (Hướng phím * Độ ảnh hưởng)
		var final_direction = (base_direction + (input_steer * steer_influence)).normalized()
		
		# 5. Ra lệnh cho bóng
		# (Đảm bảo bên slime_ball.gd bạn đã có hàm set_ball_direction như bài trước)
		if ball_in_range.has_method("set_ball_direction"):
			ball_in_range.set_ball_direction(final_direction)


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
