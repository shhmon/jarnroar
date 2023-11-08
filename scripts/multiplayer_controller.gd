extends Control

#Actual entry point of game - main
const MAX_PLAYERS = 4

var address
@export var PORT = "8000"
var peer
var scene = load("res://scenes/main.tscn")
var scene_object = null

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#if scene_object != null:
		#if scene_object.playersalive <= 1:
			
			#var winner
			
			#for i in Players:
			#	if Players[i].health > 0:
			#		winner = Players[i]
					
			#print(winner)
			#$WinnerButton.text = "WINNER\n" + str(winner)
			#RestartGame.rpc()

# This gets called on the server and the clients 
func peer_connected(id):
	print("Player connected: " + str(id))


func peer_disconnected(id):
	print("Player disconnected: " + str(id))


# Only called on client side
func connected_to_server():
	print("Successfully connected to server")
	SendPlayerInformation.rpc_id(1, $UsernameLabel/Username.text, multiplayer.get_unique_id())


# Only called on client side
func connection_failed():
	print("Connection failed")


@rpc("any_peer")
func SendPlayerInformation(name, id):
	if GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": name,
			"id": id,
			"health": 100,
		}
		print("SendPlayerInformation: Added player " + str(name) + " "+ str(id))

	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)
			
	UpdateLobbyInfo()

@rpc("any_peer")
func UpdateLobbyInfo():
	#Use GameManager object
	$LobbyLabel.text = "Lobby: " + str(len(GameManager.Players)) + " / " + str(MAX_PLAYERS) + " Players"
	
	var playernamestr = ""
	for i in GameManager.Players:
		playernamestr += str(GameManager.Players[i].name) + "\n"
		
	$LobbyLabel/LobbyInfo.text = playernamestr
		

@rpc("any_peer", "call_local")
func StartGame():
	# Instantiate world
	#if scene_object != null:
		
	scene_object = scene.instantiate()
	get_tree().root.add_child(scene_object)
	self.hide()

@rpc("any_peer", "call_local")
func RestartGame():
	print("Called restartgame")
	if scene_object != null:
		scene_object.queue_free()
	#$WinnerButton.show()
	#$WinnerButton/Timer.start(3)
	self.show()

func _on_host_button_button_down():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(int(PORT), MAX_PLAYERS)
	if error != OK:
		print("Cannot host: " + str(error))
		return
		
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER) #Can use other compression schemes
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for players...")
	$HostButton/HostingStatus.text = "HOSTING ON " + $MyIPAddressLabel.local_ip
	
	SendPlayerInformation($UsernameLabel/Username.text, multiplayer.get_unique_id())

func _on_join_button_button_down():
	peer = ENetMultiplayerPeer.new()
	address = $IPAddressLabel/IPAddress.text
	print("Connecting to " + str(address))
	peer.create_client(address, int(PORT))
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER) #Can use other compression schemes
	multiplayer.set_multiplayer_peer(peer)

func _on_start_game_button_down():
	StartGame.rpc()

func _on_start_game_button_button_down():
	pass # Replace with function body.
