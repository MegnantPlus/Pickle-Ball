extends CharacterBody2D

# 1. KHAI BÁO CÁC TRẠNG THÁI (ENUM)
# Enum giống như một danh sách số thứ tự: IDLE=0, CHASE=1, RECOVER=2
enum State {
	IDLE,
	CHASE,
	RECOVER
}

# --- CẤU HÌNH DASH ---
const DASH_SPEED = 900.0   # Tốc độ lướt (Nhanh hơn chạy thường)
const DASH_DURATION = 0.2  # Thời gian lướt (Ngắn thôi)
const DASH_COOLDOWN = 2.0  # Hồi chiêu (Bot không được spam liên tục)

# Khoảng cách để Bot quyết định Dash
# Nếu bóng xa hơn 150px thì mới Dash
@export var dash_trigger_distance: float = 150.0 
@export var aim_variance: float = 700.0
# Thời gian đứng im ngắm nghía sau khi đánh (0.5 giây)
var recovery_timer: float = 0.0
const RECOVERY_DURATION: float = 0.2

# Biến trạng thái
var is_dashing: bool = false
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO # Hướng lướt

# Biến lưu trạng thái hiện tại (Mặc định là đang Rảnh)
var current_state = State.IDLE
# Thêm biến aim_marker cho Bot
var bot_aim_marker: Node2D = null
# Các thông số
@export var attack_range: float = 60.0 # Tầm với của vợt Bot
const SPEED = 400.0 # Bot chạy chậm hơn Player chút cho công bằng
@onready var ball: RigidBody2D # Tham chiếu tới quả bóng
var home_position: Vector2 # Vị trí "Nhà" (Giữa sân Bot)

func _ready() -> void:
	# Tìm quả bóng trong game (Dựa vào group "ball" ta đã làm bài trước)
	ball = get_tree().get_first_node_in_group("ball")
	
	# Xác định vị trí "Nhà" là vị trí đặt Bot lúc đầu game
	home_position = global_position 
	# ... (code cũ giữ nguyên) ...
	ball = get_tree().get_first_node_in_group("ball")
	home_position = global_position
	
	# Tìm điểm ngắm của Bot
	bot_aim_marker = get_tree().get_first_node_in_group("bot_aim")

func _physics_process(_delta: float) -> void:
	# MÁY TRẠNG THÁI (THE BRAIN)
	# Dùng lệnh match (giống switch-case) để phân loại hành động
	match current_state:
		State.IDLE:
			_process_idle_state()
		State.CHASE:
			_process_chase_state()
		State.RECOVER:
			_process_recover_state()
	
	move_and_slide()

func perform_hit():
	print("Bot Smash!")
	
	# 1. Lấy vị trí hồng tâm gốc
	var base_target = Vector2.ZERO
	if bot_aim_marker != null:
		base_target = bot_aim_marker.global_position
	else:
		base_target = ball.global_position + Vector2(0, 500)
	
	# 2. TẠO ĐỘ LỆCH NGẪU NHIÊN (Randomness)
	# Random từ -200 đến +200
	var random_offset_x = randf_range(-aim_variance, aim_variance)
	
	# Tạo vị trí đích thực tế (Hồng tâm + Độ lệch)
	var final_target = base_target + Vector2(random_offset_x, 0)
	
	# 3. Tính hướng và đánh (Code cũ)
	var hit_dir = (final_target - ball.global_position).normalized()
	
	if ball.has_method("set_ball_direction"):
		ball.set_ball_direction(hit_dir)
	
	# Reset timer nghỉ (Code từ bài trước)
	recovery_timer = RECOVERY_DURATION 
	change_state(State.RECOVER)
	
# --- CÁC HÀM XỬ LÝ TỪNG TRẠNG THÁI ---

func _process_idle_state():
	# 1. Tính vị trí phòng thủ:
	# X = Theo quả bóng (để không bị lỡ nhịp)
	# Y = Giữ nguyên tại Home (để thủ gôn)
	var defensive_x = ball.global_position.x
	
	# Giới hạn không cho Bot chạy ra khỏi biên ngang (Ví dụ sân rộng 400px thì kẹp từ -200 đến 200)
	# Bạn hãy thay số 300 bằng chiều rộng thực tế của sân bạn / 2
	defensive_x = clamp(defensive_x, -300, 300) 
	
	var target_pos = Vector2(defensive_x, home_position.y)
	
	# 2. Di chuyển mượt mà tới vị trí đó
	# Dùng move_toward để di chuyển vật lý chuẩn
	var direction = (target_pos - global_position).normalized()
	
	# Nếu khoảng cách còn xa thì chạy, gần thì dừng cho đỡ rung lắc
	if global_position.distance_to(target_pos) > 5.0:
		velocity = direction * (SPEED * 0.5) # Chạy chậm thôi (50% sức) khi đang Idle
	else:
		velocity = Vector2.ZERO

	# 3. Chuyển trạng thái: Nếu bóng vượt qua lưới (Y < 0) -> SĂN!
	if ball_is_on_my_side():
		change_state(State.CHASE)

