extends Node3D

const INK := Color("#141916")
const PANEL := Color("#202923")
const PANEL_LIGHT := Color("#2b382f")
const PAPER := Color("#f0f1e8")
const MUTED := Color("#9ba79b")
const LIME := Color("#c4ef72")
const CORAL := Color("#ff826d")
const TEAL := Color("#72d7c2")
const TOTAL_DAYS := 3

const DAY_TICKETS := [
	[
		{"title": "I can't sign in", "customer": "Mara · Sales", "message": "My password works on my phone, but this laptop keeps asking me to sign in again.", "hint": "They can sign in elsewhere, so the laptop may have an old sign-in saved.", "choices": ["Sign out here, then sign in again", "Order a new laptop", "Change their desk"], "answer": 0},
		{"title": "The printer is stuck", "customer": "Devin · Finance", "message": "My report has been 'printing' for ages, but nothing is coming out.", "hint": "The printer is on. The report may be stuck waiting its turn.", "choices": ["Clear the waiting print jobs", "Replace the printer", "Reset their email"], "answer": 0},
		{"title": "Where did my file go?", "customer": "Inez · Accounts", "message": "I saved the meeting notes, but now I can't find them on this computer.", "hint": "They just saved it. Start by checking the computer's recent files.", "choices": ["Look in recent files", "Reinstall the internet", "Make a new account"], "answer": 0}
	],
	[
		{"title": "Video calls keep freezing", "customer": "Owen · Design", "message": "The call freezes when I sit in the small room at the end of the hall.", "hint": "It only happens in one room, far from the usual work area.", "choices": ["Try a spot closer to the office Wi-Fi", "Replace the webcam", "Turn off the meeting chat"], "answer": 0},
		{"title": "I can't open the team folder", "customer": "Nia · People Ops", "message": "Everyone on my team can open this folder except me. It says I need permission.", "hint": "The folder works for the rest of the team, so this is about who can open it.", "choices": ["Ask the folder owner to add their access", "Move their desk", "Delete the folder"], "answer": 0},
		{"title": "The meeting room screen is blank", "customer": "Sam · Support", "message": "The meeting is about to start. The room screen is on, but it says 'No signal'.", "hint": "The screen is on. Check the connection between the laptop and screen.", "choices": ["Reconnect the room cable", "Change everyone's password", "Restart the office Wi-Fi"], "answer": 0}
	],
	[
		{"title": "The whole room lost internet", "customer": "Ari · Operations", "message": "Everyone in the training room lost internet at once. The rest of the office is fine.", "hint": "Several people in one room are affected, while the rest of the office is okay.", "choices": ["Check the room's internet box and reconnect it", "Fix each laptop one by one", "Replace everyone's mouse"], "answer": 0},
		{"title": "My headset works everywhere but meetings", "customer": "Jules · Sales", "message": "Music plays through my headset, but meeting callers can't hear me.", "hint": "The headset works, so the meeting app may be listening to a different microphone.", "choices": ["Choose the headset in meeting sound settings", "Order a new computer", "Turn off the office lights"], "answer": 0},
		{"title": "The team can't reach the shared drive", "customer": "Rae · Design", "message": "Three teammates all lost access to the shared drive at the same time. Our files are still there.", "hint": "Several teammates lost access together, so check the shared service before changing their devices.", "choices": ["Check whether the shared drive is having an outage", "Reset each teammate's password", "Delete and recreate the files"], "answer": 0},
		{"title": "A new teammate needs to get started", "customer": "Lee · People Ops", "message": "Their laptop is ready, but they can't get online or open the team's welcome page.", "hint": "They need to join the office network before opening an online page.", "choices": ["Connect them to the office Wi-Fi", "Replace the welcome page", "Ask them to use a different keyboard"], "answer": 0}
	]
]

var player: CharacterBody3D
var computer_ray: RayCast3D
var terminal_root: Control
var ticket_list: VBoxContainer
var ticket_detail: VBoxContainer
var day_label: Label
var progress_label: Label
var mood_label: Label
var hint_label: Label
var feedback_label: Label
var result_overlay: ColorRect
var computer_body: StaticBody3D
var tickets: Array[Dictionary] = []
var selected_ticket := 0
var day_number := 1
var day_closed := 0
var day_quota := 4
var mood := 75
var in_terminal := false
var feedback_text := "Pick a ticket, read the customer's clues, and choose a fix."


