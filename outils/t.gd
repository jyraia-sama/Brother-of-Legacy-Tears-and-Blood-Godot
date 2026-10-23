extends SceneTree
var n := 0
func _initialize():
	print("start")
	var sc: Node = load("res://scenes/main_menu.tscn").instantiate()
	print("inst")
	root.add_child(sc)
	print("added")
func _process(_d) -> bool:
	n += 1
	if n == 30:
		print("frames ok")
		quit()
	return false
