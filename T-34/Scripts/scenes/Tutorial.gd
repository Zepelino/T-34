extends Node

var inside: bool
var current
onready var player = $Player
onready var tween = $Tween

func _ready():
	player.add_collision_exception_with($Enemy)

func _process(delta):
	
	if inside && current.monitoring:
		player._damage(1, true, current.global_position)
	
	for texts in $Texts.get_children():
		if player.position.x > texts.rect_position.x + 300:
			if !tween.is_active():
				tween.interpolate_property(texts, "modulate", Color.white, Color.transparent, 1)
				tween.start()
		if texts.modulate.a == 0:
			texts.queue_free()
	
	if player.global_position.y > 900:
		get_tree().reload_current_scene()
	

func _on_Laser_body_entered(body):
	if body.is_in_group("Player"):
		inside = true
		current = $Laser

func _on_Barrier_body_entered(body):
	if body.is_in_group("Player"):
		inside = true
		current = $Barrier

func _on_Barrier_body_exited(body):
	inside = false

func _on_Laser_body_exited(body):
	inside = false

func _on_Timer_timeout():
	$Laser.monitoring = !$Laser.monitoring
	$Laser/ColorRect.visible = $Laser.monitoring