func _ready() -> void:
	randomize()
	_build_room()
	_build_player()
	_build_interface()
	_start_day()


func _process(_delta: float) -> void:
	if in_terminal or not is_instance_valid(computer_ray):
		return
	var looking_at_computer := computer_ray.is_colliding() and computer_ray.get_collider().is_in_group("computer")
	hint_label.visible = looking_at_computer


func _build_room() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#18211c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#b9cbb7")
	environment.ambient_light_energy = 0.45
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -22, 0)
	sun.light_energy = 0.7
	add_child(sun)

	_add_box("Floor", Vector3(10, 0.2, 10), Vector3(0, -0.1, 0), Color("#41483d"))
	_add_box("Back wall", Vector3(10, 3.2, 0.2), Vector3(0, 1.5, -4.8), Color("#637060"))
	_add_box("Left wall", Vector3(0.2, 3.2, 10), Vector3(-4.8, 1.5, 0), Color("#526050"))
	_add_box("Right wall", Vector3(0.2, 3.2, 10), Vector3(4.8, 1.5, 0), Color("#526050"))
	_add_box("Desk top", Vector3(2.2, 0.12, 0.95), Vector3(0, 0.78, -1.75), Color("#936947"))
	_add_box("Desk left leg", Vector3(0.12, 0.76, 0.12), Vector3(-0.94, 0.38, -1.75), Color("#72553d"))
	_add_box("Desk right leg", Vector3(0.12, 0.76, 0.12), Vector3(0.94, 0.38, -1.75), Color("#72553d"))
	_add_box("Monitor stand", Vector3(0.12, 0.28, 0.12), Vector3(0, 0.98, -1.78), Color("#252b28"))
	computer_body = _add_box("Workstation", Vector3(1.05, 0.62, 0.12), Vector3(0, 1.39, -1.78), Color("#222a25"))
	computer_body.add_to_group("computer")
	var screen_text := Label3D.new()
	screen_text.text = "HELP DESK\nPRESS E"
	screen_text.position = Vector3(0, 0, 0.066)
	screen_text.font_size = 32
	screen_text.modulate = LIME
	screen_text.outline_size = 8
	computer_body.add_child(screen_text)
	_add_box("Keyboard", Vector3(0.72, 0.035, 0.26), Vector3(0, 0.87, -1.19), Color("#303a32"), false)
	_add_box("Desk lamp", Vector3(0.1, 0.42, 0.1), Vector3(-0.78, 1.05, -1.7), Color("#d0c77d"), false)
	_add_box("Filing cabinet", Vector3(0.8, 1.1, 0.75), Vector3(-3.2, 0.55, -3.5), Color("#89907d"))
	_add_box("Notice board", Vector3(2.1, 1.1, 0.06), Vector3(2.1, 2.05, -4.66), Color("#a27a55"), false)


func _build_player() -> void:
	var player_script: Script = load("res://scripts/player.gd")
	player = CharacterBody3D.new()
	player.set_script(player_script)
	player.position = Vector3(0, 0.05, 1.6)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)
	add_child(player)
	player.interact_requested.connect(_on_interact)
	player.escape_requested.connect(_on_escape)
	computer_ray = player.get_node("Camera3D/ComputerRay")


