extends RigidBody2D

signal lives_changed
signal dead

@export var engine_power:int = 500
@export var spin_power:int = 8000
@export var bullet_scene:PackedScene
@export var fire_rate:float = 0.25

var can_shoot:bool = true
var thrust:Vector2 = Vector2.ZERO
var rotation_dir:int = 0
var rotation_multiplier:int = 0
var rotation_iterations:int = 0
var reset_pos:bool = false
var lives = 0: set = set_lives

const ANGULAR_DAMP_TURBO:float = 1.0
const ANGULAR_DAMP_NORMAL:float = 4.0
const LINEAR_DAMP_TURBO:float = 33.0
const LINEAR_DAMP_NORMAL:float = 1.0

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
	get_input(delta)


func get_input(delta: float) -> void:
	thrust = Vector2.ZERO
	if state in [ DEAD, INIT ]:
		return
	if Input.is_action_pressed("turbo_rotate"):
		angular_damp *= 0.25
		thrust = Vector2.ZERO
		linear_damp = LINEAR_DAMP_TURBO
	else:
		linear_damp = LINEAR_DAMP_NORMAL
	if Input.is_action_pressed("thrust"):
		thrust = transform.x * engine_power
		rotation_dir = Input.get_axis("rotate_left", "rotate_right")
		if Input.is_action_just_pressed("rotate_stop"):
			rotation_dir = 0
	if Input.is_action_pressed("rotate_left"):
		rotation_dir = -1
	if Input.is_action_pressed("rotate_right"):
		rotation_dir = 1
	if Input.is_action_just_pressed("rotate_stop"):
		linear_damp = LINEAR_DAMP_TURBO
		rotation_dir = 0
		rotation_iterations = 0
	if Input.is_action_just_released("rotate_stop"):
		linear_damp = LINEAR_DAMP_NORMAL
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
	if reset_pos:
		physics_state.transform.origin = screensize / 2
		reset_pos = false


func set_lives(value:int) -> void:
	lives = value
	lives_changed.emit(lives)
	if lives <= 0:
		change_state(DEAD)
	else:
		change_state(INVULNERABLE)


func reset() -> void:
	reset_pos = true
	$Sprite2D.show()
	lives = 3
	change_state(ALIVE)


func _on_gun_cooldown_timeout() -> void:
	can_shoot = true


func _on_rotation_cooldown_timeout() -> void:
	if Input.is_action_pressed("rotate_left") || Input.is_action_pressed("rotate_right"):
		if rotation_iterations % 3 == 0:
			rotation_iterations += 1
		angular_damp = clamp(angular_damp, ANGULAR_DAMP_TURBO, ANGULAR_DAMP_TURBO * rotation_iterations)
	else:
		rotation_iterations -= 1
		if rotation_iterations < 0:
			rotation_iterations = 0
		angular_damp = ANGULAR_DAMP_NORMAL
		rotation_dir = 0
