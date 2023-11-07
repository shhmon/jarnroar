extends CharacterBody3D

@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var animation_tree : AnimationTree = $Pivot.get_node("Farmer/AnimationTree2")
@onready var healthbar : ProgressBar = $Pivot.get_node("Farmer/SubViewport/Healthbar")
@onready var bloodparticles : CPUParticles3D = $Pivot.get_node("Farmer/RootNode/CharacterArmature/Skeleton3D/BloodAttachment/Particles")
const FADE_RATE = 0.1
const FADE_DURATION = 5
const DMG_SCALE = 5	
const SPEED = 5
var max_health = 1000
var health = max_health
var direction : Vector3 = Vector3.ZERO
var rolling = false
var moving = false
var attacking = false
var is_dead = false

var rng = RandomNumberGenerator.new()


func timeout(duration: float, callback: Callable):
	get_tree().create_timer(duration).connect("timeout", callback)
	
func _process(delta):
	healthbar.value = health
	animate()

func take_damage(damage: int, crit: bool, direction: Vector3, knockback: int):
	#velocity = direction * knockback
	bloodparticles.emitting = true
	animation_tree["parameters/Idle/HitShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	
	health = clamp(health - damage, 0, max_health)
	show_dmg(damage, crit)
	if health == 0:
		health=max_health
		#is_dead = true
		
	
func _ready():
	animation_tree.active = true
	
func show_dmg(dmg, crit):
	var dmg_label = Label.new()
	
	var pos = Vector2(400,400)
	pos.y = pos.y + rng.randf_range(-150,150)
	pos.x = pos.x + rng.randf_range(-150,150)
	dmg_label.set_position(pos)
	
	dmg_label.text = str(dmg)
	dmg_label.scale = Vector2(DMG_SCALE*2,DMG_SCALE*2) if crit else Vector2(DMG_SCALE,DMG_SCALE)

	# add to viewport
	var viewport = $Pivot.get_node("Farmer/SubViewport")
	viewport.add_child(dmg_label)	
	
	# Remove after a while
	timeout(FADE_DURATION, func(): viewport.remove_child(dmg_label))
	for i in range(1,11):

		timeout(.3+i*FADE_RATE, func(): 	dmg_label.modulate = Color(1,1,1,1-i*FADE_RATE))
	
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
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if is_dead: return
	
	velocity.x = move_toward(velocity.x, 0, SPEED / 5)
	velocity.z = move_toward(velocity.z, 0, SPEED / 5)

	move_and_slide()
	
