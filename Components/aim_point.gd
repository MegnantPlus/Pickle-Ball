extends Area2D # Nếu AimPoint là Marker2D, hãy đổi thành Area2D hoặc thêm Area2D con
signal target_hit

func _on_body_entered(body):
	if body.is_in_group("ball"):
		target_hit.emit()
