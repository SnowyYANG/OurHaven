extends Node2D

# 递归用 Line2D 绘制标准三叉树（每节点三叉）
# 可通过导出变量调整深度、长度、缩放、角度、线宽与颜色

var depth = 2                          # 递归深度（层数）
var initial_length = 10.0           # 起始主干长度（像素）
var length_scale = 0.65               # 子分支长度相对于父分支的缩放
var angle_spread_deg = 30.0          # 左中右子分支的角度展开（度）
var line_width = 2.0                 # 线宽
var line_color = Color(1, 1, 1)      # 线颜色
var root_offset = Vector2(400, 400)    # 根点偏移（相对于此 Node2D 的局部坐标）
var ellipse_points := []  # 存储所有点击点
var lines := []

func _ready():
	# 自动在场景运行时构建树
	set_process_input(true)
	rebuild_tree()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = event.position
		var min_dist = INF
		var nearest_line = null
		for line in lines:
			if line.get_point_count() >= 2:
				var p1 = line.get_point_position(0)
				var p2 = line.get_point_position(1)
				var dist = Geometry2D.get_closest_point_to_segment(mouse_pos, p1, p2).distance_to(mouse_pos)
				if dist < min_dist:
					min_dist = dist
					nearest_line = line
		if nearest_line != null:
			var marker = Node2D.new()
			marker.position = mouse_pos - nearest_line.global_position
			nearest_line.add_child(marker)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		clear_tree()
		depth = 2
		initial_length = 10
		angle_spread_deg = 30
		ellipse_points.clear()
		rebuild_tree()
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		# 示例：每次按空格递增深度（可自定义为其他参数或循环）
		depth += 0.2
		initial_length += 5
		angle_spread_deg += 1.5
		if depth > 5:  # 限制最大深度，防止性能问题
			depth = 5
		rebuild_tree()
	queue_redraw()

func _draw():
	for line in lines:
		for child in line.get_children():
			if child is Node2D:
				var global_pos = line.to_global(child.position)
				draw_circle(global_pos, 6, Color(1, 1, 1), false)

func rebuild_tree() -> void:
	# 清除已有 Line2D，然后从 root_offset 向上画主干
	# 起始向上方向为 -90 度（即屏幕向上）
	draw_branch("t", root_offset, -90.0, initial_length, depth)

func clear_tree() -> void:
	lines.clear()
	for child in get_children():
		if child is Line2D:
			remove_child(child)
			child.queue_free()

func draw_branch(linename: String, start_pos: Vector2, angle_deg_local: float, length: float, depth_local: int) -> void:
	# 计算终点
	var rad = deg_to_rad(angle_deg_local)
	var dir = Vector2(cos(rad), sin(rad))
	var end_pos = start_pos + dir * length

	var line = null
	for existing_line in lines:
		if existing_line.name == linename:
			line = existing_line
			break
	
	# 创建 Line2D 节点表示这段分支
	if (line == null):
		line = Line2D.new()
		line.name = linename
		line.width = line_width
		line.default_color = line_color
		lines.append(line)
		add_child(line)

	# Line2D 的点使用相对于父节点（即此 Node2D）的局部坐标
	var old_start = start_pos
	var old_end = end_pos
	if line.get_point_count() >= 2:
		old_start = line.get_point_position(0)
		old_end = line.get_point_position(1)
		line.clear_points()
	line.add_point(start_pos)
	line.add_point(end_pos)
	for child in line.get_children():
		if child is Node2D:
			var p = (child.position - old_start).length() / (old_end - old_start).length()
			child.position = Vector2(start_pos.x + p * (end_pos.x - start_pos.x), start_pos.y + p * (end_pos.y - start_pos.y))

	# 递归终止条件：已经绘制此段后，如果 depth_local<=0 则不再继续
	if depth_local <= 0:
		return

	var next_length = length * length_scale
	var spread = angle_spread_deg

	# 三叉：左、中、右
	var p2 = 1.1
	if randf() < p2:
		draw_branch(linename + "l", end_pos, angle_deg_local - spread, next_length, depth_local - 1)
	if randf() < p2:
		draw_branch(linename + "m", end_pos, angle_deg_local, next_length, depth_local - 1)
	if randf() < p2:
		draw_branch(linename + "r", end_pos, angle_deg_local + spread, next_length, depth_local - 1)
