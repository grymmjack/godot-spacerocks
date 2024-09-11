extends Area2D

@export var speed = 1000

var velocity = Vector2.ZERO
var shot_level = 0

func start(_transform):
	transform = _transform
	velocity = transform.x * speed


func _process(delta):
	if get_tree().paused:
		return
	position += velocity * delta


func _on_bullet_body_entered(body):
	if body.is_in_group("rocks"):
		printerr("ROCK SHOT LEVEL: %d" % shot_level)
		match shot_level:
			0:
				printerr("0 - ROCK EXPLODING!")
				body.shot_level = shot_level
				body.explode(0)
				queue_free()
			1:
				printerr("1 - ROCK EXPLODING!")
				body.shot_level = shot_level
				body.explode(shot_level)
				queue_free()
			2:
				printerr("2 - ROCK EXPLODING BIGLY!")
				body.shot_level = shot_level
				body.explode(shot_level)
			3:
				printerr("3 - ROCK DESTROYED!")
				body.shot_level = shot_level
				body.explode(shot_level)


func _on_area_entered(area):
	if area.is_in_group("enemies"):
		printerr("ENEMY TAKING DAMAGE: %d" % shot_level)
		area.take_damage(1, shot_level)

		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
