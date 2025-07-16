# laser_beam.gd (Versi Final yang Sudah Diperbaiki)
extends RayCast2D

# --- Variabel Pengaturan ---
@export_group("Beam Stats")
@export var damage_per_second := 30.0
@export var max_length := 1400.0

@export_group("Beam Timings")
@export var charge_duration := 3.0
@export var firing_duration := 4.0
@export var end_duration := 1.0

@export_group("Beam Visuals")
@export var max_width_multiplier := 2.5

# --- State Machine ---
enum State { IDLE, CHARGING, FIRING, ENDING }
var current_state = State.IDLE

# --- Referensi Node ---
@onready var fill: Line2D = $FillLine2D
@onready var casting_particles := $CastingParticles2D
@onready var collision_particles := $CollisionParticles2D
@onready var beam_particles := $BeamParticles2D
@onready var sfx_charge := $SfxCharge
@onready var sfx_firing := $SfxFiring
@onready var sfx_end := $SfxEnd

var base_width: float

func _ready() -> void:
	base_width = fill.width
	set_physics_process(false)
	fill.points[1] = Vector2.ZERO
	fill.width = 0

func _physics_process(_delta: float) -> void:
	cast_beam_and_damage()

func fire_full_sequence():
	if current_state != State.IDLE: return
	
	# --- TAHAP 1: CHARGING ---
	current_state = State.CHARGING
	print("Beam is charging...")
	sfx_charge.play()
	casting_particles.emitting = true
	var charge_tween = create_tween()
	charge_tween.tween_property(fill, "width", base_width * 0.2, charge_duration).from(0)
	await get_tree().create_timer(charge_duration).timeout
	
	# --- TAHAP 2: FIRING ---
	if not is_queued_for_deletion():
		current_state = State.FIRING
		print("Beam is FIRING!")
		sfx_charge.stop()
		sfx_firing.play()
		beam_particles.emitting = true
		target_position = Vector2(max_length, 0)
		set_physics_process(true)
		var fire_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		fire_tween.tween_property(fill, "width", base_width * max_width_multiplier, 0.4)
		
		# <<<<<<<<<<<<<<<<<<<< BARIS PENTING YANG HILANG ADA DI SINI >>>>>>>>>>>>>>>>>>>>
		await get_tree().create_timer(firing_duration).timeout
		# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

	# --- TAHAP 3: ENDING ---
	if not is_queued_for_deletion():
		current_state = State.ENDING
		print("Beam is ending...")
		sfx_firing.stop()
		sfx_end.play()
		set_physics_process(false)
		casting_particles.emitting = false
		beam_particles.emitting = false
		collision_particles.emitting = false
		var end_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		end_tween.tween_property(fill, "width", 0, end_duration)
		await end_tween.finished

	# --- CLEANUP ---
	if not is_queued_for_deletion():
		current_state = State.IDLE
		print("Beam sequence complete.")
		queue_free()

func cast_beam_and_damage() -> void:
	var cast_point := target_position
	force_raycast_update()
	var is_hitting = is_colliding()
	collision_particles.emitting = is_hitting

	if is_hitting:
		var collider = get_collider()
		if collider and collider.has_method("take_damage"):
			collider.take_damage(damage_per_second * get_physics_process_delta_time())
		
		cast_point = to_local(get_collision_point())
		collision_particles.global_rotation = get_collision_normal().angle()
		collision_particles.position = cast_point

	fill.points[1] = cast_point
	var beam_center = cast_point * 0.5
	beam_particles.position = beam_center
	var extents = beam_particles.process_material.emission_box_extents
	extents.x = cast_point.length() * 0.5
	beam_particles.process_material.emission_box_extents = extents
