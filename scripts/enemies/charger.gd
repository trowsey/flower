# Charger: rusher that telegraphs then dashes in straight line
extends EnemyBase
class_name Charger

enum State { IDLE, TELEGRAPH, CHARGING, RECOVER }

@export var charge_trigger_range: float = 8.0
@export var telegraph_time: float = 0.6
@export var charge_time: float = 1.0
@export var recover_time: float = 1.5
@export var charge_speed: float = 6.0

var state: int = State.IDLE
var _state_timer: float = 0.0
var _charge_dir: Vector3 = Vector3.ZERO


func _ready() -> void:
	max_health = 35.0
	move_speed = 2.5
	damage = 16.0
	attack_range = 1.4
	enemy_type = "charger"
	xp_reward = 35.0
	gold_drop_min = 1
	gold_drop_max = 6
	super._ready()


func _physics_process(delta: float) -> void:
	if not alive or not player:
		return
	_state_timer -= delta
	match state:
		State.IDLE:
			_idle(delta)
		State.TELEGRAPH:
			velocity = Vector3.ZERO
			if _state_timer <= 0.0:
				_begin_charge()
		State.CHARGING:
			velocity = _charge_dir * charge_speed
			move_and_slide()
			if distance_to_player() <= attack_range and player.has_method("take_damage"):
				player.take_damage(damage)
				_enter_recover()
				return
			if _state_timer <= 0.0:
				_enter_recover()
		State.RECOVER:
			velocity = Vector3.ZERO
			if _state_timer <= 0.0:
				state = State.IDLE


func _idle(_delta: float) -> void:
	var dist := distance_to_player()
	if dist <= charge_trigger_range:
		state = State.TELEGRAPH
		_state_timer = telegraph_time
		velocity = Vector3.ZERO
	else:
		var dir: Vector3 = (player.global_position - global_position)
		dir.y = 0.0
		velocity = dir.normalized() * move_speed
		move_and_slide()


func _begin_charge() -> void:
	state = State.CHARGING
	_state_timer = charge_time
	var dir: Vector3 = (player.global_position - global_position)
	dir.y = 0.0
	_charge_dir = dir.normalized()


func _enter_recover() -> void:
	state = State.RECOVER
	_state_timer = recover_time
	velocity = Vector3.ZERO
