extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Face.set_frame(4)
	$Emoticon.set_frame(22)
	$Hand/Card1.set_frame(2)
	$Hand/Card2.set_frame(38)
	$Hand/Card3.set_frame(46)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