func _process_chase_state():
	if ball == null: return
	
	# 1. Tính toán cho việc DI CHUYỂN THƯỜNG (Giữ nguyên 8 hướng)
	# Vẫn phải tính target_x (dự đoán) như bài trước để chạy đón đầu
	var target_x = predict_ball_landing_x()
	target_x = clamp(target_x, -350, 350) 
	
	var target_pos = Vector2(target_x, ball.global_position.y)
	var move_direction = (target_pos - global_position).normalized()
	
	# Tính khoảng cách thực tế tới bóng
	var dist_to_ball = global_position.distance_to(ball.global_position)

	# --- 2. LOGIC DASH MỚI (CHỈ DASH NGANG) ---
	# Điều kiện kích hoạt: Bóng xa + Skill sẵn sàng + Chưa Dash
	if dist_to_ball > dash_trigger_distance and can_dash and not is_dashing:
		
		# TÍNH HƯỚNG DASH (Khác hướng di chuyển)
		var dash_dir = Vector2.ZERO
		
		# Chỉ quan tâm bóng nằm bên Trái hay Phải so với Bot
		if ball.global_position.x < global_position.x:
			dash_dir = Vector2.LEFT # Vector (-1, 0)
		else:
			dash_dir = Vector2.RIGHT # Vector (1, 0)
			
		# Gọi hàm Dash với vector ngang hoàn toàn này
		start_dash(dash_dir)

	# --- 3. XỬ LÝ VẬN TỐC (Velocity) ---
	if is_dashing:
		# Nếu đang lướt: Bay thẳng theo hướng ngang đã chốt
		velocity = dash_direction * DASH_SPEED
	else:
		# Nếu chạy thường: Chạy linh hoạt theo bóng (bao gồm cả lên xuống)
		velocity = move_direction * SPEED

	# ... (Các đoạn logic check hit và check sân giữ nguyên) ...
	if dist_to_ball < attack_range:
		perform_hit()
		change_state(State.RECOVER)
		
	if !ball_is_on_my_side():
		change_state(State.RECOVER)
		
func _process_recover_state():
	# GIAI ĐOẠN 1: ĐỨNG IM (Follow-through)
	if recovery_timer > 0:
		recovery_timer -= get_process_delta_time() # Trừ thời gian
		
		# Trong lúc này, Bot nên đứng im hoặc trôi nhẹ theo quán tính cho đẹp
		# Dùng lerp để phanh từ từ thay vì khựng lại ngay lập tức (Game Feel)
		velocity = velocity.lerp(Vector2.ZERO, 0.1) 
		return # Kết thúc hàm, không chạy đoạn dưới

	# GIAI ĐOẠN 2: THONG THẢ VỀ THỦ (Sau khi hết giờ chờ)
	
	# Tính vị trí muốn về:
	# X = Vẫn bám theo quả bóng (để sẵn sàng đỡ cú tiếp theo) -> Đây là "Move around a few pixels"
	# Y = Về Home Position (Vạch cuối sân)
	var target_x = clamp(ball.global_position.x, -300, 300) # Nhớ thay số 300 theo sân bạn
	var target_pos = Vector2(target_x, home_position.y)
	
	# Kiểm tra khoảng cách: Nếu đã gần vị trí thủ rồi thì chuyển sang IDLE luôn
	if global_position.distance_to(target_pos) < 10.0:
		velocity = Vector2.ZERO
		change_state(State.IDLE)
		return

	# Di chuyển về vị trí thủ nhưng CHẬM THÔI (70% tốc độ)
	var direction = (target_pos - global_position).normalized()
	velocity = direction * (SPEED * 0.7)

# --- HÀM HỖ TRỢ (HELPER) ---

func change_state(new_state):
	# Hàm này để chuyển trạng thái và có thể debug in ra màn hình
	current_state = new_state
	# print("Bot chuyển sang: ", State.keys()[new_state]) # Bật lên để debug

# Hàm kiểm tra: "Bóng đã sang phần sân của tao chưa?"
func ball_is_on_my_side() -> bool:
	if ball == null: return false
	
	# Vì Bot ở sân TRÊN (Y Âm), nên bóng sang sân khi Y < 0
	# (Nếu bạn đặt Bot ở sân dưới thì đổi dấu thành > 0)
	return ball.global_position.y < 0
func start_dash(dir: Vector2):
	print("Bot dùng Dash!")
	is_dashing = true
	can_dash = false
	dash_direction = dir # Chốt hướng lướt (không bẻ lái khi đang lướt)
	
	# Tạo Timer để kết thúc Dash sau 0.2s
	get_tree().create_timer(DASH_DURATION).timeout.connect(func(): is_dashing = false)
	
	# Tạo Timer để hồi chiêu sau 2.0s
	get_tree().create_timer(DASH_COOLDOWN).timeout.connect(func(): can_dash = true) 
# Hàm Dự Đoán Tương Lai (Predictive Logic)
func predict_ball_landing_x() -> float:
	# Nếu bóng không tồn tại hoặc đứng yên -> Trả về vị trí hiện tại
	if ball == null or ball.linear_velocity.length() < 10:
		return ball.global_position.x
		
	# 1. Tính khoảng cách dọc (Y) từ bóng đến Bot
	# (Giả sử Bot luôn thủ ở home_position.y)
	var dist_y = home_position.y - ball.global_position.y
	
	# 2. Tính thời gian bóng bay tới đó
	# Thời gian = Quãng đường / Vận tốc (theo trục Y)
	# Lưu ý: Cần trị tuyệt đối (abs) và tránh chia cho 0
	if abs(ball.linear_velocity.y) < 1.0: return ball.global_position.x
	
	var time_to_reach = dist_y / ball.linear_velocity.y
	
	# Nếu thời gian âm (Bóng đang bay xa khỏi Bot) -> Không cần đoán, cứ nhìn bóng thôi
	if time_to_reach < 0:
		return ball.global_position.x
		
	# 3. Tính vị trí X tương lai
	# X tương lai = X hiện tại + (Vận tốc X * Thời gian)
	var predicted_x = ball.global_position.x + (ball.linear_velocity.x * time_to_reach)
	
	return predicted_x
