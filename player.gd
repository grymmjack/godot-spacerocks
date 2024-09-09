extends RigidBody2D

signal lives_changed
signal shield_changed
signal dead

@export var bullet_scene : PackedScene
@export var engine_power = 800
@export var spin_power = 4000
@export var fire_rate = 0.18
@export var max_shield = 100.0
@export var shield_regen = 3.0

enum { INIT, ALIVE, INVULNERABLE, DEAD }
var state = INIT
var thrust = Vector2.ZERO
var rotation_dir = 0.0
var screensize = Vector2.ZERO
var can_shoot: = true
var reset_pos = false
var lives = 0: set = set_lives
var shield = 0: set = set_shield
var rotation_multiplier = 0
var rotation_iterations = 0

const ANGULAR_DAMP_TURBO = 1.0
const ANGULAR_DAMP_NORMAL = 4.0
const LINEAR_DAMP_TURBO = 33.0
const LINEAR_DAMP_NORMAL = 1.0


func _ready():
	change_state(INIT)
	screensize = get_viewport_rect().size
	$GunCooldown.wait_time = fire_rate


func change_state(new_state):
	match new_state:
		INIT:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
			state = INIT
		ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
			$Sprite2D.modulate.a = 1.0
			state = ALIVE
		INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
			$InvulnerabilityTimer.start()
			state = INVULNERABLE
		DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.hide()
			$EngineSound.volume_db = -80
			linear_velocity = Vector2.ZERO
			dead.emit()
			state = DEAD


func _process(delta):
	get_input(delta)
	shield += shield_regen * delta


func get_input(_delta):
	if get_tree().paused:
		return
	$Exhaust.emitting = false
	thrust = Vector2.ZERO
	if state in [ INIT, DEAD ]:
		return
	if Input.is_action_pressed("turbo_rotate"):
		angular_damp *= 0.25
		thrust = Vector2.ZERO
		linear_damp = LINEAR_DAMP_TURBO
	else:
		linear_damp = LINEAR_DAMP_NORMAL
	if Input.is_action_pressed("thrust"):
		$EngineSound.pitch_scale = randf_range(0.8, 1.5)
		$EngineSound.volume_db = 0.0
		thrust = transform.x * engine_power
		if shield - 1 > 5:
			shield -= 0.25
		$Exhaust.emitting = true
		rotation_dir = Input.get_axis("rotate_left", "rotate_right")
		if Input.is_action_just_pressed("rotate_stop"):
			rotation_dir = 0
	else:
		$EngineSound.pitch_scale = randf_range(0.8, 1.5)
		$EngineSound.volume_db = -80.0
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


func set_shield(value):
	value = min(value, max_shield)
	shield = value
	shield_changed.emit(shield / max_shield)
	if shield <= 0:
		lives -= 1
		explode()


func shoot():
	if get_tree().paused:
		return
	if state == INVULNERABLE:
		return
	can_shoot = false
	if shield - 1 > 5:
		shield -= 1
	$GunCooldown.start()
	var b = bullet_scene.instantiate()
	b.name = "Player Bullet"
	get_tree().root.add_child(b)
	b.start($Muzzle.global_transform)
	$LaserSound.pitch_scale = randf_range(0.5, 2.0)
	$LaserSound.play()


func _physics_process(_delta):
	if get_tree().paused:
		return
	constant_force = thrust
	constant_torque = rotation_dir * spin_power


func _integrate_forces(physics_state):
	if get_tree().paused:
		return
	if reset_pos:
		physics_state.transform.origin = screensize / 2
		reset_pos = false
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	physics_state.transform = xform


func set_lives(value):
	var orig_value = value
	# if getting a free guy don't set invulnerable
	if orig_value == lives + 1:
		return
	lives = value
	shield = max_shield
	lives_changed.emit(lives)
	if lives <= 0:
		change_state(DEAD)
	else:
		change_state(INVULNERABLE)


func reset():
	reset_pos = true
	$Sprite2D.show()
	lives = 3
	change_state(ALIVE)
	shield = max_shield


func _on_gun_cooldown_timeout():
	can_shoot = true


func _on_rotation_cooldown_timeout():
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


func _on_invulnerability_timer_timeout():
	change_state(ALIVE)


func _on_player_body_entered(body):
	if body.is_in_group("rocks"):
		shield -= body.size * 25
		body.explode()


func explode() -> void:
	$ExplosionSound.pitch_scale = randf_range(0.5, 2.0)
	$ExplosionSound.play()
	$Explosion.scale = Vector2(10, 10)
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	await $Explosion/AnimationPlayer.animation_finished
	$Explosion.hide()
