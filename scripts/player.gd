extends RigidBody3D

@export_range(750, 2000) var force_thurst: float = 1000
@export var torgue_thrust: float = 100

@onready var init_audio: AudioStreamPlayer = $InitAudio
@onready var crash_audio: AudioStreamPlayer = $CrashAudio
@onready var success_audio: AudioStreamPlayer = $SuccessAudio
@onready var boost_audio: AudioStreamPlayer = $BoostAudio
@onready var fire_particles: GPUParticles3D = $FireParticles
@onready var left_fire_particles: GPUParticles3D = $LeftFireParticles
@onready var right_fire_particles: GPUParticles3D = $RightFireParticles
@onready var success_particles: GPUParticles3D = $SuccessParticles
@onready var sparks_particles: GPUParticles3D = $ExplosionNode/SparksParticles
@onready var flash_particles: GPUParticles3D = $ExplosionNode/FlashParticles
@onready var expl_fire_particles: GPUParticles3D = $ExplosionNode/ExplFireParticles
@onready var smoke_particles: GPUParticles3D = $ExplosionNode/SmokeParticles

const Status = {
	PLAYING = 0,
	CRASHED = 1,
	WON = 2
}

var direction_z: float = 0
var tween
var player_status: int = Status.PLAYING

func tween_init() -> void:
	if tween:
		tween.kill()
	tween = create_tween()

func tween_disappear() -> void:
	tween_init()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 1)

func tween_appear() -> void:
	tween_init()
	tween.set_trans(Tween.EASE_OUT_IN)
	tween.tween_property(self, "scale", Vector3(0.01, 1, 0.01), 0.01)
	tween.tween_property(self, "scale", Vector3(1, 1, 1), 0.4)

func _ready() -> void:
	boost_audio.stream.set_loop(true)
	init_audio.play()

	Input.action_release("boost")
	Input.action_release("rotate_left")
	Input.action_release("rotate_right")

	tween_appear()

func process_boost_particles(input: String, particles: GPUParticles3D) -> void:
	if Input.is_action_just_pressed(input):
		particles.emitting = true

	if Input.is_action_just_released(input):
		particles.emitting = false

func _physics_process(delta: float) -> void:
	if player_status != Status.PLAYING:
		return

	var boost_key = "boost"
	var left_key = "rotate_left"
	var right_key = "rotate_right"

	var is_boost_pressed = Input.is_action_pressed(boost_key)

	var is_key_just_pressed = Input.is_action_just_pressed(boost_key)||Input.is_action_just_pressed(left_key)||Input.is_action_just_pressed(right_key)
	var is_key_pressing_key = is_boost_pressed||Input.is_action_pressed(left_key)||Input.is_action_pressed(right_key)
	if is_key_just_pressed:
		boost_audio.play()
	if !is_key_pressing_key:
		boost_audio.stop()

	process_boost_particles(boost_key, fire_particles)
	process_boost_particles(left_key, left_fire_particles)
	process_boost_particles(right_key, right_fire_particles)

	if is_boost_pressed:
		apply_central_force(basis.y * delta * force_thurst)
	
	direction_z = Input.get_axis(left_key, right_key)
	if direction_z != 0:
		apply_torque(Vector3(0, 0, torgue_thrust * delta * - direction_z))

func stop_all_boost_emitters() -> void:
	boost_audio.stop()
	for particles in [fire_particles, left_fire_particles, right_fire_particles]:
		particles.emitting = false

func wait_play_sound(audio: AudioStreamPlayer) -> void:
	audio.play()
	await get_tree().create_timer(audio.stream.get_length()).timeout

func _load_next_level(next_level) -> void:
	if next_level:
		get_tree().change_scene_to_file(next_level)
	else:
		get_tree().quit()

func on_enter_goal(body: Node) -> void:
	player_status = Status.WON
	
	stop_all_boost_emitters()
	tween_disappear()
	success_particles.emitting = true
	await wait_play_sound(success_audio)

	_load_next_level(body.next_level_file)

func on_enter_hazard() -> void:
	player_status = Status.CRASHED

	stop_all_boost_emitters()
	for particles in [sparks_particles, flash_particles, expl_fire_particles, smoke_particles]:
		particles.emitting = true
	await wait_play_sound(crash_audio)
	
	get_tree().reload_current_scene()

func _on_body_entered(body: Node) -> void:
	if player_status != Status.PLAYING:
		return

	if body.is_in_group("Goals"):
		on_enter_goal(body)
	if body.is_in_group("Hazards"):
		on_enter_hazard()
