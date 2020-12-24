extends Area2D

var dir: Vector2

var tuto: bool
var limit: Array = [0,0]

func _process(delta):
	global_position += dir * delta * 1600
	if tuto && (global_position.x > limit[1] || global_position.x < limit[0]):
		queue_free()

func _on_VisibilityNotifier2D_screen_exited():
	if !tuto:
		queue_free()
	

func _on_Bullet_body_entered(body):
	if body.is_in_group("Player") && !body.dash:
		body._damage(1)
		queue_free()
