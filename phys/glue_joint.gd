extends Generic6DOFJoint3D
class_name GlueJoint

var display := MeshInstance3D.new()

# used for safety detach and display
var reference_distance := 0.0
var separation: Vector3

func _init(a: RigidBody3D, b: RigidBody3D) -> void:
	var cap := CapsuleMesh.new()
	reference_distance = a.global_position.distance_to(b.global_position)
	separation = a.to_local(b.global_position)
	cap.height = reference_distance
	cap.radius = 0.05
	display.mesh = cap
	display.rotate_x(PI/2)
	add_child(display)
	node_a = a.get_path()
	node_b = b.get_path()

	# these _significantly_ increase the joint rigidity
	var pin := PinJoint3D.new()
	pin.node_a = node_a
	pin.node_b = node_b
	add_child(pin)

	var lock := HingeJoint3D.new()
	lock.node_a = node_a
	lock.node_b = node_b
	lock.set("angular_limit/enable", true)
	lock.set("angular_limit/lower_limit", 0)
	lock.set("angular_limit/upper_limit", 0)
	lock.set("angular_limit/relaxation", 0.25)
	add_child(lock)

func _update_positions(_delta: float):
	var a: RigidBody3D = get_node_or_null(node_a)
	var b: RigidBody3D = get_node_or_null(node_b)
	if not a or not b:
		return
	if a.global_position.distance_to(b.global_position) > reference_distance * 4:
		Contraption.detach_body(a)
		print("safety detach")
	var up: Vector3 = a.global_basis.y
	var center := (a.global_position + b.global_position) / 2
	var dir := center.direction_to(b.global_position)
	var angle := minf(dir.angle_to(up), dir.angle_to(-up))
	if angle < 0.01:
		up = a.global_basis.z
	look_at_from_position(center, b.global_position, up)

	var target_b := a.to_global(separation)
	var correction := separation * target_b.distance_to(b.global_position) * _delta
	a.apply_central_force(-correction / 2 * a.mass)
	b.apply_central_force(correction / 2 * b.mass)

func _physics_process(_delta: float) -> void:
	_update_positions(_delta)
