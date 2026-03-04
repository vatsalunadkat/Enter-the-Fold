extends Node2D

func _ready():
	$Customer.position = $CustomerEntrance.position
	$Customer.show()
	await do_dropoff_visit()
	
	await get_tree().create_timer(2.0).timeout  # wait 2 seconds hidden
	
	await do_pickup_visit()

func do_dropoff_visit():
	$Customer.position = $CustomerEntrance.position
	$Customer.show()
	$Customer.start_visit($DropOffPath)
	await $Customer.visit_done

func do_pickup_visit():
	$Customer.position = $CustomerEntrance.position
	$Customer.show()
	$Customer.start_visit($PickupPath)
	await $Customer.visit_done
