extends Node

signal start_game

@onready var lives_counter = $MarginContainer/HBoxContainer/LivesCounter.get_children()
@onready var score_label = $MarginContainer/HBoxContainer/ScoreLabel
@onready var message = $VBoxContainer/Message
@onready var start_button = $VBoxContainer/StartButton
@onready var shield_bar = $MarginContainer/HBoxContainer/ShieldBar

var bar_textures = {
	"green": preload("res://assets/bar_green_200.png"),
	"yellow": preload("res://assets/bar_yellow_200.png"),
	"red": preload("res://assets/bar_red_200.png")
}


func _ready() -> void:
	start_button.grab_focus()


func show_message(text:String) -> void:
	message.text = text
	message.show()
	$Timer.start()


func update_shield(value:float) -> void:
	shield_bar.texture_progress = bar_textures["green"]
	if value < 0.4:
		shield_bar.texture_progress = bar_textures["red"]
	elif value < 0.7:
		shield_bar.texture_progress = bar_textures["yellow"]
	shield_bar.value = value


func update_score(value:int) -> void:
	# Free guy every 150 points
	if value % 150 == 0:
		$MarginContainer/HBoxContainer/LivesCounter/L3.duplicate()
		$FreeGuySound.play()
	score_label.text = str(value)


func update_lives(value:int) -> void:
	for item in 3:
		lives_counter[item].visible = value > item


func game_over() -> void:
	show_message("Game Over")
	await $Timer.timeout
	start_button.show()


func _on_start_button_pressed() -> void:
	start_button.hide()
	start_game.emit()


func _on_timer_timeout() -> void:
	message.hide()
	message.text = ""
