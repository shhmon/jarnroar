extends Node2D

# Handles world and spawning of players

@export var PlayerScene : PackedScene
@export var PlayerObjects = []
@export var playersalive = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	var index = 0
	for i in GameManager.Players:
		var currentPlayer = PlayerScene.instantiate()
		currentPlayer.name = str(GameManager.Players[i].id)
		currentPlayer.set_playername(str(GameManager.Players[i].name))
		add_child(currentPlayer)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(index):
				currentPlayer.global_position = spawn.global_position
		PlayerObjects.append(currentPlayer)
		playersalive += 1
		index += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for player in PlayerObjects:
		if player.dead:
			playersalive -= 1
			#PlayerObjects.erase(player)
			#player.queue_free() # Remove player
