extends CharacterBody2D
@onready var animate: AnimatedSprite2D = $AnimatedCharacter
@onready var hit_box: Area2D = $HitBox 
@export var steer_influence: float = 1.0
@export var aim_width: float = 300.0
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
	if Input.is_action_just_pressed("hit") and ball_in_range != null:
		print("Player Smash!")
		
		# 1. Lấy vị trí Gốc (Tâm hồng tâm)
		var base_target_pos = Vector2.ZERO
		if aim_marker != null:
			base_target_pos = aim_marker.global_position
		else:
			# Fallback: Đánh thẳng lên trên (-Y)
			base_target_pos = ball_in_range.global_position + Vector2(0, -500)
		
		# 2. Xử lý Input (Trái/Phải)
		# Input.get_axis trả về: -1 (Trái), 1 (Phải), 0 (Không bấm)
		var input_axis = Input.get_axis("left", "right")
		
		# Nếu bạn muốn hỗ trợ Analog (tay cầm) để đánh góc 50% thì giữ nguyên
		# Nếu muốn bàn phím nhạy hơn, có thể giữ nguyên vì get_axis đã xử lý rồi
		
		# 3. TÍNH TOÁN ĐIỂM ĐÍCH THỰC TẾ (Target Offset)
		# Đích cuối = Đích gốc + (Hướng bấm * Độ rộng sân)
		# Ví dụ: Bấm Trái (-1) * 250 = Dịch sang trái 250px
		var offset_vector = Vector2(input_axis * aim_width, 0)
		var final_target_pos = base_target_pos + offset_vector
		
		# 4. Tính hướng đánh (Từ bóng -> Đích cuối)
		var hit_direction = (final_target_pos - ball_in_range.global_position).normalized()
		
		# 5. Thực thi
		if ball_in_range.has_method("set_ball_direction"):
			ball_in_range.set_ball_direction(hit_direction)

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
