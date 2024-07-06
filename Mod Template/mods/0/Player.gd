extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var player: V1.Player;

var left: V1.Element;
var right: V1.Element;
var jump: V1.Element

var left_held = false;
var right_held = false;

var jump_held = false;

func with_data(p_player: V1.Player):
	self.player = p_player;
	self.left = V1.Element.new("v1-test", {})
	self.player.add_child(self.left);
	#self.left = V1.Element.ButtonElement.new("left", ["a", "ArrowLeft"]);
	#self.left.Down.connect(func(): self.left_held = true);
	#self.left.Up.connect(func(): self.left_held = false);
	#self.right = V1.Element.new("v1-button", { "text" = "right", "keyboard_inputs" = ["d","ArrowRight"]  });
	#self.right.Event.connect(func(e, d):  
		#if e == "down":
			#self.right_held = true;
		#else:
			#self.right_held = false;
	#);
	#
	#self.jump = V1.Element.ButtonElement.new("jump", [" ", "w", "ArrowUp"]);
	#self.jump.Down.connect(func(): self.jump_held = true);
	#self.jump.Up.connect(func(): self.jump_held = false);
	#
	#self.player.root_element.add_children([self.left, self.right, self.jump]);
	return self;

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if self.jump_held and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.s
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var direction = Input.get_axis("ui_left", "ui_right")
	var direction = 0.0;
	if self.left_held:
		direction += -1.0;
	if self.right_held:
		direction += 1.0;
	
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
