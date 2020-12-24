extends KinematicBody2D

var rng = RandomNumberGenerator.new()

var cannon = preload("res://Scenes/Entities/Cannon.tscn")
onready var player = get_node("../Player")

var move := Vector2()
var spd = 600
var gravity = 10
var dir: int = -1

var stage: int = 2
var STATES = {"dash": ["Left", "Right", "Stopped"], "smash": ["Waiting", "Up", "Down"], "stealthy": ["Hinding", "Hidden", "Returning"]}
var state = STATES["dash"][2]

export var life: int  = 100
export var stg1: int = 70
export var stg2: int = 40

signal Damage

var inside: bool

var wait2dash: float = 1.0

var wait2jump: float = 1.0
var stomp_times: int = 0
var stomp_limit: int

var hidden: bool
var canPlace: bool = true
var cn_times: int = 5

func _ready():
	rng.randomize()
	stomp_limit = rng.randi_range(2,5)
	for p in get_tree().get_nodes_in_group("Player"):
		add_collision_exception_with(p)
		connect("Damage",p,"_damage")

func _process(delta):
	
	if inside:
		emit_signal("Damage", 1, true, global_position)
	
	############################## dash ##################################
	if STATES["dash"].has(state) && state != STATES["dash"][2]:
		move.x = spd * dir
	elif state == STATES["dash"][2]:
		wait2dash -= delta
		if wait2dash <= 0:
			wait2dash = 1.0
			if stage == 1 && rng.randi()%100 < 40:
				state = STATES["smash"][0]
			else:
				state = STATES["dash"][0 if dir == -1 else 1]
			
	############################## Stomp cycles ########################################################
	if state == STATES["smash"][0]:
		
		wait2jump -= delta
		if wait2jump <= 0:
			wait2jump = 1.0
			state = STATES["smash"][1]
		
	elif state == STATES["smash"][1]:
		
		move.x = 0
		move.y = -5000
		if global_position.y < -1400:
			move.y = 3000
			global_position.y = -10000
			state = STATES["smash"][2]
		
	elif state == STATES["smash"][2]:
		
		move.y += gravity
		if global_position.y < -300 && abs(player.global_position.x - global_position.x) > 30:
			move.x = spd * sign(player.global_position.x - global_position.x)
		else:
			move.x = 0
		for i in get_slide_count():
			var collision = get_slide_collision(i)
			if collision != null:
				if collision.collider.is_in_group("Ground"):
					stomp_times += 1
					if stomp_times <= stomp_limit && stage == 1: 
						state = STATES["smash"][0]
					else:
						stomp_times = 0
						stomp_limit = rng.randi_range(2,5)
						state = STATES["dash"][2]
		update()
	###############################Stealthy cycles###########################################
	if state == STATES["stealthy"][0]:
		move.x = spd * dir
		if hidden:
			state = STATES["stealthy"][1]
		
	elif state == STATES["stealthy"][1]:
		move = Vector2.ZERO
		if $spawn_timer.is_stopped() && canPlace:
			if cn_times > 0:
				cn_times -= 1
				canPlace = false
				$spawn_timer.start()
			else:
				cn_times = rng.randi_range(5,12)
				dir *= -1
				state = STATES["stealthy"][2]
	elif state == STATES["stealthy"][2]:
		move.x = spd * dir
		if abs(get_viewport_rect().size.x/2 - global_position.x) < 100:
			for wall in get_tree().get_nodes_in_group("Wall"):
				remove_collision_exception_with(wall)
			state = STATES["dash"][0 if dir == -1 else 1]
	
	$CollisionShape2D.disabled = hidden

func _on_spawn_timer_timeout():
	var cn = cannon.instance()
	cn.global_position = Vector2(rng.randi()%1024, -200)
	$Cannons.add_child(cn)

func _physics_process(delta):
	move = move_and_slide(move)
	
	if STATES["dash"].has(state):
		for i in get_slide_count():
			var collision = get_slide_collision(i)
			if collision != null:
				if collision.collider.is_in_group("Wall"):
					dir *= -1
					position.x += dir
					move = Vector2.ZERO
					if stage == 2:
						var c = rng.randi()%100
						if c < 25:
							state = STATES["stealthy"][0]
							for wall in get_tree().get_nodes_in_group("Wall"):
								add_collision_exception_with(wall)
					else:
						state = STATES["dash"][2]

func damage(dano: int):
	if !hidden || state == STATES["stealthy"][1]:
		life -= dano
		$CanvasLayer/Label.text = String(life)
		if life <= 0:
			get_tree().reload_current_scene()

func _draw():
	if state == STATES["smash"][2]:
		draw_rect(Rect2(-64*2, 64*1.5, 64*4, -global_position.y + 672), Color(0,0,0,0.2))

func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"):
		inside = true

func _on_Area2D_body_exited(body):
	if body.is_in_group("Player"):
		inside = false

func _on_VisibilityNotifier2D_screen_exited():
	hidden = true

func _on_VisibilityNotifier2D_screen_entered():
	hidden = false

func _on_Switch_Timer_timeout():
	stage = choose_stage([0,1,2])

func choose_stage(stages: Array):
	var possible = stages.duplicate()
	possible.erase(stage)
	var a = rng.randi()%len(possible)-1
	return possible[a]
