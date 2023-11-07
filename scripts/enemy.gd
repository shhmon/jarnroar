extends CharacterBody3D

@onready var animation_tree : AnimationTree = $Pivot.get_node("Farmer/AnimationTree2")
@onready var healthbar : ProgressBar = $Pivot.get_node("Farmer/SubViewport/Healthbar")

const SPEED = 5
var health = 100
var direction : Vector3 = Vector3.ZERO
var rolling = false
var moving = false
var attacking = false
var is_dead = false

func timeout(duration: float, callback: Callable):
	get_tree().create_timer(duration).connect("timeout", callback)
	
func _process(delta):
	healthbar.value = health
	animate()

func take_damage(damage: int, crit: bool, direction: Vector3):
	velocity = direction * 50
	get_node("Pivot/Farmer/RootNode/CharacterArmature/Skeleton3D/BloodAttachment/Particles").emitting = true
	animation_tree["parameters/Idle/HitShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	
	health = clamp(health - damage, 0, 100)
	
	if health == 0:
		is_dead = true
		
	
func _ready():
	animation_tree.active = true

func animate():
	if is_dead:
		animation_tree["parameters/conditions/dead"] = true
		return
		
	moving = direction and (velocity.x or velocity.z)
	
	animation_tree["parameters/conditions/idle"] = not moving
	animation_tree["parameters/conditions/moving"] = moving
		
	animation_tree["parameters/conditions/swing"] = attacking
	
	if moving and attacking and not animation_tree["parameters/RunSwing/OneShot/active"]:
		animation_tree["parameters/RunSwing/OneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	
	animation_tree["parameters/conditions/jump"] = rolling
	
func _physics_process(delta):
	if is_dead: return
	
	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
