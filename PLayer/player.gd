extends CharacterBody2D


@onready var animate: AnimatedSprite2D = $AnimatedCharacter
@onready var hit_box: Area2D = $HitBox
@export var steer_influence: float = 1.0
@export var aim_width: float = 300.0
@export var spin_aim_width: float = 150.0


const SPEED = 500.0
const JUMP_VELOCITY = -400.0

@export var spin_angle: float = -300.0 # Góc xoáy (độ)
var spin_marker: Node2D = null

# CẤU HÌNH DASH
const DASH_SPEED = 1000.0
const DASH_DURATION = 0.3 # Tăng lên xíu để dễ test Spin (0.15 hơi nhanh quá)
const DASH_COOLDOWN = 0.5 # Hồi chiêu

var is_dashing = false
var can_dash = true
var current_dash_time: float = 0.0 # Biến đếm ngược thời gian dash
var dash_locked_direction: Vector2 = Vector2.ZERO # Hướng bị khóa khi dash

var ball_in_range: RigidBody2D = null # Biến lưu trữ quả bóng hiện tại đang nằm trong tầm đánh
var aim_marker: Node2D = null # Biến để nhớ cái AimPoint đang ở đâu

func _ready() -> void:
# TỰ ĐỘNG TÌM MARKER KHI GAME BẮT ĐẦU
	# Lệnh này tìm node đầu tiên trong nhóm "p1_aim" (chính là cái bạn vừa tạo ở Main)
	aim_marker = get_tree().get_first_node_in_group("p1_aim")
	
	if aim_marker == null:
		print("LỖI: Không tìm thấy AimPoint! Hãy chắc chắn bạn đã tạo Marker2D và gán Group 'p1_aim'.")
	# THÊM: Tìm Spin Marker
	spin_marker = get_tree().get_first_node_in_group("spin_aim")
	if spin_marker == null:
		print("CẢNH BÁO: Chưa có SpinMarker! Hãy tạo Marker2D và gán group 'spin_aim' trong Main.")

func _physics_process(delta: float) -> void:
	# Nếu ĐANG DASH
	if is_dashing:
		# 1. Trừ thời gian
		current_dash_time -= delta
		
		# 2. Ép vận tốc theo hướng đã khóa (Bỏ qua input người chơi lúc này)
		velocity = dash_locked_direction * DASH_SPEED
		
		# 3. Kiểm tra hết giờ
		if current_dash_time <= 0:
			end_dash()
			
	# Nếu KHÔNG DASH (Di chuyển thường)
	else:
		move() # Hàm move cũ của bạn
		handle_hit_input() # Đánh thường (J)

	move_and_slide()
	
# Hàm kết thúc dash tách riêng cho gọn
func end_dash():
	is_dashing = false
	velocity = Vector2.ZERO # Phanh lại ngay lập tức (hoặc lerp nếu muốn mượt)
	print("<<< END DASH")

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
		
	# Kích hoạt Dash (Giữ lại đoạn này)
	if Input.is_action_just_pressed("dash") and can_dash and input_direction != Vector2.ZERO:
		start_dash()

	# Chỉ di chuyển bình thường khi không dash
	if not is_dashing:
		velocity = input_direction * SPEED
		
# THÊM: Hàm dash
func start_dash():
	# 1. Bật cờ trạng thái
	is_dashing = true
	can_dash = false
	
	# 2. Reset đồng hồ đếm ngược (Đầy bình)
	current_dash_time = DASH_DURATION
	
	# 3. KHÓA HƯỚNG (Quan trọng)
	# Lấy hướng input hiện tại. Nếu đang đứng im thì dash theo hướng mặt đang nhìn
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("left"): input_dir.x -= 1
	if Input.is_action_pressed("right"): input_dir.x += 1
	if Input.is_action_pressed("up"): input_dir.y -= 1
	if Input.is_action_pressed("down"): input_dir.y += 1
	
	if input_dir != Vector2.ZERO:
		dash_locked_direction = input_dir.normalized()
	else:
		# Fallback: Nếu không bấm gì thì dash theo hướng mặt (biến last_facing_direction từ bài trước)
		# Nếu chưa có biến này thì mặc định dash sang phải (Vector2.RIGHT)
		dash_locked_direction = Vector2.RIGHT

	# 4. Chỉ dùng Timer để HỒI CHIÊU (Cooldown)
	get_tree().create_timer(DASH_COOLDOWN).timeout.connect(_on_dash_cooldown_timeout)
	
	print(">>> START DASH! Hướng: ", dash_locked_direction)


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
	if body.is_in_group("ball"):
			ball_in_range = body
			print("Bóng vào tầm!")

			# Nếu đang Dash -> Kích hoạt đánh tự động luôn (Auto-Hit)
			if is_dashing:
				perform_dash_hit()