func _build_interface() -> void:
	var hint_layer := CanvasLayer.new()
	add_child(hint_layer)
	hint_label = Label.new()
	hint_label.text = "E   USE WORKSTATION"
	hint_label.visible = false
	hint_label.position = Vector2(0, -90)
	hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_label.offset_left = -170
	hint_label.offset_right = 170
	hint_label.offset_top = -42
	hint_label.offset_bottom = 0
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", LIME)
	hint_layer.add_child(hint_label)

	var terminal_layer := CanvasLayer.new()
	terminal_layer.layer = 2
	add_child(terminal_layer)
	terminal_root = Control.new()
	terminal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	terminal_root.visible = false
	terminal_layer.add_child(terminal_root)
	var backdrop := ColorRect.new()
	backdrop.color = Color("#101512")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	terminal_root.add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 32)
	terminal_root.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_child(_make_label("NORTHSTAR   /   SUPPORT PORTAL", 12, LIME, true))
	title_stack.add_child(_make_label("Help Desk", 28, PAPER, true))
	header.add_child(title_stack)
	day_label = _make_label("DAY 1", 14, TEAL, true)
	header.add_child(day_label)
	var close_button := _make_button("E / ESC  STAND UP", MUTED)
	close_button.pressed.connect(_close_terminal)
	header.add_child(close_button)

	var status_bar := HBoxContainer.new()
	status_bar.add_theme_constant_override("separation", 10)
	layout.add_child(status_bar)
	status_bar.add_child(_make_status("TODAY'S QUOTA", "4 tickets"))
	progress_label = _make_label("0 / 4 CLOSED", 15, LIME, true)
	status_bar.add_child(progress_label)
	status_bar.add_child(_make_status("TEAM MOOD", "75%"))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	layout.add_child(body)
	var inbox_panel := _make_panel()
	inbox_panel.custom_minimum_size.x = 340
	body.add_child(inbox_panel)
	var inbox_layout := VBoxContainer.new()
	inbox_layout.add_theme_constant_override("separation", 12)
	inbox_panel.add_child(inbox_layout)
	inbox_layout.add_child(_make_label("OPEN TICKETS", 14, PAPER, true))
	ticket_list = VBoxContainer.new()
	ticket_list.add_theme_constant_override("separation", 8)
	inbox_layout.add_child(ticket_list)
	inbox_layout.add_spacer(false)
	inbox_layout.add_child(_make_label("Read the clues. No tech experience needed.", 12, MUTED))
	var detail_panel := _make_panel()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(detail_panel)
	ticket_detail = VBoxContainer.new()
	ticket_detail.add_theme_constant_override("separation", 14)
	detail_panel.add_child(ticket_detail)

	var footer := _make_label("PLAIN-LANGUAGE SUPPORT   ·   CUSTOMERS ARE WAITING", 11, MUTED, true)
	layout.add_child(footer)


func _start_day() -> void:
	day_quota = 3 + day_number
	day_closed = 0
	tickets.clear()
	selected_ticket = 0
	feedback_text = "Pick a ticket, read the customer's clues, and choose a fix."
	if is_instance_valid(result_overlay):
		result_overlay.queue_free()
		result_overlay = null
	for index in range(mini(3, day_quota)):
		_add_ticket()
	_render_portal()


func _add_ticket() -> void:
	var pool: Array = DAY_TICKETS[day_number - 1]
	var ticket: Dictionary = pool[randi() % pool.size()].duplicate(true)
	ticket["id"] = day_closed + tickets.size() + 1
	tickets.append(ticket)


func _render_portal() -> void:
	day_label.text = "DAY %d   /   %s" % [day_number, _day_theme()]
	progress_label.text = "%d / %d CLOSED" % [day_closed, day_quota]
	mood_label.text = "%d%%" % mood
	for child in ticket_list.get_children():
		child.queue_free()
	if tickets.is_empty():
		ticket_list.add_child(_make_label("No open tickets. Enjoy the quiet.", 14, MUTED))
	else:
		selected_ticket = clampi(selected_ticket, 0, tickets.size() - 1)
		for index in range(tickets.size()):
			var ticket: Dictionary = tickets[index]
			var button := _make_button("%s\n%s" % [ticket["title"], ticket["customer"]], PAPER if index == selected_ticket else MUTED)
			button.custom_minimum_size.y = 68
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.pressed.connect(_select_ticket.bind(index))
			ticket_list.add_child(button)
	for child in ticket_detail.get_children():
		child.queue_free()
	if tickets.is_empty():
		ticket_detail.add_child(_make_label("INBOX CLEAR", 13, TEAL, true))
		ticket_detail.add_child(_make_label("You handled the whole queue.", 25, PAPER, true))
		ticket_detail.add_child(_make_label("Take a breath before the next batch arrives.", 15, MUTED))
		return
	var selected: Dictionary = tickets[selected_ticket]
	ticket_detail.add_child(_make_label("CUSTOMER REQUEST   /   #%02d" % selected["id"], 12, CORAL, true))
	ticket_detail.add_child(_make_label(selected["title"], 25, PAPER, true))
	ticket_detail.add_child(_make_label(selected["customer"], 14, TEAL, true))
	var message := _make_label("\"%s\"" % selected["message"], 16, PAPER)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ticket_detail.add_child(message)
	ticket_detail.add_child(_make_label("WHAT WOULD YOU TRY?", 11, MUTED, true))
	for option_index in range(selected["choices"].size()):
		var action := _make_button("%d    %s" % [option_index + 1, selected["choices"][option_index]], PAPER)
		action.custom_minimum_size.y = 48
		action.alignment = HORIZONTAL_ALIGNMENT_LEFT
		action.pressed.connect(_resolve_ticket.bind(option_index))
		ticket_detail.add_child(action)
	feedback_label = _make_label(feedback_text, 13, MUTED)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ticket_detail.add_child(feedback_label)
	ticket_detail.add_spacer(false)


