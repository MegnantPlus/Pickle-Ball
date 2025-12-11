extends Area2D

# Tín hiệu sạch sẽ, chỉ bắn ra khi BÓNG trúng đích
signal target_hit

func _ready() -> void:
	# Tự kết nối chính mình (Self-connection)
	# Khi có vật thể đi vào -> Gọi hàm _on_body_entered
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Lọc rác: Chỉ quan tâm nếu đó là quả bóng
	if body.is_in_group("ball"):
		print("Bóng trúng đích!")
		# Bắn pháo hiệu "TRÚNG RỒI" ra ngoài cho Manager biết
		target_hit.emit()
