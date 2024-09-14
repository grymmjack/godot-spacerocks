extends Node

@export var rock_scene : PackedScene
@export var enemy_scene : PackedScene
@export var screen_fx : PackedScene
@export var aim_with_mouse = false : set = setup_mouse

var screensize = Vector2.ZERO
var level = 0
var score = 0
var playing = false

const MUSIC_VOLUME = 0
const MUSIC_PAUSE_VOLUME = -80


func _ready():
	randomize()
	screensize = get_viewport().get_visible_rect().size
	$Player.hide()
	$HUD/MarginContainer.hide()
	level = 10
	roll_rocks()


func _process(_delta):
	if !playing:
		return
	if get_tree().get_nodes_in_group("rocks").size() == 0:
		new_level()


func _input(event):
	if event is InputEventMouseMotion:
		aim_with_mouse = true
		var mouse_position = get_viewport().get_mouse_position()
		$MouseCrosshair/Sprite2D.position = mouse_position


	if event.is_action_pressed("pause"):
		if !playing:
			return
		get_tree().paused = not get_tree().paused
		var message = $HUD/VBoxContainer/Message
		if get_tree().paused:
			message.text = "Paused"
			message.show()
			$Music.volume_db = MUSIC_PAUSE_VOLUME
		else:
			message.text = ""
			message.hide()
			$Music.volume_db = MUSIC_VOLUME


func setup_mouse(value):
	if value == aim_with_mouse:
		# only restart timer
		$MouseAimDisableTimer.stop()
		$MouseAimDisableTimer.start()
		return
	aim_with_mouse = value
	if aim_with_mouse == true:
		$MouseCrosshair.visible = true
	else:
		$MouseCrosshair.visible = false
	# restart timer
	$MouseAimDisableTimer.stop()
	$MouseAimDisableTimer.start()


func game_over():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	playing = false
	$HUD.game_over()
	$Music.stop()
	$Player/PlayerDeathSound.play()
	$HUD/MarginContainer/VBoxContainer/HBoxContainer/WaveLabel.hide()
	$Player.state = $Player.INIT


func new_game():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$Player.show()
	$HUD/MarginContainer.show()
	# remove any old rocks from previous game
	get_tree().call_group("rocks", "queue_free")
	# remove any old enemies from previous game
	get_tree().call_group("enemies", "queue_free")
	level = 0
	score = 0
	$HUD.update_score(score)
	$HUD.add_lives(3)
	$Player.reset()
	$HUD.show_message("Get Ready!")
	await $HUD/Timer.timeout
	playing = true
	$Music.play()


func new_level():
	$LevelupSound.play()
	$EnemyTimer.start(randf_range(5, 10))
	level += 1
	$HUD.update_wave(level)
	$Player.shield += 25
	$HUD.show_message("Wave %s" % level)
	roll_rocks()


func roll_rocks():
	var rock_roller = 0
	var rock_size = 3
	if level > 1:
		score += level
		$HUD.update_score(score)
	for i in level + 1:
		var _rock_vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(50, 150)
		rock_roller = randi_range(1, 10)
		match rock_roller:
			1:
				rock_size = 1
				_rock_vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(100, 250)
			2:
				rock_size = 2
			3,4:
				rock_size = 3
			5,6,7:
				rock_size = 4
				_rock_vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(25, 100)
			8,9:
				rock_size = 5
				_rock_vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(33, 75)
			10:
				rock_size = 6
				_rock_vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(15, 50)
			_:
				rock_size = 3
		spawn_rock(rock_size, null, Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(50, 150 + (level * 10)))


func spawn_rock(size, pos=null, vel=null):
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


func _on_rock_exploded(size, radius, pos, vel, shot_level, award_points):
	$Player.shield += 1
	match shot_level:
		0,1:
			score += 5 * size
			for offset in [ -1, 1 ]:
				var dir = $Player.position.direction_to(pos).orthogonal() * offset
				var newpos = pos + dir * radius
				var newvel = dir * vel.length() * 1.1
				if size >= 2:
					spawn_rock(size - 1, newpos, newvel)
		1:
				score += 15 * size
				$Player.shield += 5
				$ChargedShotLevel1ExplodeSound.play()
		2:
			score += 25 * size
			$Player.shield += 10
			for offset in [ 1 ]:
				var dir = $Player.position.direction_to(pos).orthogonal() * offset
				var newpos = pos + dir * radius
				var newvel = dir * vel.length() * 1.1
				if size - 2 > 1:
					$ChargedShotLevel2ExplodeSound.play()
					if size >= 3:
						spawn_rock(size - 2, newpos, newvel)
		3,4,5,6,7,8,9,10:
			score += 40 * size
			$Player.shield = $Player.max_shield
			$ChargedShotLevel3ExplodeSound.play()
	if $Player.state != $Player.DEAD && award_points:
		$HUD.update_score(score)


func _on_enemy_timer_timeout():
	if get_tree().paused:
		return
	if level > 1:
		var e = enemy_scene.instantiate()
		add_child(e)
		e.target = $Player
		$EnemyTimer.start(randf_range(20, 40))


func _on_player_charged_shot_changed(shot_level):
	$HUD.shot_level = shot_level


func _on_mouse_aim_disable_timer_timeout() -> void:
	aim_with_mouse = false