func _select_ticket(index: int) -> void:
	selected_ticket = index
	feedback_text = "Read the customer's clues, then pick the fix that fits."
	_render_portal()


func _resolve_ticket(choice_index: int) -> void:
	if tickets.is_empty():
		return
	var ticket: Dictionary = tickets[selected_ticket]
	if choice_index == ticket["answer"]:
		day_closed += 1
		mood = mini(100, mood + 4)
		feedback_text = "Solved. %s is back to work." % ticket["customer"].split(" · ")[0]
		tickets.remove_at(selected_ticket)
		selected_ticket = mini(selected_ticket, maxi(0, tickets.size() - 1))
		if day_closed < day_quota and tickets.size() < 3:
			_add_ticket()
		_render_portal()
		if day_closed >= day_quota:
			_show_day_result()
	else:
		mood = maxi(0, mood - 8)
		feedback_text = "Not quite. Clue: %s" % ticket["hint"]
		_render_portal()


func _show_day_result() -> void:
	result_overlay = ColorRect.new()
	result_overlay.color = Color(0, 0, 0, 0.76)
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	terminal_root.add_child(result_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.add_child(center)
	var card := _make_panel()
	card.custom_minimum_size = Vector2(470, 240)
	center.add_child(card)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	card.add_child(content)
	content.add_child(_make_label("DAY %d COMPLETE" % day_number, 12, LIME, true))
	var is_final_day := day_number >= TOTAL_DAYS
	content.add_child(_make_label("The queue is clear." if not is_final_day else "You're the office hero.", 26, PAPER, true))
	content.add_child(_make_label("%d tickets closed  ·  Team mood %d%%" % [day_closed, mood], 14, MUTED))
	var next_button := _make_button("BACK TO OFFICE" if is_final_day else "START DAY %d" % (day_number + 1), INK, LIME)
	next_button.custom_minimum_size.y = 48
	if is_final_day:
		next_button.pressed.connect(_close_terminal)
	else:
		next_button.pressed.connect(_advance_day)
	content.add_child(next_button)


func _advance_day() -> void:
	day_number += 1
	_start_day()


func _day_theme() -> String:
	var themes := ["FIRST DAY", "OFFICE CONNECTIONS", "WHOLE-TEAM ISSUES"]
	return themes[day_number - 1]


func _on_interact() -> void:
	if in_terminal:
		_close_terminal()
		return
	if computer_ray.is_colliding() and computer_ray.get_collider().is_in_group("computer"):
		in_terminal = true
		terminal_root.visible = true
		hint_label.visible = false
		player.can_move = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_escape() -> void:
	if in_terminal:
		_close_terminal()
	elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _close_terminal() -> void:
	in_terminal = false
	terminal_root.visible = false
	player.can_move = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _add_box(box_name: String, box_size: Vector3, box_position: Vector3, color: Color, has_collision: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = box_position
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	mesh_instance.mesh = box_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	if has_collision:
		var shape := BoxShape3D.new()
		shape.size = box_size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
	add_child(body)
	return body


func _make_status(caption: String, value: String) -> PanelContainer:
	var panel := _make_panel()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	row.add_child(_make_label(caption, 11, MUTED, true))
	var value_label := _make_label(value, 14, PAPER, true)
	if caption == "TEAM MOOD":
		mood_label = value_label
	row.add_child(value_label)
	return panel


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_top = 16
	style.content_margin_right = 18
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_button(text: String, text_color: Color, fill: Color = PANEL_LIGHT) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_stylebox_override("normal", _button_style(fill))
	button.add_theme_stylebox_override("hover", _button_style(Color("#39483d")))
	button.add_theme_stylebox_override("pressed", _button_style(LIME))
	return button


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	return style


func _make_label(text: String, size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	return label