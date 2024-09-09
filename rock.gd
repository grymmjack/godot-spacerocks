class_name rock
extends RigidBody2D

signal exploded

var screensize = Vector2.ZERO
var size
var radius
var scale_factor = 0.2


func start(_position, _velocity, _size):
	position = _position
	size = _size
	mass = 1.5 * size
	$Sprite2D.scale = Vector2.ONE * scale_factor * size
	radius = int($Sprite2D.texture.get_size().x / 2 * $Sprite2D.scale.x)
	var shape = CircleShape2D.new()
	shape.radius = radius
	$CollisionShape2D.shape = shape
	linear_velocity = _velocity
	angular_velocity = randf_range(-PI, PI)
	$Explosion.scale = Vector2.ONE * 0.75 * size


func _integrate_forces(physics_state):
	var xform:Transform2D = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0 - radius, screensize.x + radius)
	xform.origin.y = wrapf(xform.origin.y, 0 - radius, screensize.y + radius)
	physics_state.transform = xform


func explode():
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()
	$Explosion/AnimationPlayer.play("explosion")
	$Explosion.show()
	var rock_pitch = size
	match size:
		1:
			rock_pitch = 2.0
		2:
			rock_pitch = 1.5
		3:
			rock_pitch = 0.75
		4:
			rock_pitch = 0.5
		5:
			rock_pitch = 0.4
		6:
			rock_pitch = 0.25
		_:
			rock_pitch = 1.0
	$ExplosionSound.pitch_scale = randf_range(rock_pitch, rock_pitch+0.25)
	$ExplosionSound.play()
	exploded.emit(size, radius, position, linear_velocity)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	await $Explosion/AnimationPlayer.animation_finished
	queue_free()
