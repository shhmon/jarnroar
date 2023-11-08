extends Area3D

signal exploded

var rng = RandomNumberGenerator.new()

var velocity = Vector3.ZERO
var caster

func init(parent):
	caster = parent

func _physics_process(delta):
	look_at(transform.origin + velocity.normalized(), Vector3.UP)
	transform.origin += velocity * delta


func _on_body_entered(body):
	if body.has_method("take_damage") and body != caster and caster.is_authority():
		body.take_damage.rpc(rng.randi_range(20, 25), true, Vector3.ZERO, 0, Globals.DAMAGE_TYPE.MAGIC)
		
	emit_signal("exploded", transform.origin)
	queue_free()
