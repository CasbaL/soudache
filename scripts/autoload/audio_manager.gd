## 音频管理器 - 自动加载单例
## 管理背景音乐和音效
extends Node

# 音频播放器
var bgm_player: AudioStreamPlayer = AudioStreamPlayer.new()
var sfx_players: Array[AudioStreamPlayer] = []

# 音量设置
var bgm_volume: float = 0.8
var sfx_volume: float = 1.0

# 最大同时播放的音效数
var max_sfx_players: int = 10

func _ready() -> void:
	# 初始化背景音乐播放器
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "BGM"
	add_child(bgm_player)
	
	# 初始化音效播放器池
	for i in range(max_sfx_players):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

## 播放背景音乐
func play_bgm(stream: AudioStream, fade_time: float = 1.0) -> void:
	if bgm_player.stream == stream and bgm_player.playing:
		return
	
	bgm_player.stream = stream
	bgm_player.volume_db = linear_to_db(0.0)
	bgm_player.play()
	
	# 淡入效果
	var tween = create_tween()
	tween.tween_method(_set_bgm_volume, 0.0, bgm_volume, fade_time)

## 停止背景音乐
func stop_bgm(fade_time: float = 1.0) -> void:
	if not bgm_player.playing:
		return
	
	# 淡出效果
	var tween = create_tween()
	tween.tween_method(_set_bgm_volume, bgm_volume, 0.0, fade_time)
	tween.tween_callback(bgm_player.stop)

## 播放音效
func play_sfx(stream: AudioStream, volume_scale: float = 1.0) -> void:
	# 查找空闲的播放器
	var player = _get_free_sfx_player()
	if player == null:
		return
	
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * volume_scale)
	player.play()

## 设置背景音乐音量
func _set_bgm_volume(volume: float) -> void:
	bgm_volume = volume
	bgm_player.volume_db = linear_to_db(volume)

## 获取空闲的音效播放器
func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return null

## 播放预加载的音效（通过路径）
func play_sfx_by_path(path: String, volume_scale: float = 1.0) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream = load(path) as AudioStream
	if stream:
		play_sfx(stream, volume_scale)

## 播放按键音效
func play_ui_click() -> void:
	# 使用程序生成的短促音效
	var player = _get_free_sfx_player()
	if player == null:
		return
	# 简单的点击音效（如果有的话）
	# play_sfx_by_path("res://assets/audio/sfx/click.ogg")

## 设置BGM音量（0-1）
func set_bgm_volume(volume: float) -> void:
	bgm_volume = clampf(volume, 0.0, 1.0)
	bgm_player.volume_db = linear_to_db(bgm_volume)

## 设置SFX音量（0-1）
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)

## 静音/取消静音
func toggle_mute() -> void:
	if bgm_player.volume_db > -80:
		bgm_player.volume_db = -80
	else:
		bgm_player.volume_db = linear_to_db(bgm_volume)
