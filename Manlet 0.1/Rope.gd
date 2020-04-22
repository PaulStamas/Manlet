extends TileMap


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var player_position
var hook_position

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _process(delta):
	global_position = Vector2(0,0)
	if $"/root/Global".player.hook_shot.get_class() == "Area2D":
		if $"/root/Global".hook_shot.speed != 0:
			clear()
			player_position = $"/root/Global".player.position / Vector2(2.5, 2.5)
			hook_position = $"/root/Global".hook_shot.position / Vector2(2.5, 2.5)
			var points = interpolated_line(player_position, hook_position)
			for i in len(points):
				var point = Vector2(points[i][0], points[i][1])
				set_cellv(point, 0)
		else:
			clear()
		
func interpolated_line(p0, p1):
	var points = []
	if p0 == p1:
		return(points)
	var dx = p1[0] - p0[0]
	var dy = p1[1] - p0[1]
	var N = max(abs(dx), abs(dy))
	for i in N + 1:
		var t = float(i) / float(N)
		var point = [round(lerp(p0[0], p1[0], t)), round(lerp(p0[1], p1[1], t))]
		points.append(point)
	return points

	
