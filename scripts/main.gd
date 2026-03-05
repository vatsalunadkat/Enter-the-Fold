extends Node2D

# preload customer scene variants to avoid loading them at runtime
var customer1_scene = preload("res://scenes/customer.tscn")
var customer2_scene = preload("res://scenes/customer_2.tscn")
var customer3_scene = preload("res://scenes/customer_3.tscn")

# run each of the customers sequentially
func _ready():
	await run_customer(customer1_scene)
	await run_customer(customer2_scene)
	await run_customer(customer3_scene)

# instantiate the customer from the given scene and add it to the scene tree
func run_customer(scene):
	var customer = scene.instantiate()
	add_child(customer)
	customer.position = $CustomerEntrance.position

	# drop-off visit
	customer.start_visit($DropOffPath)
	await customer.visit_done

	await get_tree().create_timer(2.0).timeout

	# pickup visit
	customer.position = $CustomerEntrance.position
	customer.show()
	customer.start_visit($PickupPath)
	await customer.visit_done

	customer.queue_free()
