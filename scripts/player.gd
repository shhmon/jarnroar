extends CharacterBody3D

const SPEED = 5
#const JUMP_VELOCITY = 4
const TURN_SPEED = 2
const ROTATION_SPEED = 20
const WF_PROC_RATE = 0.2 # VERY DANGEROUS INCREASE WITH CAUTION!

@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var animation_tree : AnimationTree = $Pivot.get_node("Farmer/AnimationTree2")
@onready var healthbar : ProgressBar = $Pivot.get_node("Farmer/SubViewport/Healthbar")

var crit_chance = 0.30 # 5% critchance is to weak
var health = 100
var direction : Vector3 = Vector3.ZERO
var on_floor : bool = false
var rolling = false
var moving = false
var attacking = false
var kicking = false
var is_dead = false

var rng = RandomNumberGenerator.new()


func take_damage(damage: int, crit: bool):
	health = clamp(health - damage, 0, 100)
	if health == 0: is_dead = true

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
	# Set attack to true
	attacking = true

	
	const duration = 0.3
	
	# Attack may result in  wf proc
	
	#if rng.randf() <= WF_PROC_RATE:
	#	animation_tree["parameters/RunSwing/SwingScale/scale"] = SPEED * 3.5
	#	animation_tree["parameters/Swing/SwingScale/scale"] = SPEED * 3.5
	
	# spawn hitbox
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
	
	const duration = 0.2
	
	# kick
	
	timeout(duration, func(): kicking = false)
	

func _ready():
	animation_tree.active = true
	animation_tree["parameters/Roll/RollScale/scale"] = SPEED / 2.7
	animation_tree["parameters/RunSwing/RunScale/scale"] = SPEED / 3.5
	animation_tree["parameters/Slash/StateMachine/QuickSlash1/TimeScale/scale"] = 7.5
	animation_tree["parameters/Slash/StateMachine/QuickSlash2/TimeScale/scale"] = 7.5
	animation_tree["parameters/Slash/StateMachine/QuickSlash3/TimeScale/scale"] = 7.5

func _process(delta):
	healthbar.value = health
	animate()

func animate():
	if is_dead:
		animation_tree["parameters/conditions/dead"] = true
		return
		
	moving = direction and (velocity.x or velocity.z)
	
	animation_tree["parameters/conditions/idle"] = not moving
	animation_tree["parameters/conditions/moving"] = moving
	
	animation_tree["parameters/conditions/swing"] = attacking 
	animation_tree["parameters/conditions/kick"] = kicking
	
	if moving and attacking and not animation_tree["parameters/RunSwing/OneShot/active"]:
		animation_tree["parameters/RunSwing/OneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	
	animation_tree["parameters/conditions/jump"] = rolling

func _physics_process(delta):
	if is_dead: return
	
	on_floor = is_on_floor()
	
	#print("moving: ", moving, " / rolling: ", rolling, " / attacking:", attacking)
	
	# Add the gravity.
	if not on_floor:
		velocity.y -= gravity * delta
	
	if not rolling and not attacking and not kicking:
		if Input.is_action_just_pressed("ui_accept"):
			roll()
		if Input.is_action_just_pressed("murder"):
			attack()
		if Input.is_action_just_pressed("kick"):
			kick()
			
		
	if not rolling and not kicking:
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


func _on_area_3d_body_exited(body):
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var is_crit = rng.randf() <= crit_chance
		var multiplier = 2 if is_crit else 1
		body.take_damage(rng.randi_range(10, 15) * multiplier, is_crit, transform.basis.z)
