extends Node

@export var rock_scene:PackedScene
@export var enemy_scene:PackedScene

var screensize:Vector2 = Vector2.ZERO
var level:int = 0
var score:int = 0
var playing:bool = false

const MUSIC_VOLUME = 0
const MUSIC_PAUSE_VOLUME = -80


func _ready() -> void:
	$Player.hide()
	$HUD/MarginContainer/HBoxContainer.hide()
	screensize = get_viewport().get_visible_rect().size


func _process(delta: float) -> void:
	delta = delta
	if not playing:
		return
	if get_tree().get_nodes_in_group("rocks").size() == 0:
		new_level()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if not playing:
			return
		get_tree().paused = not get_tree().paused
		var message = $HUD/VBoxContainer/Message
		if get_tree().paused:
			message.text = "Paused"
			message.show()
			$Music.volume_db = MUSIC_PAUSE_VOLUME
			var enemies = get_tree().get_nodes_in_group("enemies")
			if enemies.size() > 0:
				for enemy in enemies:
					enemy.paused = true
		else:
			message.text = ""
			message.hide()
			$Music.volume_db = MUSIC_VOLUME
			var enemies = get_tree().get_nodes_in_group("enemies")
			if enemies.size() > 0:
				for enemy in enemies:
					enemy.paused = false


func game_over() -> void:
	playing = false
	$HUD.game_over()
	$Music.stop()


func new_game() -> void:
	$Music.play()
	$Player.show()
	$HUD/MarginContainer/HBoxContainer.show()
	# remove any old rocks from previous game
	get_tree().call_group("rocks", "queue_free")
	# remove any old enemies from previous game
	get_tree().call_group("enemies", "queue_free")
	level = 0
	score = 0
	$HUD.update_score(score)
	$HUD.show_message("Get Ready!")
	$Player.reset()
	await $HUD/Timer.timeout
	playing = true


func new_level() -> void:
	# remove any old enemies from previous game
	get_tree().call_group("enemies", "queue_free")
	$LevelupSound.play()
	level += 1
	$HUD.show_message("Wave %s" % level)
	if level > 1:
		score += level
		$HUD.update_score(score)
	for i in level:
		spawn_rock(3)
	$EnemyTimer.start(randf_range(5, 10))


func spawn_rock(size, pos=null, vel=null) -> void:
	if pos == null:
		$RockPath/RockSpawn.progress = randi()
		pos = $RockPath/RockSpawn.position
	if vel == null:
		vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(50, 125)
	var r = rock_scene.instantiate()
	r.screensize = screensize
	r.start(pos, vel, size)
	call_deferred("add_child", r)
	r.exploded.connect(self._on_rock_exploded)


func _on_rock_exploded(size, radius, pos, vel) -> void:
	$ExplosionSound.play()
	score += 10 * size
	$HUD.update_score(score)
	if size <= 1:
		return
	for offset in [ -1, 1 ]:
		var dir = $Player.position.direction_to(pos).orthogonal() * offset
		var newpos = pos + dir * radius
		var newvel = dir * vel.length() * 1.1
		spawn_rock(size - 1, newpos, newvel)


func _on_enemy_timer_timeout() -> void:
	var e = enemy_scene.instantiate()
	add_child(e)
	e.target = $Player
	$EnemyTimer.start(randf_range(20, 40))
