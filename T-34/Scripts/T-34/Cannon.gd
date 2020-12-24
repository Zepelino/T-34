extends Sprite

var player

var state = 0
var time: float = 1.0
var rtrn_time: float = time
var instancied: bool

var spd: int = 600

func _ready():
	for p in get_tree().get_nodes_in_group("Player"):
		player = p

func _process(delta):
	if state == 0:
		if global_position.y < 0:
			global_position.y += delta * spd
		else:
			if !instancied:
				rotation = lerp_angle(rotation, global_position.angle_to_point(player.global_position) + PI, delta * 10)
			rtrn_time -= delta
			if !instancied && rtrn_time <= time/2:
				emit()
				instancied = true
				var bullet = preload("res://Scenes/Entities/Bullet.tscn").instance()
				bullet.global_position = $Position2D.global_position
				bullet.rotation = rotation
				bullet.dir = Vector2(cos(rotation), sin(rotation))
				
				get_parent().add_child(bullet)
			elif rtrn_time <= 0:
				state = 1
	elif state == 1:
		global_position.y -= delta * spd
		if global_position.y < -200:
			get_node("../../").canPlace = true
			queue_free()
	

func emit():
	$CPUParticles2D.emitting = true
	yield(get_tree().create_timer(0.1), "timeout")
	$CPUParticles2D.emitting = false

func _on_Area2D_area_entered(area):
	if area.is_in_group("Coins"):
		get_node("../../").damage(area.damage)
		area.hit = true
		area.queue_free()
