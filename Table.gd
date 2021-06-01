extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Card1.set_frame(1)
	$Card2.set_frame(32)
	$Card3.set_frame(37)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
