extends RigidBody2D

signal lives_changed
signal shield_changed
signal charged_shot_changed
signal dead

@export var bullet_scene : PackedScene
@export var charged_shot_gadget : PackedScene
@export var engine_power = 800
@export var spin_power = 7000
@export var fire_rate = 0.18
@export var max_shield = 100.0
@export var shield_regen = 8.0
@export var charged_shot_shield_regen = 4.0

const SHOT_LEVEL_0_COST = 2.0
const SHOT_LEVEL_1_COST = 10.0
const SHOT_LEVEL_2_COST = 20.0
const SHOT_LEVEL_3_COST = 30.0

enum { INIT, ALIVE, INVULNERABLE, DEAD }
var state = INIT
var thrust = Vector2.ZERO
var rotation_dir = 0.0
var screensize = Vector2.ZERO
var can_shoot = true
var shot_charging = false
var shot_level = 0
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
			$ShieldOrb.modulate.a = 0.5
			state = INIT
			$ChargedShotLevel1Timer.stop()
			$ChargedShotLevel2Timer.stop()
			$ChargedShotLevel3Timer.stop()
			$ChargedShotGadget/Level1.hide()
			$ChargedShotGadget/Level2.hide()
			$ChargedShotGadget/Level3.hide()
			shot_charging = false
		ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
			$Sprite2D.modulate.a = 1.0
			$Sprite2D.show()
			$ShieldOrb.show()
			state = ALIVE
			update_shot_level(0)
			if $/root/Main/EnemyTimer.is_stopped:
				$/root/Main/EnemyTimer.start()
		INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
			$InvulnerabilityTimer.start()
			shot_charging = false
			state = INVULNERABLE
			$ChargedShotLevel1Timer.stop()
			$ChargedShotLevel2Timer.stop()
			$ChargedShotLevel3Timer.stop()
			$ChargedShotGadget/Level1.hide()
			$ChargedShotGadget/Level2.hide()
			$ChargedShotGadget/Level3.hide()
			update_shot_level(0)
			if $/root/Main/EnemyTimer.is_stopped:
				$/root/Main/EnemyTimer.start()
		DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.hide()
			$ShieldOrb.hide()
			$EngineSound.volume_db = -80
			linear_velocity = Vector2.ZERO
			dead.emit()
			state = DEAD
			$ChargedShotLevel1Timer.stop()
			$ChargedShotLevel2Timer.stop()
			$ChargedShotLevel3Timer.stop()
			$ChargedShotGadget/Level1.hide()
			$ChargedShotGadget/Level2.hide()
			$ChargedShotGadget/Level3.hide()
			update_shot_level(0)


func _process(delta):
	get_input(delta)
	if shot_charging:
		shield += charged_shot_shield_regen * delta
	else:
		shield += shield_regen * delta


func get_input(_delta):
	if get_tree().paused:
		return
	$Exhaust.emitting = false
	thrust = Vector2.ZERO
	if state in [ INIT, DEAD ]:
		return

	# mouse handler
	if $/root/Main.aim_with_mouse == true:
		var mouse_position = get_viewport().get_mouse_position()
		var direction = (mouse_position - position).normalized()
		rotation = direction.angle()

	if Input.is_action_pressed("turbo_rotate"):
		angular_damp *= 0.25
		thrust = Vector2.ZERO
		linear_damp = LINEAR_DAMP_TURBO
	else:
		linear_damp = LINEAR_DAMP_NORMAL
	if Input.is_action_pressed("thrust"):
		if shield - 0.1 > 0:
			$EngineSound.pitch_scale = randf_range(0.8, 1.5)
			$EngineSound.volume_db = 0.0
			thrust = transform.x * engine_power
			shield -= 0.1
			$Exhaust.emitting = true
		elif shield <= 0:
			thrust = Vector2.ZERO
			$Exhaust.emitting = false
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
	# shoot logic
	if Input.is_action_just_pressed("shoot"):
		if $ChargedShotLevel1Timer.is_stopped:
			shoot()
			if shield >= SHOT_LEVEL_1_COST:
				$ChargedShotLevel1Timer.start()
				shot_charging = true
		else:
			if shield <= SHOT_LEVEL_1_COST:
				fail_charged_shot()
			shoot()
			shot_charging = false
	if Input.is_action_just_released("shoot") and can_shoot:
		$ChargedShotLevel1Timer.stop()
		$ChargedShotLevel2Timer.stop()
		$ChargedShotLevel3Timer.stop()
		shoot()
		shot_charging = false
		$ChargedShotGadget/Level1.hide()
		$ChargedShotGadget/Level2.hide()
		$ChargedShotGadget/Level3.hide()


func fail_charged_shot():
	$ChargedShotFailSound.play()


func update_shot_level(value):
	shot_level = value
	charged_shot_changed.emit(shot_level)


