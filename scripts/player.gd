extends CharacterBody3D

@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var animation_tree : AnimationTree = $Pivot.get_node("Farmer/AnimationTree2")
@onready var healthbar : ProgressBar = $Pivot.get_node("Farmer/SubViewport/Healthbar")
@onready var fireball_spell = preload("res://scenes/fireball_spell.tscn")
@onready var skeleton = $Pivot/Farmer/RootNode/CharacterArmature/Skeleton3D
@onready var foot_idx = skeleton.find_bone("LowerLeg.L_end")
@onready var fireball_effect = $Pivot/Farmer/RootNode/CharacterArmature/Skeleton3D/FootAttachment/Fireball
@onready var bloodparticles : CPUParticles3D = $Pivot.get_node("Farmer/RootNode/CharacterArmature/Skeleton3D/BloodAttachment/Particles")
@onready var camera = $Camera

var local = true

var playername = ""
var health = 100
var direction : Vector3 = Vector3.ZERO
var on_floor : bool = false
var rolling = false
var moving = false
var attacking = false
var kicking = false
var dead = false
var blocking = false
var hit_counter = 0
var skating = false

var rng = RandomNumberGenerator.new()

func timeout(duration: float, callback: Callable):
	get_tree().create_timer(duration).connect("timeout", callback) # The timer will be automatically freed after its time elapses'

func set_authority():
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	
func is_authority():
	return local or $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id()
	
func set_playername(text):
	#$PlayerName.set_text(text)
	playername = text
		
func show_dmg(dmg, crit, type: int):
	var dmg_label = Label.new()
	
	var pos = Vector2(400,400)
	pos.y = pos.y + rng.randf_range(-150,150)
	pos.x = pos.x + rng.randf_range(-150,150)
	dmg_label.set_position(pos)
	
	var color = Color(1,1,1) if type == Globals.DAMAGE_TYPE.PHYS else Color(1,1,0)
	dmg_label.text = str(dmg)
	dmg_label.modulate = color
	var scaleVector = Vector2(Globals.DMG_SCALE, Globals.DMG_SCALE)
	dmg_label.scale = scaleVector * 2 if crit else scaleVector

	# add to viewport
	var viewport = $Pivot.get_node("Farmer/SubViewport")
	viewport.add_child(dmg_label)
	
	var wr = weakref(dmg_label)
	
	# Remove after a while
	timeout(Globals.FADE_DURATION, func(): if wr.get_ref(): dmg_label.queue_free())
	
	for i in range(1,11):
		timeout(.3+i*Globals.FADE_RATE,
			func():
				if wr.get_ref():
					dmg_label.modulate = Color(1,1,color.b,1-i*Globals.FADE_RATE)
		)

@rpc("any_peer", "call_local")
func skate():
	const duration = 0.2
	
	skating = true
	
	timeout(duration, func (): skating = false)
	