func _on_hit_box_body_exited(body: Node2D) -> void:
# Cũng kiểm tra group hoặc so sánh trực tiếp
	if body == ball_in_range:
		ball_in_range = null
		print("Bóng đã rời đi!")

 # 1. HÀM PHÂN LOẠI (Router)
func perform_dash_hit():
	print("Dash Hit Triggered!")
	
	# Logic: Nếu thời gian còn lại ít hơn 30% -> Là cuối cú Dash (Spin)
	# current_dash_time chạy từ 0.25 về 0.
	var spin_threshold = DASH_DURATION * 1
	
	if current_dash_time <= spin_threshold:
		perform_spin_shot() # Cuối hành trình -> Xoáy
	else:
		perform_normal_dash_shot() # Đầu hành trình -> Đánh chéo
	
	# Đánh xong thì dừng dash luôn cho cảm giác lực va chạm
	end_dash()

# 2. HÀM ĐÁNH CHÉO SÂN (Normal Dash)
func perform_normal_dash_shot():
	print(">> Normal Dash Shot (Cross-court)")
	
	# Lấy vị trí AimPoint cơ bản
	var target_pos = Vector2.ZERO
	if aim_marker != null:
		target_pos = aim_marker.global_position
	
	# LOGIC ĐÁNH CHÉO:
	# Đứng bên Trái (X < 0) -> Đánh sang Phải (+aim_width)
	# Đứng bên Phải (X > 0) -> Đánh sang Trái (-aim_width)
	var offset_x = 0.0
	if global_position.x < 0:
		offset_x = aim_width
	else:
		offset_x = - aim_width
	
	target_pos.x += offset_x
	
	# Thực hiện đánh
	var direction = (target_pos - ball_in_range.global_position).normalized()
	if ball_in_range.has_method("set_ball_direction"):
		ball_in_range.set_ball_direction(direction)

# 3. HÀM ĐÁNH XOÁY (Spin Dash)
func perform_spin_shot():
	print(">> SPIN SHOT (Directional)!!!")
	
	# 1. Lấy điểm mốc SpinPoint
	var base_target = Vector2.ZERO
	if spin_marker != null:
		base_target = spin_marker.global_position
	else:
		base_target = ball_in_range.global_position + Vector2(0, -300)
		
	# 2. Lấy Input hướng (Trái/Phải) TẠI THỜI ĐIỂM ĐÁNH
	# Lưu ý: Người chơi có thể vừa Dash vừa giữ phím hướng
	var input_axis = Input.get_axis("left", "right")
	
	# 3. Tính Điểm Đích (Target) + Độ lệch (Offset)
	# Nếu bấm trái -> Lệch trái. Bấm phải -> Lệch phải. Không bấm -> Lệch 0
	var final_target = base_target + Vector2(input_axis * spin_aim_width, 0)

	# --- KIỂM TRA ĐỘ CAO (Y) ---
	# Đảm bảo điểm đích phải nằm SÂU hơn bóng ít nhất 200px (để bóng luôn bay dốc lên)
	# Nếu điểm đích nằm ngang hàng với bóng, góc đánh sẽ là 90 độ -> Xoáy cái là ngược ngay.
	
	if final_target.y > ball_in_range.global_position.y - 200:
		# Đẩy điểm đích ra xa hơn về phía trên
		final_target.y = ball_in_range.global_position.y - 200
	
	# 4. Tính Góc Xoáy (Spin Angle) dựa trên Input
	var angle_to_apply = 0.0
	
	if input_axis != 0:
		# TRƯỜNG HỢP A: Có bấm phím -> Xoáy theo phím
		if input_axis < 0: # Bấm Trái
			angle_to_apply = - spin_angle # Xoáy sang trái
		else: # Bấm Phải
			angle_to_apply = spin_angle # Xoáy sang phải
	else:
		# TRƯỜNG HỢP B: Không bấm phím -> Logic cũ (Tự động xoáy ra biên)
		if global_position.x < 0:
			angle_to_apply = - spin_angle
		else:
			angle_to_apply = spin_angle
			
	# 5. Gửi lệnh cho bóng (Dùng hàm set_spin_shot bên slime_ball.gd)
	if ball_in_range.has_method("set_spin_shot"):
		ball_in_range.set_spin_shot(final_target, angle_to_apply)
