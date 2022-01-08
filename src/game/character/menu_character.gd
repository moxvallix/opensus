extends Node2D

onready var sprite: Sprite = $ViewportSprite

func setOutline(color: Color) -> void:
	sprite.material.set_shader_param("line_color", color)
