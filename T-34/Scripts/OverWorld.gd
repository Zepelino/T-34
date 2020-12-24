extends Node

var current: String

func _ready():
	for p in $Portals.get_children():
		p.connect("body_entered", self, "entered", [p.name])
		p.connect("body_exited", self, "exited")

func entered(body, name: String):
	current = name

func exited(body):
	current = ""

func _input(event):
	if Input.is_action_just_pressed("Jump") && current != "":
		print(current)
