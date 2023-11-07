extends Area3D

enum DAMAGE_TYPE { PHYS, MAGIC }

signal exploded

var rng = RandomNumberGenerator.new()

var velocity = Vector3.ZERO

func _physics_process(delta):
	look_at(transform.origin + velocity.normalized(), Vector3.UP)
	transform.origin += velocity * delta


func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(rng.randi_range(20, 25), true, Vector3.ZERO, 0, DAMAGE_TYPE.MAGIC)
		
	emit_signal("exploded", transform.origin)
	queue_free()
