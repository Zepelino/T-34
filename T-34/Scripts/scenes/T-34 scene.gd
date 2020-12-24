extends Node

var s_time: float = 0
var amplitude = 1

onready var cam = $Camera2D
onready var cam_pos = cam.position

func _ready():
	set_process(false)
	$Player.connect("shake", self, "_Shake")

func _process(delta):
	if s_time > 0:
		s_time -= delta
		cam.position += Vector2(cos(rad2deg(s_time)), sin(rad2deg(s_time))) * amplitude
	elif cam.position != cam_pos:
		s_time = 0
		cam.position = cam_pos
		set_process(false)

func _Shake(time: float, amp: float = 1):
	s_time = time
	amplitude = amp
	set_process(true)
