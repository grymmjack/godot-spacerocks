extends Area2D

@export var speed = 800
@export var damage = 35

func start(_pos, _dir):
	position = _pos
	rotation = _dir.angle()

func _process(delta):
	if get_tree().paused:
		return
	position += transform.x * speed * delta

func _on_body_entered(body):
	if body.name == "Player":
		if body.state != body.INVULNERABLE:
			body.shield -= damage
			$/root/Main/ExplosionSound.volume_db = -6
			$/root/Main/ExplosionSound.play()
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
