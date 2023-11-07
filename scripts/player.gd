extends CharacterBody3D

enum DAMAGE_TYPE { PHYS, MAGIC }

const SPEED = 5
#const JUMP_VELOCITY = 4
const TURN_SPEED = 2
const ROTATION_SPEED = 20
const WF_PROC_RATE = 0.4 # VERY DANGEROUS INCREASE WITH CAUTION!

@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var animation_tree : AnimationTree = $Pivot.get_node("Farmer/AnimationTree2")
@onready var healthbar : ProgressBar = $Pivot.get_node("Farmer/SubViewport/Healthbar")
@onready var fireball_spell = preload("res://scenes/fireball_spell.tscn")
@onready var skeleton = $Pivot/Farmer/RootNode/CharacterArmature/Skeleton3D
@onready var foot_idx = skeleton.find_bone("LowerLeg.L_end")
@onready var fireball_effect = $Pivot/Farmer/RootNode/CharacterArmature/Skeleton3D/FootAttachment/Fireball

var crit_chance = 0.30 # 5% critchance is to weak
var health = 100
var direction : Vector3 = Vector3.ZERO
var on_floor : bool = false
var rolling = false
var moving = false
var attacking = false
var kicking = false
var is_dead = false
var attack_rate = 1
var hit_counter = 0
var is_blocking = false

var rng = RandomNumberGenerator.new()

#func take_damage(damage: int, crit: bool):
	#health = clamp(health - damage, 0, 100)
	#if health == 0: is_dead = true

func timeout(duration: float, callback: Callable):
	get_tree().create_timer(duration).connect("timeout", callback)
	
func roll():
	rolling = true
	
	const duration = SPEED / 7.15
	const speed = SPEED * 3
	
	velocity.x = $Pivot.transform.basis.z.x * SPEED * 2
	velocity.z = $Pivot.transform.basis.z.z * SPEED * 2
	
	timeout(duration, func (): rolling = false)


func attack():
	
	attacking = true
	
	const duration = 0.3
	
	# Attack may result in  wf proc
	if rng.randf() <= WF_PROC_RATE:
		animation_tree["parameters/Slash/QuickBlend/blend_amount"] = 1
	
	# Reset flags after duration
	timeout(duration,
		func ():
			attacking = false
			animation_tree["parameters/Slash/QuickBlend/blend_amount"] = 0
	)
	
func kick():
	kicking = true
	hit_counter = 0
	
	const duration = 0.4
	
	# kick
	velocity = Vector3.ZERO
	
	timeout(duration / 2,
		func ():
			var fireball = fireball_spell.instantiate()
			get_node("/root/Main").add_child(fireball)
			var foot_position = skeleton.to_global(skeleton.get_bone_global_pose(foot_idx).origin)
			#var direction = -(transform.origin - foot_position).normalized()
			#var direction = $Pivot.rotation
			var direction = Vector3(0,0,1).rotated(Vector3(0,1,0), $Pivot.rotation.y)
			fireball.transform.origin = foot_position
			fireball.velocity = Vector3(direction.x, 0, direction.z) * 10
	)
	
	timeout(duration, func(): kicking = false)
	
func block():
	is_blocking = true
	const duration = 0.6
	velocity = Vector3.ZERO
	
	timeout(duration, func(): is_blocking = false)
	

func _ready():
	animation_tree.active = true
	animation_tree["parameters/Roll/RollScale/scale"] = SPEED / 2.7 # roll
	animation_tree["parameters/RunSwing/RunScale/scale"] = SPEED / 3.5 # run
	
	animation_tree["parameters/Slash/SwingScale/scale"] = 2.5 # swing
	animation_tree["parameters/RunSwing/RunSwingScale/scale"] = 2.5 # run swing
	animation_tree["parameters/Kick/TimeScale/scale"] = 2
	
	animation_tree["parameters/Block/BlockScale/scale"] = 2
	
	# Windfury
	animation_tree["parameters/Slash/StateMachine/QuickSlash1/TimeScale/scale"] = 7.5
	animation_tree["parameters/Slash/StateMachine/QuickSlash2/TimeScale/scale"] = 7.5
	animation_tree["parameters/Slash/StateMachine/QuickSlash3/TimeScale/scale"] = 7.5
	animation_tree["parameters/Slash/StateMachine/QuickSlash3/TimeScale/scale"] = 7.5
	

func _process(delta):
	healthbar.value = health
	animate()

func animate():
	if is_dead:
		animation_tree["parameters/conditions/dead"] = true
		return
	
	var charge_state = 0.01#(hit_counter / 3) / 10
	fireball_effect.visible = hit_counter >= 3
	fireball_effect.scale = Vector3(charge_state,charge_state,charge_state)
	
	
	moving = direction and (velocity.x or velocity.z)
	animation_tree["parameters/conditions/blocking"] = is_blocking
	
	animation_tree["parameters/conditions/idle"] = not moving
	animation_tree["parameters/conditions/moving"] = moving
	
	animation_tree["parameters/conditions/swing"] = attacking 
	animation_tree["parameters/conditions/kick"] = kicking
	
	if moving and attacking and not animation_tree["parameters/RunSwing/OneShot/active"]:
		animation_tree["parameters/RunSwing/OneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	
	animation_tree["parameters/conditions/jump"] = rolling

func _physics_process(delta):
		# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if is_dead: return
	
	on_floor = is_on_floor()
	
	#print("moving: ", moving, " / rolling: ", rolling, " / attacking:", attacking)
	
	if not rolling and not attacking and not kicking:
		if Input.is_action_just_pressed("ui_accept"):
			roll()
		if Input.is_action_just_pressed("murder"):
			attack()
		if Input.is_action_just_pressed("kick") and hit_counter >= 3:
			kick()
		if Input.is_action_just_pressed("block"):
			block()
			
		
	if not rolling and not kicking and not is_blocking:
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			
			$Pivot.rotation.y = lerp_angle($Pivot.rotation.y, atan2(direction.x, direction.z), delta * ROTATION_SPEED)
				
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func _on_area_3d_body_entered(body):
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		hit_counter += 1
		var is_crit = rng.randf() <= crit_chance
		var multiplier = 2 if is_crit else 1
		var direction = -(transform.origin - body.transform.origin).normalized()
		body.take_damage(rng.randi_range(10, 15) * multiplier, is_crit, Vector3(direction.x, 0, direction.z), 30, DAMAGE_TYPE.PHYS)
