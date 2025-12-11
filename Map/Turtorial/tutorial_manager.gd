extends Node2D

# --- CÁC BƯỚC HƯỚNG DẪN ---
enum Step {
	START,
	MOVE_LEFT,
	FREE_MOVE,
	HIT_BALL,
	DASH_HIT,
	FINISHED
}

var current_step = Step.START
var hit_count = 0 # Đếm số lần đánh trúng đích

# --- THAM CHIẾU ---
@export var player: CharacterBody2D
@export var ball: RigidBody2D
@export var tutorial_label: Label
@export var aim_point: Node2D # Cái đích để tập đánh

# Vị trí
var start_pos_player = Vector2(500, 200) # Góc phải dưới (Bạn tự chỉnh số theo map)
var ball_spawn_pos = Vector2(0, -200) # Vị trí bóng xuất hiện

func _ready():
	# Setup ban đầu
	if player:
		player.global_position = start_pos_player
	
	if ball:
		ball.visible = false
		ball.freeze = true # Đóng băng bóng
		ball.global_position = Vector2(9999, 9999) # Giấu đi
	
	change_step(Step.START)

func _process(delta):
	# Kiểm tra điều kiện hoàn thành từng bước
	match current_step:
		Step.START:
			# Chờ người dùng sẵn sàng hoặc tự chuyển luôn
			change_step(Step.MOVE_LEFT)
			
		Step.MOVE_LEFT:
			if Input.is_action_pressed("left"):
				print("Người chơi đã đi sang trái!")
				change_step(Step.FREE_MOVE)
		
		Step.FREE_MOVE:
			# Cho di chuyển tự do 2 giây rồi hiện bóng
			pass # Logic đếm giờ xử lý ở hàm change_step

# --- HÀM CHUYỂN BƯỚC (STATE MACHINE) ---
func change_step(new_step):
	current_step = new_step
	
	match current_step:
		Step.START:
			pass
			
		Step.MOVE_LEFT:
			tutorial_label.text = "Press A to move LEFT"
			
		Step.FREE_MOVE:
			tutorial_label.text = "Use W A S D to Move around"
			# Tạo timer 3 giây để người chơi làm quen
			await get_tree().create_timer(3.0).timeout
			change_step(Step.HIT_BALL)
			
		Step.HIT_BALL:
			tutorial_label.text = "Press J to HIT the ball!"
			spawn_ball_practice()
			hit_count = 0
			
		Step.DASH_HIT:
			tutorial_label.text = "Hold SHIFT to DASH & HIT!"
			spawn_ball_practice()
			hit_count = 0 # Reset đếm để tập Dash 1-2 lần
			
		Step.FINISHED:
			tutorial_label.text = "YOU ARE READY FOR BATTLE!"
			if ball: ball.queue_free()
			# Chờ 2s rồi về Menu hoặc vào Game chính
			await get_tree().create_timer(2.0).timeout
			get_tree().change_scene_to_file("res://Menu/menu.tscn")

# --- LOGIC TẬP LUYỆN ---

func spawn_ball_practice():
	if ball:
		ball.visible = true
		ball.freeze = false
		ball.linear_velocity = Vector2.ZERO
		# Đặt bóng ở phía trên để nó rơi xuống hoặc bay về phía player
		ball.global_position = Vector2(0, -300) 
		ball.apply_impulse(Vector2(0, 200)) # Đẩy nhẹ về phía player

# Hàm này sẽ được gọi khi bóng chạm vào AimPoint (Cần setup signal)
func on_target_hit():
	if current_step == Step.HIT_BALL:
		hit_count += 1
		tutorial_label.text = "Good! " + str(hit_count) + "/3"
		spawn_ball_practice() # Reset bóng
		
		if hit_count >= 3:
			change_step(Step.DASH_HIT)
			
	elif current_step == Step.DASH_HIT:
		# Ở bước này, kiểm tra xem Player có đang Dash không
		if player.is_dashing:
			tutorial_label.text = "PERFECT DASH!"
			await get_tree().create_timer(1.0).timeout
			change_step(Step.FINISHED)
		else:
			tutorial_label.text = "Try again! Use SHIFT!"
			spawn_ball_practice()