func set_shot_level_1():
	if Input.is_action_pressed("shoot"):
		$ChargedShotGadget/Level1.show()
		update_shot_level(1)
		$ChargedShotLevel1Timer.stop()
		$ChargedShotLevel2Timer.stop()
		$ChargedShotLevel3Timer.stop()
		if shield >= SHOT_LEVEL_2_COST:
			$ChargedShotLevel2Timer.start()


func set_shot_level_2():
	if Input.is_action_pressed("shoot"):
		$ChargedShotGadget/Level2.show()
		update_shot_level(2)
		$ChargedShotLevel1Timer.stop()
		$ChargedShotLevel2Timer.stop()
		$ChargedShotLevel3Timer.stop()
		if shield >= SHOT_LEVEL_3_COST:
			$ChargedShotLevel3Timer.start()


func set_shot_level_3():
	if Input.is_action_pressed("shoot"):
		$ChargedShotGadget/Level3.show()
		update_shot_level(3)
		$ChargedShotLevel1Timer.stop()
		$ChargedShotLevel2Timer.stop()
		$ChargedShotLevel3Timer.stop()
		shot_charging = false


func set_shield(value):
	value = min(value, max_shield)
	shield = value
	$ShieldOrb.material.set("shader_parameter/alpha", value/100)
	shield_changed.emit(shield / max_shield)
	if shield <= 0:
		lives -= 1
		lives_changed.emit(lives)
		# destroy enemy if killing player
		for enemy in get_tree().get_nodes_in_group("enemies"):
			$/root/Main/EnemyTimer.stop()
			enemy.get_node("GunCooldown").stop()
			enemy.queue_free()
		explode()


func shoot():
	if get_tree().paused:
		return
	# can't shoot if we are invulnerable
	if state == INVULNERABLE:
		return
	can_shoot = false
	var shield_cost = 1.0
	var pitch_scale = 1.0
	var bullet_scale = Vector2.ONE/2
	match shot_level:
		0:
			shield_cost = SHOT_LEVEL_0_COST
			pitch_scale = 1.0
		1:
			shield_cost = SHOT_LEVEL_1_COST
			pitch_scale = 0.8
			bullet_scale = Vector2.ONE/2 * 2
		2:
			shield_cost = SHOT_LEVEL_2_COST
			pitch_scale = 0.5
			bullet_scale = Vector2.ONE/2 * 3
		3:
			shield_cost = SHOT_LEVEL_3_COST
			pitch_scale = 0.25
			bullet_scale = Vector2.ONE/2 * 4
	if shield <= 0:
		can_shoot = false
		return
	if shield - shield_cost <= 0:
		can_shoot = false
		return
	if shield - shield_cost > 0:
		shield -= shield_cost
	$GunCooldown.start()
	var b = bullet_scene.instantiate()
	b.name = "Player Bullet"
	b.get_node("Sprite2D").scale = bullet_scale
	b.shot_level = shot_level
	get_tree().root.add_child(b)
	b.start($Muzzle.global_transform)
	$LaserSound.pitch_scale = pitch_scale
	$LaserSound.play()
	update_shot_level(0)


func _physics_process(_delta):
	if get_tree().paused:
		return
	if shield > 0:
		constant_force = thrust
	else:
		constant_force = Vector2.ZERO
	constant_torque = rotation_dir * spin_power


func _integrate_forces(physics_state):
	if get_tree().paused:
		return
	if reset_pos:
		respawn_ship(physics_state)
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	physics_state.transform = xform


func respawn_ship(physics_state):
	# TODO
	physics_state.transform.origin = screensize / 2
	reset_pos = false
	if $/root/Main/EnemyTimer.is_stopped:
		$/root/Main/EnemyTimer.start()


func set_lives(value):
	var orig_value = lives
	lives = value
	shield = max_shield
	# if getting a free guy don't set invulnerable
	if orig_value < value:
		return
	lives_changed.emit(lives)
	if lives <= 0:
		shot_charging = false
		update_shot_level(0)
		change_state(DEAD)
	else:
		shot_charging = false
		update_shot_level(0)
		change_state(INVULNERABLE)


func reset():
	reset_pos = true
	$Sprite2D.show()
	shot_charging = false
	shield = max_shield
	change_state(ALIVE)
	update_shot_level(0)


func _on_gun_cooldown_timeout():
	can_shoot = true


func _on_rotation_cooldown_timeout():
	if Input.is_action_pressed("rotate_left") || Input.is_action_pressed("rotate_right"):
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
		if state != INVULNERABLE:
			if body.size * 15 >= 100:
				shield = 5
			else:
				shield -= body.size * 15
		body.award_points = false
		body.explode(1)



func explode() -> void:
	$ExplosionSound.pitch_scale = randf_range(0.5, 2.0)
	$ExplosionSound.play()
	$Explosion.scale = Vector2(10, 10)
	$ShieldOrb.hide()
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	await $Explosion/AnimationPlayer.animation_finished
	$Explosion.hide()
	# remove enemies if player is getting killed
	for enemy in get_tree().get_nodes_in_group("enemies"):
		$/root/Main/EnemyTimer.stop()
		enemy.get_node("GunCooldown").stop()
		enemy.queue_free()
