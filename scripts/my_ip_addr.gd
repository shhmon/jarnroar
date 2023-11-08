extends Label

@export var local_ip = ""
# Called when the node enters the scene tree for the first time.
func _ready():
	for address in IP.get_local_addresses():
		print(address)
		if (address.split('.').size() == 4):
			if "192.168" in address:
				local_ip=address
	self.text = "My IP: " + local_ip


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
