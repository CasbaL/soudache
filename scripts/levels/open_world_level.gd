## 开放世界关卡
## 使用单一大地图，分散敌人、资源、NPC
extends Node2D

# ============================================================
# 场景引用
# ============================================================

@onready var player = $Player
@onready var camera = $Player/Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var open_world_map: Node2D = $OpenWorldMap

# ============================================================
# 预加载脚本
# ============================================================

var _OpenWorldMapScript = preload("res://scripts/systems/open_world_map.gd")

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print("[OpenWorldLevel] _ready 开始")
	
	# 初始化游戏
	GameManager.start_new_game()
	
	# 初始化地图
	_init_map()
	
	# 连接信号
	_connect_signals()
	
	# 初始化HUD
	if hud and player:
		hud.initialize(player)
	
	# 放置玩家到出生点
	_place_player_at_spawn()
	
	print("[OpenWorldLevel] _ready 完成")

## 初始化地图
func _init_map() -> void:
	if open_world_map:
		print("[OpenWorldLevel] 地图初始化完成")

## 连接信号
func _connect_signals() -> void:
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)

## 放置玩家到出生点
func _place_player_at_spawn() -> void:
	if player and open_world_map:
		# 出生点在左上角
		player.position = Vector2(300, 300)
		print("[OpenWorldLevel] 玩家放置到出生点: %s" % str(player.position))

# ============================================================
# 信号回调
# ============================================================

func _on_player_health_changed(new_health: int) -> void:
	if hud and player:
		hud.update_health(new_health, player.max_health)

# ============================================================
# 物理更新
# ============================================================

func _physics_process(_delta: float) -> void:
	# 限制玩家在地图范围内
	if player and open_world_map:
		var map_size = open_world_map.get_map_size()
		player.position = player.position.clamp(Vector2.ZERO, map_size)
