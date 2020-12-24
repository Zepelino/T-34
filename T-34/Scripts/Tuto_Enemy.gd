extends KinematicBody2D

var life: int = 50

func damage(damage):
	life -= damage
	if life <= 0:
		queue_free()

func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"):
		body._damage(1, true, position)


func _on_shoot_timeout():
	var bullet = preload("res://Scenes/Entities/Bullet.tscn").instance()
	bullet.global_position = global_position
	bullet.dir = Vector2.RIGHT if $"../Player".position.x > position.x else Vector2.LEFT
	bullet.limit[0] = 7000
	bullet.limit[1] = 11000
	bullet.tuto = true
	
	$Bullets.add_child(bullet)


