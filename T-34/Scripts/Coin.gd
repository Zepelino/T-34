extends Area2D

var dir: Vector2
var spd = 500
export var damage: int = 1
var hit: bool

export (String) var type

signal hit

func _ready():
	for p in get_tree().get_nodes_in_group("Player"):
		connect("hit", p,"_hit")
	
	if type == "Mega":
		$AnimatedSprite.play("Init")

func _physics_process(delta):
	global_position += dir * spd * delta

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()

func _exit_tree():
	if hit:
		var ce = preload("res://Scenes/Entities/Coin_explosion.tscn").instance()
		ce.global_position = global_position
		ce.rotation = (dir * -1).angle()
		ce.frames = load("res://Assets/Sprites/Player/%s_explosion.tres" %[type])
		get_parent().call_deferred("add_child", ce)
		emit_signal("hit")

func _on_Coin_body_entered(body):
	if body.is_in_group("Enemy"):
		body.damage(damage)
		hit = true
		queue_free()


func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "Init":
		$AnimatedSprite.play("Normal")
