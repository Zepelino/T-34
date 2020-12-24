extends KinematicBody2D

var rng = RandomNumberGenerator.new()

var x_axis: float
var y_axis: float

var x_sight: float = 1
var x_s_locked: float = 1

var dir := Vector2.RIGHT
var sight := Vector2.RIGHT
var move := Vector2.ZERO
var spd: int = 350

var knockBack: int
var knockForce: int = 500

var gravity = 40
var jumpForce = -800

var shoot_time = 0
var shooting: bool

export var life: int = 3

var damaged: bool

var dash: bool
var canDash: bool = true
var dashVec := Vector2.RIGHT * spd *5
var init_Dash_Pos: Vector2
var dash_time: float = 0.0
var jumping: bool
var crouched

onready var anim = $AnimatedSprite

signal shake

var mega: float = 0
var mega_load: int = 0

func _ready():
	rng.randomize()
	for i in range(life):
		var note = TextureRect.new()
		note.texture = preload("res://Assets/Sprites/Player/hpframe1.png")
		$CanvasLayer/HP_UI/HBoxContainer.add_child(note)
		$CanvasLayer/HP_UI/HBoxContainer.move_child(note,0)

func _process(delta):
	
	if Input.is_action_just_pressed("Down") && is_on_floor():
		$Crouched.disabled = false
		$CollisionShape2D.disabled = true
		crouched = true
	elif Input.is_action_just_released("Down") || !is_on_floor():
		$Crouched.disabled = true
		$CollisionShape2D.disabled = false
		crouched = false
	
	if x_axis == 0 && y_axis < 0:
		x_sight = 0
	else:
		x_sight = x_s_locked
	sight = Vector2(x_sight, -1 if y_axis < 0 else 0).normalized()
	
	if Input.is_action_pressed("Shoot") && !dash:
		shoot(delta)
		shooting = true
	else:
		shooting = false
	
	if shooting && knockBack == 0:
		if !$Coin_pos/Sparkle.visible:
			$Coin_pos/Sparkle.show()
			$Coin_pos/Pieces.emitting = true
	else:
		if $Coin_pos/Sparkle.visible:
			$Coin_pos/Sparkle.hide()
			$Coin_pos/Pieces.emitting = false
	
	damaged()
	
	if !crouched:
		var pi4: bool = round(rad2deg(sight.abs().angle())) == 45
		$Coin_pos.position = Vector2(sight.x * (16 if !pi4 else 20 ), sight.y * (24 if !pi4 else 12) + 10.5)
	else:
		$Coin_pos.position = Vector2(23 * x_s_locked, 18.5)

func _physics_process(delta):
	
	if !dash:
		var can_move: int = 1 if !Input.is_action_pressed("Down") && !Input.is_action_pressed("Lock") || !is_on_floor() else 0
		move = Vector2(x_axis * spd * can_move + knockBack, move.y)
		move.y += gravity
		
	else:
		dash_time += delta
		move = dashVec
		knockBack = 0
		if init_Dash_Pos.distance_to(global_position) > 400 || dash_time >= 1 || is_on_wall():
			dash_over()
	
	spriteManager()
	
	if knockBack != 0:
		knockBack -= sign(knockBack) * 5
		if is_on_wall() || (knockBack <= 10 && knockBack >= -10):
			knockBack = 0
	
	if Input.is_action_just_pressed("Jump") && is_on_floor():
		move.y = jumpForce
		jumping = true
	
	move = move_and_slide_with_snap(move, Vector2.DOWN, Vector2.UP)
	
	if is_on_floor():
		knockBack = 0
		jumping = false
	elif Input.is_action_just_pressed("Down"):
		move.y += 600

func spriteManager():
	var fixed_s_a = round(rad2deg(sight.abs().angle()))
	if !dash:
		if anim.animation == "Dash":
			yield(get_tree().create_timer(0.2),"timeout")
		if jumping && knockBack == 0:
			if move.y < 10:
				var key = anim.frame
				anim.play("Jump Up %s" %[fixed_s_a])
				anim.frame = key
			else:
				anim.play("Jump Down %s" %[fixed_s_a])
		elif move.x != 0 && knockBack == 0 && is_on_floor():
			if fixed_s_a != 90:
				anim.play("Walk %s" %[fixed_s_a])
		elif knockBack != 0:
			anim.play("Damage")
		elif $Crouched.disabled && is_on_floor():
			anim.play("Idle %s" %[fixed_s_a])
		elif is_on_floor():
			anim.play("Crouched")
	else:
		anim.play("Dash")

func _input(event):
	x_axis = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	y_axis = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	
	var semi_dir = Vector2(x_axis, y_axis).normalized()
	if semi_dir.length() != 0:
		dir = semi_dir
	
	if x_axis != 0:
		anim.flip_h = x_axis < 0
		x_s_locked = x_axis
		if sign($Coin_pos.position.x) != sign(x_s_locked):
			$Dash_sprites.scale.x *= -1
	
	if Input.is_action_just_pressed("Dash") && canDash:
		knockBack = 0
		dash = true
		canDash = false
		dashVec = Vector2(-1 if x_s_locked < 0 else 1, 0) * spd * 10
		$Dash_sprites.material.set_shader_param("dir", float(sign(dashVec.x)))
		init_Dash_Pos = global_position
		$Dash_sprites.emitting = true
		$Dash_sprites/Dash_Particles.emitting = true
	
	if mega_load >= 100 && Input.is_action_just_pressed("Mega"):
		mega_shoot()

func mega_shoot():
	mega_load = 0
	$CanvasLayer/Mega_pb.value = 0
	var mega = preload("res://Scenes/Entities/Arrow.tscn").instance()
	mega.global_position = $Coin_pos.global_position
	mega.dir = sight
	mega.spd += spd
	mega.rotation = mega.dir.angle()
	get_node("Bullets").add_child(mega)
	emit_signal("shake", rng.randf_range(0.1, 0.5), 1)

func _damage(damage: int, kb: bool = false, pos := Vector2.ZERO):
	if !dash:
		if !damaged:
			damaged = true
			life -= damage
			if life <= 0:
				get_tree().reload_current_scene()
			elif $CanvasLayer/HP_UI/HBoxContainer.get_child_count() > 0:
				$CanvasLayer/HP_UI/HBoxContainer.get_child(0).queue_free()
			$Invencible_Timer.start()
			if kb:
				knockBack = knockForce if global_position.x > pos.x else -knockForce
				move.y = jumpForce

func shoot(delta):
	$Coin_pos/Sparkle.rotation = sight.angle()
	if shoot_time <= 0:
		shoot_time = 0.1
		var coin = preload("res://Scenes/Entities/Coin.tscn").instance()
		coin.global_position = $Coin_pos.global_position
		coin.dir = sight
		coin.spd += spd
		coin.rotation = sight.angle()
		get_node("Bullets").add_child(coin)
		emit_signal("shake", rng.randf_range(0.1, 0.5), 0.4)
	shoot_time -= delta

func damaged():
	if damaged:
		anim.self_modulate = Color(1,1,1,sin(deg2rad(OS.get_ticks_msec()*2))/2+0.5)
	else:
		anim.self_modulate = Color(1,1,1,1)

func _on_Invencible_timeout():
	damaged = false

func dash_over():
	dash = false
	move.y = 0
	dash_time = 0.0
	$Dash_sprites.emitting = false
	$Dash_sprites/Dash_Particles.emitting = false
	$dashTimer.start()

func _on_dashTimer_timeout():
	canDash = true

func _hit():
	mega_load += 1
	$CanvasLayer/Mega_pb.value = mega_load
