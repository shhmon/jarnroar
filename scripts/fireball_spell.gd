extends Area3D

var rng = RandomNumberGenerator.new()

var hit = false
var velocity = Vector3.ZERO
var caster

@rpc("any_peer", "call_local")
func handle_hit():
	hit = true
		
	#scale = Vector3(5,5,5)
	# spawn something cool here
		
	Globals.timeout(0.2, func (): queue_free())

func init(parent):
	caster = parent

func _physics_process(delta):
	if !hit:
		look_at(transform.origin + velocity.normalized(), Vector3.UP)
		transform.origin += velocity * delta


func _on_body_entered(body):
	if body.has_method("take_damage") and not body.dead and caster and body != caster and caster.is_authority():
		var direction = -(transform.origin - body.transform.origin).normalized()
		body.take_damage.rpc(rng.randi_range(20, 25), true, direction, 30, Globals.DAMAGE_TYPE.MAGIC)
		handle_hit.rpc()

