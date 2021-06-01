extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Face.set_frame(5)
	$Emoticon.visible = false
	$Hand/Card1.set_frame(53)
	$Hand/Card2.set_frame(53)
	$Hand/Card3.set_frame(53)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
