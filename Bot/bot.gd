extends CharacterBody2D

# 1. KHAI BÁO CÁC TRẠNG THÁI (ENUM)
# Enum giống như một danh sách số thứ tự: IDLE=0, CHASE=1, RECOVER=2
enum State {
	IDLE,
	CHASE,
	RECOVER
}

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
	
	# Logic giống hệt Player
	var target_pos = Vector2.ZERO
	if bot_aim_marker != null:
		target_pos = bot_aim_marker.global_position
	else:
		# Fallback: Đánh thẳng xuống dưới (Y Dương)
		target_pos = ball.global_position + Vector2(0, 500)
	
	var hit_dir = (target_pos - ball.global_position).normalized()
	
	# Gọi hàm set_ball_direction của quả bóng (đảm bảo bóng có hàm này như bài trước)
	if ball.has_method("set_ball_direction"):
		ball.set_ball_direction(hit_dir)

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
	
	# 1. Chạy tới quả bóng
	var direction = (ball.global_position - global_position).normalized()
	velocity = direction * SPEED
	
	# 2. KIỂM TRA TẤN CÔNG (Logic mới)
	# Nếu khoảng cách tới bóng nhỏ hơn tầm vợt -> Vụt!
	if global_position.distance_to(ball.global_position) < attack_range:
		perform_hit() # Gọi hàm đánh
		change_state(State.RECOVER) # Đánh xong thì lui về thủ ngay

	# 3. Nếu bóng bay ngược về sân đối phương (Y > 0) -> Thôi không đuổi nữa
	if !ball_is_on_my_side():
		change_state(State.RECOVER)
		
func _process_recover_state():
	# Logic khi Hồi phục:
	# 1. Chạy về Home Position
	var direction = (home_position - global_position).normalized()
	velocity = direction * SPEED
	
	# 2. Nếu đã về gần đến nhà (khoảng cách < 10 pixel) -> Chuyển sang IDLE
	if global_position.distance_to(home_position) < 10.0:
		velocity = Vector2.ZERO
		change_state(State.IDLE)

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
