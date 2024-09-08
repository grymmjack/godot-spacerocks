extends RigidBody2D

@export var engine_power:int = 500
@export var spin_power:int = 8000
@export var bullet_scene:PackedScene
@export var fire_rate:float = 0.25

var can_shoot:bool = true
var thrust:Vector2 = Vector2.ZERO
var rotation_dir:int = 0
var screensize:Vector2 = Vector2.ZERO

enum { INIT, ALIVE, INVULNERABLE, DEAD }
var state = INIT


func _ready() -> void:
	change_state(ALIVE)
	screensize = get_viewport_rect().size
	$GunCooldown.wait_time = fire_rate


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
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()


func shoot() -> void:
	if state == INVULNERABLE:
		return
	can_shoot = false
	$GunCooldown.start()
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start($Muzzle.global_transform)


func _physics_process(delta: float) -> void:
	constant_force = thrust
	constant_torque = rotation_dir * spin_power

func _integrate_forces(physics_state: PhysicsDirectBodyState2D) -> void:
	var xform:Transform2D = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	physics_state.transform = xform


func _on_gun_cooldown_timeout() -> void:
	can_shoot = true
