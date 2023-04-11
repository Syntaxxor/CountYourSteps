@tool
extends StaticBody3D


@export var amount = 2


# Called when the node enters the scene tree for the first time.
func _ready():
	if amount > 0:
		$Label3D.text = "+" + str(amount)
	else:
		$Label3D.text = str(amount)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func disable():
	visible = false
	$CollisionShape3D.disabled = true


func enable():
	visible = true
	$CollisionShape3D.disabled = false
