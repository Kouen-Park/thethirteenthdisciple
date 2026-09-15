extends Node2D

const OPINIONS := {
	"elder": ["지팡이를 짚은 노인", "나는 왕을 기다리며 늙었지. 저분은 군사도 칼도 없구나. 내가 기다린 왕과는 다르지만… 그래서 더 지켜보고 싶네."],
	"potter": ["젊은 도공", "사람들이 기적 이야기를 하더군요. 직접 보지 않은 일까지 믿기는 어려워요. 그분이 실제로 무엇을 하는지 보고 판단하려고요."],
	"weaver": ["직물을 든 여인", "내 이웃은 아무도 가까이하지 않던 사람과 그분이 함께 앉았다고 했어요. 내게는 왕이라는 소문보다 그 이야기가 더 크게 들려요."],
	"porter": ["짐꾼", "이렇게 사람들이 모이면 경비병도 몰려와. 좋은 뜻으로 온 사람일지 몰라도, 소란의 대가는 우리 같은 사람들이 치른다고."],
	"traveler": ["여행자", "어느 마을에서는 스승이라 하고, 다른 곳에서는 위험한 사람이라 하더군. 같은 사람을 보고도 왜 이렇게 말이 다른 걸까?"],
	"mother": ["두 손을 모은 노부인", "나는 아픈 가족이 있어요. 저분이 우리에게도 멈춰 주실까, 그 생각뿐이에요. 누군가에겐 큰 사건이겠지만 내게는 작은 바람이지요."],
	"youth": ["길가의 청년", "저분이 우리를 억누르는 사람들을 몰아내 주면 좋겠어요. 그런데 나귀를 타고 조용히 오시네요. 내가 기대한 싸움을 하러 온 건 아닌 걸까요?"],
	"pilgrim": ["바구니를 든 순례자", "나는 절기를 지키러 왔어요. 환호도 비난도 너무 빨리 따라가고 싶지는 않아요. 성전에서 무슨 말씀을 하시는지 먼저 듣고 싶어요."]
}

# Each resident owns a whole texture, shadow and collision body; never split artwork.
const RESIDENTS := [
	["elder", Vector2(760, 410), Vector2(690, 410)],
	["potter", Vector2(560, 470), Vector2(510, 470)],
	["weaver", Vector2(920, 450), Vector2(850, 450)],
	["porter", Vector2(1180, 440), Vector2(1250, 440)],
	["traveler", Vector2(285, 655), Vector2(240, 655)],
	["mother", Vector2(1180, 680), Vector2(1220, 680)],
	["youth", Vector2(1570, 660), Vector2(1620, 665)],
	["pilgrim", Vector2(1840, 520), Vector2(1900, 560)]
]

func _ready() -> void:
	for data in RESIDENTS:
		var resident := StaticBody2D.new()
		resident.name = data[0]
		resident.position = data[1]
		resident.set_meta("parted_position", data[2])
		add_child(resident)
		var shadow := Polygon2D.new()
		shadow.polygon = PackedVector2Array([Vector2(-13, -3), Vector2(-7, -6), Vector2(8, -6), Vector2(14, -3), Vector2(8, 0), Vector2(-7, 0)])
		shadow.color = Color(0.12, 0.08, 0.04, 0.22)
		resident.add_child(shadow)
		var texture := load("res://assets/art/pixel/npcs/crowd/%s.png" % data[0]) as Texture2D
		# Trim transparent canvas in the renderer, preserving the generated source PNG.
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = texture.get_image().get_used_rect()
		var sprite := Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = atlas
		sprite.flip_h = resident.position.x < 1024.0
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var height := 64.0
		sprite.scale = Vector2.ONE * height / atlas.region.size.y
		sprite.position.y = -height * 0.5
		resident.add_child(sprite)
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = Vector2(22, 12)
		collision.shape = shape
		collision.position.y = -6
		resident.add_child(collision)
		resident.set_meta("head_offset", Vector2(0, -68))
		resident.set_meta("display_name", OPINIONS[data[0]][0])
		var interaction := InteractableComponent.new()
		interaction.name = "Conversation"
		interaction.interaction_id = StringName("crowd_" + data[0])
		interaction.prompt_text = OPINIONS[data[0]][0] + "의 생각 듣기 (선택)"
		interaction.description = OPINIONS[data[0]][1]
		interaction.interaction_enabled = false
		interaction.dim_on_use = false
		var area_shape := CollisionShape2D.new()
		area_shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = 32.0
		area_shape.shape = circle
		interaction.add_child(area_shape)
		resident.add_child(interaction)
		interaction.focus_changed.connect(func(focused: bool): sprite.modulate = Color(1.18, 1.08, 0.8) if focused else Color.WHITE)

func conversations() -> Array[Node]:
	var result: Array[Node] = []
	for resident in get_children():
		result.append(resident.get_node("Conversation"))
	return result

func unlock_conversations() -> void:
	for interaction in conversations():
		interaction.interaction_enabled = true

func add_parting_tracks(tween: Tween) -> void:
	for i in get_child_count():
		var resident := get_child(i) as Node2D
		# Stagger reactions so people step aside rather than two panels sliding apart.
		tween.tween_property(resident, "position", resident.get_meta("parted_position"), 1.25 + 0.1 * (i % 3)).set_delay(0.07 * i)
