extends Node

enum DAMAGE_TYPE { PHYS, MAGIC }

const SPEED = 5 # Player run speed
const TURN_SPEED = 2 # Player turn speed
const ROTATION_SPEED = 20 # Player rotation speed

const WF_PROC_RATE = 0.05 # VERY DANGEROUS INCREASE WITH CAUTION!
const CRIT_CHANCE = 0.3
const MAX_HEALTH = 100

# Damage numbers constants
const DMG_SCALE = 5
const FADE_DURATION = 5
const FADE_RATE = 0.1

const SKATE_DURATION = 0.5
const SKATE_STOP_RATE = float(Globals.SPEED) / 10.0

func timeout(duration: float, callback: Callable):
	get_tree().create_timer(duration).connect("timeout", callback) # The timer will be automatically freed after its time elapses'

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
