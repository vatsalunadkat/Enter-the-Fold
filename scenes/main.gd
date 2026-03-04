extends Node2D

var customer1_scene = preload("res://scenes/customer.tscn")
var customer2_scene = preload("res://scenes/customer_2.tscn")
var customer3_scene = preload("res://scenes/customer_3.tscn")

func _ready():
	await run_customer(customer1_scene)
	await run_customer(customer2_scene)
	await run_customer(customer3_scene)
	
func run_customer(scene):
	var customer = scene.instantiate()
	add_child(customer)
	customer.position = $CustomerEntrance.position

	# Drop-off visit
	customer.start_visit($DropOffPath)
	await customer.visit_done

	await get_tree().create_timer(2.0).timeout

	# Pickup visit
	customer.position = $CustomerEntrance.position
	customer.show()
	customer.start_visit($PickupPath)
	await customer.visit_done

	customer.queue_free()
