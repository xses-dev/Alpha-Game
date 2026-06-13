extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var goal: MeshInstance3D = $Goal

var speed := 7.0
var ai_timer := 0.0
var ai_interval := 6.0
var enemies := []
var health := 100
var game_over := false

func _ready():
	print("AI Game started.")
	print("Reach the goal cube. The AI will try to stop you.")

func _physics_process(delta):
	if game_over:
		return

	handle_player(delta)
	handle_enemies(delta)

	ai_timer += delta
	if ai_timer >= ai_interval:
		ai_timer = 0.0
		ask_ai_director()

	check_goal()

func handle_player(delta):
	var input_dir = Vector3.ZERO

	if Input.is_action_pressed("ui_up"):
		input_dir.z -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.z += 1
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	player.velocity.x = input_dir.x * speed
	player.velocity.z = input_dir.z * speed
	player.velocity.y -= 20.0 * delta

	player.move_and_slide()

func handle_enemies(delta):
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var dir = player.global_position - enemy.global_position
		dir.y = 0

		if dir.length() > 0.1:
			enemy.global_position += dir.normalized() * delta * 2.5

		if enemy.global_position.distance_to(player.global_position) < 1.4:
			health -= 10
			print("Player hit! Health:", health)
			enemy.queue_free()

			if health <= 0:
				lose_game()

func check_goal():
	if player.global_position.distance_to(goal.global_position) < 2.0:
		win_game()

func ask_ai_director():
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_ai_response.bind(http))

	var world_state = {
		"health": health,
		"player_position": vec_to_dict(player.global_position),
		"goal_position": vec_to_dict(goal.global_position),
		"enemy_count": enemies.size()
	}

	var body = {
		"model": "local-qwen",
		"messages": [
			{
				"role": "system",
				"content": load_prompt()
			},
			{
				"role": "user",
				"content": "Current world state: " + JSON.stringify(world_state)
			}
		],
		"temperature": 0.9,
		"max_tokens": 200
	}

	var headers = ["Content-Type: application/json"]

	var err = http.request(
		"http://127.0.0.1:8000/v1/chat/completions",
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)

	if err != OK:
		print("AI request failed:", err)
		http.queue_free()

func _on_ai_response(result, response_code, headers, body, http):
	http.queue_free()

	if response_code != 200:
		print("AI server error:", response_code)
		return

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if parsed == null:
		print("Could not parse AI server response.")
		return

	var text = parsed["choices"][0]["message"]["content"]
	print("AI says:", text)

	var action = JSON.parse_string(text)
	if action == null:
		print("AI did not return valid JSON.")
		return

	apply_ai_action(action)

func apply_ai_action(action):
	var action_name = action.get("action", "do_nothing")
	var message = action.get("message", "")

	if message != "":
		print("AI Director:", message)

	match action_name:
		"spawn_enemy":
			var amount = int(action.get("amount", 1))
			amount = clamp(amount, 1, 3)
			for i in range(amount):
				spawn_enemy_near_player()

		"spawn_health":
			health = min(100, health + 20)
			print("Health restored. Health:", health)

		"move_goal":
			move_goal_random()

		"taunt_player":
			print("The AI watches you carefully.")

		"do_nothing":
			print("The AI waits.")

		_:
			print("Unknown AI action:", action_name)

func spawn_enemy_near_player():
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1, 2, 1)
	mesh.mesh = box
	mesh.name = "Enemy"

	var offset = Vector3(
		randf_range(-8, 8),
		1,
		randf_range(-8, 8)
	)

	mesh.global_position = player.global_position + offset
	add_child(mesh)
	enemies.append(mesh)

	print("Enemy spawned.")

func move_goal_random():
	goal.global_position = Vector3(
		randf_range(-18, 18),
		1,
		randf_range(-18, 18)
	)
	print("Goal moved to:", goal.global_position)

func win_game():
	game_over = true
	print("YOU WIN. You reached the goal.")

func lose_game():
	game_over = true
	print("YOU LOSE. The AI defeated you.")

func load_prompt():
	var file = FileAccess.open("res://prompts/ai_director_prompt.txt", FileAccess.READ)
	if file == null:
		return "You are an AI game director. Return only JSON."
	return file.get_as_text()

func vec_to_dict(v: Vector3):
	return {
		"x": v.x,
		"y": v.y,
		"z": v.z
	}
