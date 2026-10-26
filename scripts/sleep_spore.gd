extends Node2D
# A drifting sleep spore (Napping Nimbus) or lullaby note (The Dreamer).
# Touching Lumi adds Drowse to the Sloth region. It never hurts directly.

var velocity := Vector2(0, 80)
var drowse := 15.0
var damage := 0           # hearts of damage on touch (0 for plain spores)
var life := 6.0
var wobble := 0.0         # sideways sine amplitude
var note := false         # draw as a music note
var t := 0.0
var base_x := 0.0

func _ready() -> void:
	add_to_group("enemy_projectile")
	base_x = position.x

func _process(delta: float) -> void:
	t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	position += velocity * delta
	if wobble > 0.0:
		position.y += sin(t * 3.0) * wobble * delta * 3.0
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and global_position.distance_to(player.global_position) < 24.0:
		var holder := get_tree().get_first_node_in_group("drowse_holder")
		if is_instance_valid(holder):
			holder.call("add_drowse", drowse)
		if damage > 0:
			player.take_damage(damage)
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var fade := minf(1.0, life / 0.6)
	if note:
		draw_circle(Vector2.ZERO, 9.0, Color(0.97, 0.91, 0.63, fade))
		draw_line(Vector2(8, 0), Vector2(8, -26), Color(0.97, 0.91, 0.63, fade), 3.0)
		draw_line(Vector2(8, -26), Vector2(18, -18), Color(0.97, 0.91, 0.63, fade), 3.0)
		draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 14, Color(0.2, 0.18, 0.4, fade), 2.0)
	else:
		draw_circle(Vector2.ZERO, 11.0, Color(0.72, 0.65, 0.92, 0.35 * fade))
		draw_circle(Vector2.ZERO, 7.0, Color(0.86, 0.82, 1.0, fade))
		draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 12, Color(0.2, 0.18, 0.4, fade), 2.0)
