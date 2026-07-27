## 通用对象池
## 复用节点实例，减少 GC 压力
class_name ObjectPool
extends RefCounted

var _pool: Array[Node] = []
var _scene: PackedScene
var _parent: Node
var _active: Array[Node] = []

## 初始化对象池
## scene: 要池化的场景
## parent: 池化节点的父节点
## initial_size: 预创建数量
func _init(scene: PackedScene, parent: Node, initial_size: int = 10) -> void:
	_scene = scene
	_parent = parent
	for i in range(initial_size):
		var obj = _scene.instantiate()
		obj.visible = false
		obj.set_process(false)
		obj.set_physics_process(false)
		if obj is CanvasItem:
			obj.modulate.a = 0.0
		_parent.add_child(obj)
		_pool.append(obj)

## 从池中获取一个对象
func acquire() -> Node:
	var obj: Node
	if _pool.size() > 0:
		obj = _pool.pop_back()
	else:
		obj = _scene.instantiate()
		_parent.add_child(obj)
	obj.visible = true
	obj.set_process(true)
	obj.set_physics_process(true)
	if obj is CanvasItem:
		obj.modulate.a = 1.0
	_active.append(obj)
	return obj

## 归还对象到池中
func release(obj: Node) -> void:
	if not is_instance_valid(obj):
		return
	obj.visible = false
	obj.set_process(false)
	obj.set_physics_process(false)
	if obj is CanvasItem:
		obj.modulate.a = 0.0
	var idx = _active.find(obj)
	if idx >= 0:
		_active.remove_at(idx)
	_pool.append(obj)

## 归还所有活跃对象
func release_all() -> void:
	for obj in _active:
		if is_instance_valid(obj):
			obj.visible = false
			obj.set_process(false)
			obj.set_physics_process(false)
			if obj is CanvasItem:
				obj.modulate.a = 0.0
			_pool.append(obj)
	_active.clear()

## 获取活跃对象数量
func get_active_count() -> int:
	return _active.size()

## 获取池中可用对象数量
func get_available_count() -> int:
	return _pool.size()
