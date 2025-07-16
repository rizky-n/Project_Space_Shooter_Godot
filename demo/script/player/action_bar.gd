extends HBoxContainer


var skills : Array

func _ready():
	skills = get_children()
	for i in get_child_count():
		skills[i].change_key = str(i+1)
