extends KinematicBody2D

export var ACCELERATION: int = 1500
export var FRICTION: int = 1500
export var RUN_SPEED: int = 200

enum {
  IDLE,
  MOVE,
  ATTACK_1,
  ATTACK_2
}
var can_combo: bool = false
var state: int = IDLE
var velocity: Vector2 = Vector2.ZERO
var input_vector: Vector2 = Vector2.ZERO

onready var animationPlayer: AnimationPlayer = $Sprite/AnimationPlayer
onready var animationTree: AnimationTree = $Sprite/AnimationPlayer/AnimationTree
onready var animationState: AnimationNodeStateMachinePlayback = animationTree.get("parameters/playback")

func get_input() -> void:
  input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
  input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

  input_vector = input_vector.normalized()

func move() -> void:
  velocity = move_and_slide(velocity)

func change_state(new_state: int) -> void:
  state = new_state

func idle_state(delta: float) -> void:
  if input_vector != Vector2.ZERO:
    change_state(MOVE)
    return
  if Input.is_action_just_pressed("attack"):
    change_state(ATTACK_1)
    return
  animationState.travel("idle")
  velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

func move_state(delta: float) -> void:
  if input_vector == Vector2.ZERO:
    change_state(IDLE)
    return
  if Input.is_action_just_pressed("attack"):
    change_state(ATTACK_1)
    return
  animationTree.set("parameters/idle/blend_position", input_vector)
  animationTree.set("parameters/run/blend_position", input_vector)
  animationTree.set("parameters/attack-1/blend_position", input_vector)
  animationTree.set("parameters/attack-2/blend_position", input_vector)
  animationState.travel("run")
  velocity = velocity.move_toward(input_vector * RUN_SPEED, ACCELERATION * delta)

func attack_1_state(_delta: float):
  velocity = move_and_slide(Vector2.ZERO)
  if Input.is_action_just_pressed("attack") and can_combo == true:
    change_state(ATTACK_2)
    return
  animationState.travel("attack-1")

func attack_2_state(_delta: float):
  animationState.travel("attack-2")

func attack_animation_state(state_name: String) -> void:
  if state_name == "finish":
    can_combo = false
    if input_vector != Vector2.ZERO:
      change_state(MOVE)
    else:
      change_state(IDLE)
  elif state_name == "combo":
    can_combo = true
  return

func state_machine(delta: float) -> void:
  match state:
    IDLE:
      idle_state(delta)
    MOVE:
      move_state(delta)
    ATTACK_1:
      attack_1_state(delta)
    ATTACK_2:
      attack_2_state(delta)
  move()

func _ready() -> void:
  animationTree.active = true

func _physics_process(delta: float) -> void:
  print(animationState.get_current_node())
  get_input()
  state_machine(delta)
