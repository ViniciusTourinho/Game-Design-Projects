class_name Player
extends CharacterBody2D

@export_category("movement")
@export var speed: float = 300
@export_category("damage")
@export var sword_damage: int = 2
@export var holy_aura_damage: int = 1
@export var holy_aura_interval: float = 30
@export var holy_aura_scene: PackedScene
@export_category("health")
@export var health: int = 100
@export var max_health: int = 100
@export var death_prefab: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitboxArea
@onready var health_progress_bar: ProgressBar = $HealthProgressBar

var input_vector: Vector2 = Vector2(0, 0)
var is_running: bool = false
var was_running: bool = false
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var hitbox_cooldown: float = 0.0
var holy_aura_cooldown: float =0.0


signal meat_collected(value: int)


func _ready():
	GameManager.player = self


func _process(delta: float) -> void:
	GameManager.player_position = position
	# Ler input
	read_input()

	# Processar ataque
	update_attack_cooldown(delta)
	if Input.is_action_just_pressed("attack"):
		attack()

	#processar animação e rotação de sprite
	play_run_idle_animation()
	if not is_attacking:
		rotate_sprite()

	# Processaar dano
	#update_hitbox_detection(delta)
	
	# Holy aura
	update_holy_aura(delta)
	
	# Atualizar barra de vida
	health_progress_bar.max_value = max_health
	health_progress_bar.value = health


func _physics_process(_delta: float) -> void:
	# Modificar a velocidade
	var target_velocity = input_vector * speed
	if is_attacking:
		target_velocity *= 0.25
	velocity = lerp(velocity, target_velocity, 0.05)
	move_and_slide()


func update_attack_cooldown(delta: float) -> void:
	# Atualizar temporizador do taque
	if is_attacking:
		attack_cooldown -= delta # 0.6 - 0.016
		if attack_cooldown <= 0.0:
			is_attacking = false
			is_running = false
			animation_player.play("idle")


func update_holy_aura(delta: float) -> void:
	# Atualizar temporizador
	holy_aura_cooldown -= delta 
	if holy_aura_cooldown > 0: return
	holy_aura_cooldown = holy_aura_interval
	
	# Criar holy aura
	var holy_aura = holy_aura_scene.instantiate()
	holy_aura.damage_amount = holy_aura_damage
	add_child(holy_aura)


func read_input() -> void:
	# Obter o input vector
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Apagar deadzone do input vector em controles
	var _deadzone = 0.15
	if abs(input_vector.x) < 0.15:
		input_vector.x = 0.0
	if abs(input_vector.y) < 0.15:
		input_vector.y = 0.0
	
# Atualizar o is_running
	was_running = is_running
	is_running = not input_vector.is_zero_approx()


func play_run_idle_animation() -> void:
	# Tocar animação
	if not is_attacking:
		if was_running != is_running:
			if is_running:
				animation_player.play("run")
			else:
				animation_player.play("idle")


func rotate_sprite() -> void:
	# Girar Sprite
	if input_vector.x > 0:
		sprite.flip_h = false
	elif input_vector.x < 0:
		sprite.flip_h = true


func attack() -> void:
	if is_attacking:
		return
	
	# Tocar animação
	animation_player.play("attack_side_1")
	
	#configurar temporizador
	attack_cooldown = 0.6
	
	# Marcar ataque
	is_attacking = true


func damage(amount: int) -> void:
	health -= amount
	print("Player recebeu dano de ", amount, ". A vida total é de ", health)

	# Piscar node
	modulate = Color.RED
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

	# Processar morte
	if health <= 0:
		die()


func die() -> void:
	if death_prefab:
		var death_object = death_prefab.instantiate()
		death_object.position = position
		get_parent().add_child(death_object)
	
	queue_free()


func heal(amount: int) -> int:
	health += amount
	if health > max_health:
		health = max_health
	print("Player recebeu cura de", amount, ". A vida total é de ", health, "/", max_health)
	return health
