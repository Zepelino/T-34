extends KinematicBody2D

var hMove:float
var vMove:float
var spd = 300
var move:Vector2

func _physics_process(delta):
	move = Vector2(hMove,vMove).normalized()*spd
	move = move_and_slide(move)

func _input(_event):
	hMove = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	vMove = Input.get_action_strength("Down") - Input.get_action_strength("Up")
