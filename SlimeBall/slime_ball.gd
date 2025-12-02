extends RigidBody2D


@export var constant_speed: float = 500.0

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	if linear_velocity.length_squared() > 0:
		linear_velocity = linear_velocity.normalized() * constant_speed
func set_ball_direction(direction: Vector2) -> void:
	linear_velocity = direction.normalized() * constant_speed
