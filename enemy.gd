extends Area2D

@export var bullet_scene:PackedScene
@export var speed:int = 150
@export var rotation_speed:int = 120
@export var health:int = 3
@export var bullet_spread:float = 0.2

@onready var paused:bool = false

var follow = PathFollow2D.new()
var target = null


func _ready() -> void:
	$Sprite2D.frame = randi() % 3
	var path = $EnemyPaths.get_children()[randi() % $EnemyPaths.get_child_count()]
	path.add_child(follow)
	follow.loop = false


func _process(delta: float) -> void:
	delta = delta
	if paused:
		$GunCooldown.paused = true
	else:
		$GunCooldown.paused = false


func _physics_process(delta: float) -> void:
	if paused:
		return
	rotation += deg_to_rad(rotation_speed) * delta
	follow.progress += speed * delta
	position = follow.global_position
	if follow.progress_ratio >= 1:
		queue_free()


func _on_gun_cooldown_timeout() -> void:
	#var shot_type:int = randi_range(1, 6)
	#if shot_type > 5:
	shoot_pulse(3, 0.15)
	#else:
		#shoot()


func shoot() -> void:
	var dir = global_position.direction_to(target.global_position)
	dir = dir.rotated(randf_range(-bullet_spread, bullet_spread))
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start(global_position, dir)
	$LaserSound.play()


func shoot_pulse(n, delay) -> void:
	for i in n:
		shoot()
		await get_tree().create_timer(delay).timeout


func take_damage(amount:int) -> void:
	health -= amount
	$AnimationPlayer.play("flash")
	$ExplosionSound.play()
	$/root/Main.score += 1
	$/root/Main/HUD.update_score($/root/Main.score)
	if health <= 0:
		explode()


func explode() -> void:
	$ExplosionSound.play()
	speed = 0
	$GunCooldown.stop()
	$CollisionShape2D.set_deferred("disabled", "true")
	$Sprite2D.hide()
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	$Explosion.scale = Vector2(5, 5)
	await $Explosion/AnimationPlayer.animation_finished
	$/root/Main.score += 25
	$/root/Main/HUD.update_score($/root/Main.score)
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("rocks"):
		return
	explode()
	body.shield -= 50
