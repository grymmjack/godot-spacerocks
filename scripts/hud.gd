extends Node

signal start_game

@export var life_scene : PackedScene

@onready var lives_counter = $MarginContainer/VBoxContainer/HBoxContainer/LivesCounter.get_children()
@onready var lives_container = $MarginContainer/VBoxContainer/HBoxContainer/LivesCounter
@onready var score_label = $MarginContainer/VBoxContainer/HBoxContainer/ScoreLabel
@onready var message = $VBoxContainer/Message
@onready var start_button = $VBoxContainer/StartButton
@onready var shield_bar = $MarginContainer/VBoxContainer/ShieldContainer/ShieldBar
@onready var charged_shot_bar = $MarginContainer/VBoxContainer/ChargeShotContainer/ChargedShotBar

var free_guy_ready = true
var shot_level = 0 : set = update_charged_shot
var prev_free_guy_score = 0

var bar_textures = {
	"green": preload("res://assets/bar_green_200.png"),
	"yellow": preload("res://assets/bar_yellow_200.png"),
	"red": preload("res://assets/bar_red_200.png")
}


func _ready():
	start_button.grab_focus()


func show_message(text):
	message.text = text
	message.show()
	$Timer.start()


func update_charged_shot(value):
	shot_level = value
	var tw = get_tree().root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(charged_shot_bar, "tint_over", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	tw.chain().tween_property(charged_shot_bar, "value", shot_level, 0.2)
	tw.play()
	await tw.finished
	match value:
		1:
			$/root/Main/Player/ChargedShotLevel1Sound.play()
		2:
			$/root/Main/Player/ChargedShotLevel2Sound.play()
		3:
			$/root/Main/Player/ChargedShotLevel3Sound.play()
	tw.stop()
	tw.tween_property(charged_shot_bar, "tint_over", Color(0.5, 0.5, 0.5, 1.0), 0.2)
	tw.play()
	await tw.finished

func update_shield(value):
	shield_bar.texture_progress = bar_textures["green"]
	if value < 0.4:
		shield_bar.texture_progress = bar_textures["red"]
	elif value < 0.7:
		shield_bar.texture_progress = bar_textures["yellow"]
	shield_bar.value = value


func update_score(value):
	# Free guy every 1000 points
	if $/root/Main/Player.lives + 1 <= 10:
		if value >= 1000 and free_guy_ready:
			if value % 1000 in range(0, 100):
				prev_free_guy_score = value
				free_guy_ready = false
				var l = life_scene.instantiate()
				$MarginContainer/VBoxContainer/HBoxContainer/LivesCounter.add_child(l)
				$/root/Main/FreeGuySound.play()
				$/root/Main/Player.lives += 1
				$/root/Main/Player.shield += 50
				$FreeGuyTimer.stop()
				$FreeGuyTimer.start()
	score_label.text = str(value)


func add_lives(value):
	$/root/Main/Player.lives = value
	for i in range(min(value, 10)):
		var l = life_scene.instantiate()
		lives_container.add_child(l)


func update_lives(value):
	var i = 0
	for item in lives_container.get_children():
		item.visible = value > i
		i += 1


func update_wave(value):
	$MarginContainer/VBoxContainer/HBoxContainer/WaveLabel.text = "  WAVE %d " % value
	$MarginContainer/VBoxContainer/HBoxContainer/WaveLabel.show()


func game_over():
	show_message("Game Over")
	await $Timer.timeout
	start_button.show()
	start_button.grab_focus()
	show_message("Space Rocks!")
	$Timer.stop()


func _on_start_button_pressed():
	start_button.hide()
	start_game.emit()


func _on_timer_timeout():
	message.hide()
	message.text = ""


func _on_free_guy_timer_timeout() -> void:
	if int(score_label.text) >= prev_free_guy_score:
		free_guy_ready = true
