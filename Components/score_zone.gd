class_name ScoreZone extends Area2D

# Định nghĩa ai sở hữu vùng này
enum ZoneOwner { PLAYER, BOT }

# Mặc định là vùng của Bot (Nếu bóng vào đây -> Player ghi điểm)
@export var zone_owner: ZoneOwner = ZoneOwner.BOT

# Signal gửi đi gồm: Ai vừa bị lọt lưới?
signal ball_entered_zone(owner_type)

func _ready() -> void:
	# Kết nối sự kiện có vật thể bay vào vùng
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Kiểm tra xem vật đó có phải là Bóng không (dựa vào Group "ball" trong slime_ball.tscn)
	if body.is_in_group("ball"):
		print("Bóng đã lọt lưới của: ", ZoneOwner.keys()[zone_owner])
		ball_entered_zone.emit(zone_owner)
