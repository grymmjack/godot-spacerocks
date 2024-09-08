extends Area2D

@export var speed:int = 800
@export var damage:int = 15

@onready var paused:bool = false


func start(_pos, _dir):
	position = _pos
	rotation = _dir.angle()


func _process(delta: float) -> void:
	if paused:
		return
	position += transform.x * speed * delta


func _on_body_entered(body):
	if body.name == "Player":
		body.shield -= damage
		$ExplosionSound.play()
	queue_free()


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