@rpc("any_peer", "call_local")
func take_damage(damage: int, crit: bool, direction: Vector3, knockback: int, type: int):
	if type == Globals.DAMAGE_TYPE.PHYS and blocking:
		return
		
	velocity = direction * knockback
	
	bloodparticles.emitting = true
	animation_tree["parameters/Idle/HitShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	
	health = clamp(health - damage, 0, Globals.MAX_HEALTH)
	show_dmg(damage, crit, type)
	
	if damage > 0:
		skate.rpc()
	
	dead = health == 0
	#if health == 0:
	#	health = Globals.MAX_HEALTH

@rpc("any_peer", "call_local")
func roll():
	rolling = true
	
	var duration = Globals.SPEED / 7.15
	var speed = Globals.SPEED * 3
	
	velocity.x = $Pivot.transform.basis.z.x * Globals.SPEED * 2
	velocity.z = $Pivot.transform.basis.z.z * Globals.SPEED * 2
	
	timeout(duration, func (): rolling = false)

@rpc("any_peer", "call_local")
func attack():
	attacking = true
	
	const duration = 0.3
	
	# Attack may result in  wf proc
	if rng.randf() <= Globals.WF_PROC_RATE:
		animation_tree["parameters/Slash/QuickBlend/blend_amount"] = 1
	
	# Reset flags after duration
	timeout(duration,
		func ():
			attacking = false
			animation_tree["parameters/Slash/QuickBlend/blend_amount"] = 0
	)

@rpc("any_peer", "call_local")
func kick():
	kicking = true
	
	const duration = 0.4
	
	velocity = Vector3.ZERO
	
	timeout(duration / 2,
		func ():
			var fireball = fireball_spell.instantiate()
			fireball.init(self)
			get_node("/root/main").add_child(fireball)
			var foot_position = skeleton.to_global(skeleton.get_bone_global_pose(foot_idx).origin)
			var direction = Vector3(0,0,1).rotated(Vector3(0,1,0), $Pivot.rotation.y)
			fireball.transform.origin = foot_position
			fireball.velocity = Vector3(direction.x, 0, direction.z) * 10
			velocity = -direction * 15
			skate.rpc()
			hit_counter = 0
	)
	
	timeout(duration, func(): kicking = false)

@rpc("any_peer", "call_local")
func block():
	blocking = true
	const duration = 0.6
	velocity = Vector3.ZERO
	
	timeout(duration, func(): blocking = false)
	

func _ready():
	animation_tree.active = true
	animation_tree["parameters/Roll/RollScale/scale"] = Globals.SPEED / 2.7 # roll
	animation_tree["parameters/RunSwing/RunScale/scale"] = Globals.SPEED / 3.5 # run
	
	animation_tree["parameters/Slash/SwingScale/scale"] = 2.5 # swing
	animation_tree["parameters/RunSwing/RunSwingScale/scale"] = 2.5 # run swing
	animation_tree["parameters/Kick/TimeScale/scale"] = 2
	
	animation_tree["parameters/Block/BlockScale/scale"] = 2
	
	# Windfury
	animation_tree["parameters/Slash/StateMachine/QuickSlash1/TimeScale/scale"] = 7.5
	animation_tree["parameters/Slash/StateMachine/QuickSlash2/TimeScale/scale"] = 7.5
	animation_tree["parameters/Slash/StateMachine/QuickSlash3/TimeScale/scale"] = 7.5
	animation_tree["parameters/Slash/StateMachine/QuickSlash3/TimeScale/scale"] = 7.5
	
	set_authority()
	
	#if camera:
		#camera.transform
	
func handle_audio():
	if attacking:
		if !$SwingAudio.playing:
			$SwingAudio.play()
	else:
		$SwingAudio.stop()
	
	if moving and not rolling:
		if !$RunAudio.playing:
			$RunAudio.play()
	else:
		$RunAudio.stop()

func _process(delta):
	healthbar.value = health
	animate()
	handle_audio()
	
	if is_authority():
		$PlayerCamera.make_current()

func animate():
	if dead:
		animation_tree["parameters/conditions/dead"] = true
		return
	
	var charge_state = 0.01#(hit_counter / 3) / 10
	fireball_effect.visible = hit_counter >= 3
	fireball_effect.scale = Vector3(charge_state,charge_state,charge_state)
	
	animation_tree["parameters/conditions/blocking"] = blocking
	
	animation_tree["parameters/conditions/idle"] = not moving
	animation_tree["parameters/conditions/moving"] = moving
	
	animation_tree["parameters/conditions/swing"] = attacking 
	animation_tree["parameters/conditions/kick"] = kicking
	
	if moving and attacking and not animation_tree["parameters/RunSwing/OneShot/active"]:
		animation_tree["parameters/RunSwing/OneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	
	animation_tree["parameters/conditions/jump"] = rolling
	
@rpc("any_peer", "call_local")
func set_moving(value: bool):
	moving = value
	
@rpc("any_peer", "call_local")	
func set_hit_counter(value: int):
	hit_counter = value

func _physics_process(delta):
	if is_authority(): # Only control the right character
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta
			
		if dead:
			return
		
		on_floor = is_on_floor()
		
		#print("moving: ", moving, " / rolling: ", rolling, " / attacking:", attacking)
		
		if not rolling and not attacking and not kicking:
			if Input.is_action_just_pressed("ui_accept"):
				roll.rpc()
			if Input.is_action_just_pressed("murder"):
				attack.rpc()
			if Input.is_action_just_pressed("kick") and hit_counter >= 3:
				kick.rpc()
			if Input.is_action_just_pressed("block"):
				block.rpc()
				
			
		if not rolling and not kicking and not blocking:
			var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
			direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			
			if direction:
				
				if skating:
					var x = velocity.x + direction.x * Globals.SPEED
					var z = velocity.z + direction.z * Globals.SPEED
					
					x = clamp(x, -Globals.SPEED, Globals.SPEED)
					z = clamp(z, -Globals.SPEED, Globals.SPEED)
					
					velocity.x = move_toward(velocity.x, x, Globals.SKATE_STOP_RATE)
					velocity.z = move_toward(velocity.z, z, Globals.SKATE_STOP_RATE)
				else:
					velocity.x = direction.x * Globals.SPEED
					velocity.z = direction.z * Globals.SPEED
				
				$Pivot.rotation.y = lerp_angle($Pivot.rotation.y, atan2(direction.x, direction.z), delta * Globals.ROTATION_SPEED)
					
			else:
				velocity.x = move_toward(velocity.x, 0, Globals.SKATE_STOP_RATE if skating else Globals.SPEED)
				velocity.z = move_toward(velocity.z, 0, Globals.SKATE_STOP_RATE if skating else Globals.SPEED)
				
		set_moving.rpc(direction and (velocity.x or velocity.z))

		move_and_slide()


func _on_area_3d_body_entered(body):
	if body.has_method("take_damage") and body != self and is_authority():
		set_hit_counter.rpc(hit_counter + 1)
		var is_crit = rng.randf() <= Globals.CRIT_CHANCE
		var multiplier = 2 if is_crit else 1
		var direction = -(transform.origin - body.transform.origin).normalized()
		body.take_damage.rpc(rng.randi_range(7, 10) * multiplier, is_crit, Vector3(direction.x, 0, direction.z), 15, Globals.DAMAGE_TYPE.PHYS)
		
		
#func _input(event):
	#if event is InputEventMouseButton:
		#var position3D = $Camera.project_position(event.position, transform.origin.z) # verified
		#var vec = -(transform.origin - Vector3(position3D.x, position3D.y, 0)).normalized()
