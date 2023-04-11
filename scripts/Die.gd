extends Node3D


const SQRT_2 = sqrt(2)

const UP = 0
const DOWN = 1
const RIGHT = 2
const LEFT = 3

const dirs = [
	Vector3(0.0, 0.0, -1.0),
	Vector3(0.0, 0.0, 1.0),
	Vector3(1.0, 0.0, 0.0),
	Vector3(-1.0, 0.0, 0.0),
]

const STEP_SOUNDS = [
	preload("res://sounds/step1.wav"),
	preload("res://sounds/step2.wav"),
	preload("res://sounds/step3.wav"),
	preload("res://sounds/step4.wav"),
	preload("res://sounds/step5.wav"),
	preload("res://sounds/step6.wav")
]

@export_range(0.0, 4.0) var step_speed = 4.0
@export var death_speed = 2.0
@export var death_fall_speed = 20.0
@export var death_fall_start = 10.0
@export var respawn_time = 0.5

var steps = 0:
	set(s):
		if s > steps:
			$AnimationPlayer.play("ChangeSteps", -1, 2.0)
		steps = s
		%StepCount.text = str(steps)
var step_progress = 0.0
var step_dir = UP
@onready var start_pos = position
@onready var start_rot = rotation
@onready var pos = position
var next_level = ""
var dead = false
var death_anim = 0.0
var steps_taken = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	%die.rotation = rotation
	rotation = Vector3(0.0, 0.0, 0.0)
	$SpringArm3D/Camera3D.make_current()


func get_num_steps():
	var up = %die.transform.basis.y.y
	var right = %die.transform.basis.x.y
	var forward = %die.transform.basis.z.y
	if up > 0.9:
		return 1
	if up < -0.9:
		return 6
	if right > 0.9:
		return 4
	if right < -0.9:
		return 3
	if forward > 0.9:
		return 2
	if forward < -0.9:
		return 5
	return 0


func play_sound(stream):
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.unit_db = 5.0
	player.finished.connect(player.queue_free)
	player.process_mode = PROCESS_MODE_ALWAYS
	player.position = position
	get_parent().add_child(player)
	player.play()


func _process(delta):
	var space_state = get_world_3d().direct_space_state
	if steps > 0:
		# Move towards next step
		var last_step_progress = step_progress
		step_progress = min(step_progress + delta * step_speed, 1.0)
		var step_delta = step_progress - last_step_progress
		var dir = dirs[step_dir]
		var target_pos = pos + dir * 2
		position.x = lerp(pos.x, target_pos.x, step_progress)
		position.z = lerp(pos.z, target_pos.z, step_progress)
		%die.position.y = (0.5 - absf(step_progress - 0.5)) * SQRT_2 * 0.5
		%die.rotate(Vector3(dir.z, 0.0, -dir.x).normalized(), PI * step_delta * 0.5)
		
		if step_progress == 1.0:
			pos = pos + dirs[step_dir] * 2
			steps -= 1
			step_progress = 0.0
			
			var sound_ind = get_num_steps() - 1
			
			# Check if off the level
			var parameters = PhysicsRayQueryParameters3D.new()
			parameters.from = position
			parameters.to = position - Vector3(0.0, 1.0, 0.0)
			var intersection = space_state.intersect_ray(parameters)
			if intersection.is_empty():
				steps = 0
				death_anim = 0.0
				dead = true
			elif intersection.collider.is_in_group("pickup"):
				steps += intersection.collider.amount
				if steps < 0:
					steps = 0
				play_sound(STEP_SOUNDS[sound_ind])
				play_sound(STEP_SOUNDS[(sound_ind + intersection.collider.amount) % 6])
				intersection.collider.disable()
			elif intersection.collider.is_in_group("goal") and steps == 0:
				next_level = intersection.collider.level
				%MovesTaken.text = "Moves Taken: " + str(steps_taken)
				$AnimationPlayer.play("FadeInEndScreen")
				play_sound(preload("res://sounds/finish.wav"))
				%NextLevelButton.grab_focus()
				get_tree().paused = true
			else:
				play_sound(STEP_SOUNDS[sound_ind])
	else:
		if dead:
			if death_anim < 1.0:
				death_anim += delta * death_speed
				var dir = dirs[step_dir]
				position += dir * delta * step_speed
				%die.rotate(Vector3(dir.z, 0.0, -dir.x).normalized(), PI * delta * step_speed * 0.5)
				var down_vel = ((death_anim * death_fall_speed) / death_speed) + death_fall_start
				%die.position.y -= down_vel * delta
			elif death_anim < 2.0:
				death_anim = 2.0
				restart_level()
		else:
			var pressed = false
			if Input.is_action_just_pressed("ui_up"):
				step_dir = UP
				pressed = true
			if Input.is_action_just_pressed("ui_down"):
				step_dir = DOWN
				pressed = true
			if Input.is_action_just_pressed("ui_right"):
				step_dir = RIGHT
				pressed = true
			if Input.is_action_just_pressed("ui_left"):
				step_dir = LEFT
				pressed = true
			if pressed:
				steps = get_num_steps()
				steps_taken += 1


func back_to_menu():
	get_tree().paused = false
	get_tree().change_scene("res://Menu.tscn")


func to_next_level():
	if next_level:
		get_tree().paused = false
		get_tree().change_scene(next_level)


func restart_level():
	get_tree().paused = false
	pos = start_pos
	steps_taken = 0
	$HUD/EndingHUD.visible = false
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_parallel(true)
	tween.tween_property(%die, "position", Vector3(0.0, 0.0, 0.0), respawn_time)
	tween.tween_property(%die, "rotation", start_rot, respawn_time)
	tween.set_parallel(false)
	tween.tween_property(self, "position", start_pos, respawn_time)
	tween.finished.connect(func(): dead = false)
	tween.play()
	for p in get_tree().get_nodes_in_group("pickup"):
		p.enable()
