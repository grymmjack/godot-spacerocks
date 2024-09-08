extends RigidBody2D

@export var engine_power:int = 500
@export var spin_power:int = 8000

var thrust:Vector2 = Vector2.ZERO
var rotation_dir:int = 0

enum { INIT, ALIVE, INVULNERABLE, DEAD }
var state = INIT


func _ready() -> void:
	change_state(ALIVE)


func change_state(new_state:int) -> void:
	match new_state:
		INIT:
			$CollisionShape2D.set_deferred("disabled", true)
		ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
		INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", true)
		DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
	state = new_state


func _process(delta: float) -> void:
	delta = delta
	get_input()


func get_input() -> void:
	thrust = Vector2.ZERO
	if state in [ DEAD, INIT ]:
		return
	if Input.is_action_pressed("thrust"):
		thrust = transform.x * engine_power
		rotation_dir = Input.get_axis("rotate_left", "rotate_right")


func _physics_process(delta: float) -> void:
	constant_force = thrust
	constant_torque = rotation_dir * spin_power
