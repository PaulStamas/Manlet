extends Node

var time = 0.0
var max_time = 0.0

func _init(max_time):
    self.max_time = max_time
    self.time = max_time

func tick(delta):
    time = max(time + delta, 0)

func is_ready():
	print(time)
	if time >= max_time:
		time = 0
		return true
	return false
	
func set_duration(duration):
	max_time = duration
	
func reset():
	time = 0