extends Node2D

# --- KẾT NỐI (DEPENDENCIES) ---
@export_group("Game Objects")
@export var player: CharacterBody2D
@export var bot: CharacterBody2D
@export var ball: RigidBody2D
@export var score_zones_container: Node2D

@export_group("UI References")
@export var player_score_label: Label  # Kéo Label điểm Player vào đây
@export var bot_score_label: Label     # Kéo Label điểm Bot vào đây
@export var winner_label: Label        # Kéo cái dòng chữ WINNER vào đây

# --- CẤU HÌNH ---
const WIN_SCORE = 5 # Luật chơi: Ai lên 5 trước thì thắng
var player_score = 0
var bot_score = 0

# Trạng thái game
var spawn_player: Vector2
var spawn_bot: Vector2
var spawn_ball: Vector2
var is_round_active: bool = true 

func _ready() -> void:
	if not player or not ball or not score_zones_container:
		push_error("❌ LỖI: Thiếu node trong Inspector!")
		return
	
	# Lưu vị trí gốc
	spawn_player = player.global_position
	spawn_bot = bot.global_position
	spawn_ball = ball.global_position
	
	# Ẩn bảng Winner đi
	if winner_label: winner_label.visible = false
	
	update_ui()
	connect_score_zones()

func connect_score_zones():
	for zone in score_zones_container.get_children():
		if zone.has_signal("ball_entered_zone"):
			if not zone.ball_entered_zone.is_connected(_on_zone_triggered):
				zone.ball_entered_zone.connect(_on_zone_triggered)

# --- LOGIC GHI ĐIỂM ---

func _on_zone_triggered(owner_type):
	if not is_round_active: return
	
	is_round_active = false # Khóa game lại
	print("⚽ Bóng vào lưới của: ", owner_type)
	
	# Chờ 1 chút cho bóng bay đi
	await get_tree().create_timer(1.0).timeout
	
	# Xử lý điểm số
	# owner_type: 0 = PLAYER (Player lọt lưới -> Bot ăn điểm)
	# owner_type: 1 = BOT (Bot lọt lưới -> Player ăn điểm)
	
	if owner_type == ScoreZone.ZoneOwner.BOT:
		# Bóng vào lưới Bot -> Player ghi điểm
		player_score += 1
		print("Player ghi bàn! Tỉ số: ", player_score, "-", bot_score)
	else:
		# Bóng vào lưới Player -> Bot ghi điểm
		bot_score += 1
		print("Bot ghi bàn! Tỉ số: ", player_score, "-", bot_score)
	
	update_ui()
	check_match_result()

func check_match_result():
	# Kiểm tra xem ai đã thắng chưa
	if player_score >= WIN_SCORE:
		end_match("PLAYER WINS!")
	elif bot_score >= WIN_SCORE:
		end_match("BOT WINS!")
	else:
		# Chưa ai thắng -> Chơi hiệp tiếp theo
		reset_round()

func end_match(winner_text: String):
	print("🏆 TRẬN ĐẤU KẾT THÚC: ", winner_text)
	
	# Hiển thị thông báo thắng
	if winner_label:
		winner_label.text = winner_text
		winner_label.visible = true
		
		# Hiệu ứng nhấp nháy cho vui (Tween)
		var tween = create_tween().set_loops()
		tween.tween_property(winner_label, "scale", Vector2(1.2, 1.2), 0.5)
		tween.tween_property(winner_label, "scale", Vector2(1.0, 1.0), 0.5)
	
	# Sau 3 giây thì tự động chơi lại từ đầu (Hoặc hiện nút Replay)
	await get_tree().create_timer(3.0).timeout
	restart_game()

func restart_game():
	player_score = 0
	bot_score = 0
	if winner_label: winner_label.visible = false
	update_ui()
	reset_round()

func reset_round():
	# Reset vị trí như cũ
	player.global_position = spawn_player
	player.velocity = Vector2.ZERO
	if player.has_method("end_dash"): player.end_dash()
	
	bot.global_position = spawn_bot
	bot.velocity = Vector2.ZERO
	if bot.get("current_state") != null: bot.set("current_state", 0) # IDLE
	
	# Reset Bóng
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0.0
	PhysicsServer2D.body_set_state(
		ball.get_rid(),
		PhysicsServer2D.BODY_STATE_TRANSFORM,
		Transform2D(0.0, spawn_ball)
	)
	if ball.get("is_spin_active") != null: ball.set("is_spin_active", false)

	# Mở khóa game
	await get_tree().create_timer(0.5).timeout
	is_round_active = true

func update_ui():
	if player_score_label: player_score_label.text = str(player_score)
	if bot_score_label: bot_score_label.text = str(bot_score)
