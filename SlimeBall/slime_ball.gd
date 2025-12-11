extends RigidBody2D


@export var constant_speed: float = 500.0
# --- BIẾN CHO CƠ CHẾ XOÁY (SPIN) ---
var is_spin_active: bool = false # Đang trong trạng thái chờ xoáy?
var spin_target_pos: Vector2 = Vector2.ZERO # Điểm mốc để bắt đầu xoáy
var spin_angle_pending: float = 0.0 # Góc sẽ xoáy (15 độ)
func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
# 1. Logic duy trì tốc độ (Code cũ)
	if linear_velocity.length_squared() > 0:
		linear_velocity = linear_velocity.normalized() * constant_speed
		
		# Xoay hình ảnh theo hướng bay (Optional)
		if $AnimatedSprite2D:
			$AnimatedSprite2D.rotation = linear_velocity.angle()

	# 2. --- LOGIC KÍCH HOẠT XOÁY (DELAYED SPIN) ---
	if is_spin_active:
		# Kiểm tra xem đã bay đến gần điểm mốc chưa?
		# Dùng khoảng cách < 20 pixel (đừng để nhỏ quá kẻo bóng bay lướt qua luôn không kịp bắt)
		if global_position.distance_to(spin_target_pos) < 20.0:
			trigger_spin_effect()

# Hàm kích hoạt xoáy (Do Player gọi)
func set_spin_shot(target: Vector2, angle_deg: float) -> void:
	# Giai đoạn 1: Bay thẳng tắp đến điểm mốc
	var direction_to_target = (target - global_position).normalized()
	linear_velocity = direction_to_target * constant_speed
	
	# Lưu thông tin để dành cho Giai đoạn 2
	spin_target_pos = target
	spin_angle_pending = angle_deg
	is_spin_active = true
	print("Bóng: Đã nhận lệnh Spin! Bay tới: ", target)
# Hàm thực hiện bẻ lái (Tự gọi khi đến nơi)
func trigger_spin_effect() -> void:
	print("Bóng: Đến điểm mốc! Bẻ lái ngay!")
	is_spin_active = false
	
	# 1. Tính toán vector mới (như cũ)
	var new_velocity = linear_velocity.rotated(deg_to_rad(spin_angle_pending))
	
	# 2. --- VAN AN TOÀN (SAFETY CLAMP) ---
	# Mục tiêu: Bóng PHẢI bay lên phía trên (Y < 0)
	# Nếu sau khi xoay mà Y > 0 (bay ngược về) hoặc Y = 0 (bay ngang)
	# Ta sẽ ép nó phải có một chút độ dốc hướng lên.
	
	if new_velocity.y >= -150.0: # -100 là ngưỡng an toàn (hơi dốc lên)
		# Ép Y thành số âm (bay lên)
		# Giữ nguyên chiều X, chỉ sửa chiều Y
		new_velocity.y = -200.0 # Hoặc lấy -abs(new_velocity.y)
		
		# Chuẩn hóa lại để giữ đúng tốc độ (không bị chậm đi do sửa Y)
		new_velocity = new_velocity.normalized() * constant_speed
		
		print("⚠️ Safety Valve Triggered: Đã ngăn bóng bay ngược!")
	
	# 3. Áp dụng vận tốc mới
	linear_velocity = new_velocity

# Hàm đánh thường (Reset trạng thái xoáy để tránh lỗi)
func set_ball_direction(direction: Vector2) -> void:
	is_spin_active = false # Hủy bỏ lệnh xoáy cũ nếu có
	linear_velocity = direction.normalized() * constant_speed
