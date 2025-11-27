extends RigidBody2D

@onready var slime_ball: RigidBody2D = $"."
var max_speed = 300.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	slime_ball.lock_rotation = true



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
