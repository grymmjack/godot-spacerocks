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
		match shot_level:
			0:
				body.shot_level = shot_level
				body.explode(1)
				queue_free()
			1:
				body.shot_level = shot_level
				body.explode(shot_level)
				queue_free()
			2:
				body.shot_level = shot_level
				body.explode(shot_level)
			3:
				body.shot_level = shot_level
				body.explode(shot_level)


func _on_area_entered(area):
	if area.is_in_group("enemies"):
		area.take_damage(1, shot_level)
		# pierce if shot level 2, or 3
		if shot_level <= 1:
			queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
