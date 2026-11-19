extends CharacterBody3D

signal interact_requested
signal escape_requested

const WALK_SPEED := 4.2
const MOUSE_SENSITIVITY := 0.002
const GRAVITY := 18.0

var can_move := true
var camera: Camera3D


func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position.y = 1.62
	camera.rotation.x = deg_to_rad(5)
	camera.current = true
	add_child(camera)
	var ray := RayCast3D.new()
	ray.name = "ComputerRay"
	ray.target_position = Vector3(0, 0, -3.2)
	ray.enabled = true
	ray.collision_mask = 1
	camera.add_child(ray)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and can_move:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-75), deg_to_rad(75))
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			interact_requested.emit()
		elif event.keycode == KEY_ESCAPE:
			escape_requested.emit()


func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector3.ZERO
		return
	var input_direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input_direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_direction.y += 1.0
	input_direction = input_direction.normalized()
	var move_direction := global_transform.basis * Vector3(input_direction.x, 0, input_direction.y)
	velocity.x = move_direction.x * WALK_SPEED
	velocity.z = move_direction.z * WALK_SPEED
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()