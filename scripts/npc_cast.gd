class_name NPCCast
extends RefCounted

# Repeated texture paths are permitted only when continuity_id names the same person.
const ENTRIES := [
	{"chapter": 1, "id": &"merchant_jonah", "name": "상인 요나", "continuity_id": &"jonah", "path": "res://assets/art/pixel/npcs/merchant_jonah.png"},
	{"chapter": 1, "id": &"miriam", "name": "미리암", "continuity_id": &"miriam", "path": "res://assets/art/pixel/npcs/miriam.png"},
	{"chapter": 1, "id": &"crowd_elder", "name": "지팡이를 짚은 노인", "continuity_id": &"gate_elder", "path": "res://assets/art/pixel/npcs/crowd/elder.png"},
	{"chapter": 1, "id": &"crowd_potter", "name": "젊은 도공", "continuity_id": &"gate_potter", "path": "res://assets/art/pixel/npcs/crowd/potter.png"},
	{"chapter": 1, "id": &"crowd_weaver", "name": "직물을 든 여인", "continuity_id": &"gate_weaver", "path": "res://assets/art/pixel/npcs/crowd/weaver.png"},
	{"chapter": 1, "id": &"crowd_porter", "name": "짐꾼", "continuity_id": &"gate_porter", "path": "res://assets/art/pixel/npcs/crowd/porter.png"},
	{"chapter": 1, "id": &"crowd_traveler", "name": "여행자", "continuity_id": &"gate_traveler", "path": "res://assets/art/pixel/npcs/crowd/traveler.png"},
	{"chapter": 1, "id": &"crowd_mother", "name": "두 손을 모은 노부인", "continuity_id": &"gate_mother", "path": "res://assets/art/pixel/npcs/crowd/mother.png"},
	{"chapter": 1, "id": &"crowd_youth", "name": "길가의 청년", "continuity_id": &"gate_youth", "path": "res://assets/art/pixel/npcs/crowd/youth.png"},
	{"chapter": 1, "id": &"crowd_pilgrim", "name": "바구니를 든 순례자", "continuity_id": &"gate_pilgrim", "path": "res://assets/art/pixel/npcs/crowd/pilgrim.png"},
	{"chapter": 2, "id": &"merchant_jonah", "name": "상인 요나", "continuity_id": &"jonah", "path": "res://assets/art/pixel/npcs/merchant_jonah.png"},
	{"chapter": 2, "id": &"miriam", "name": "미리암", "continuity_id": &"miriam", "path": "res://assets/art/pixel/npcs/miriam.png"},
	{"chapter": 2, "id": &"temple_guard", "name": "성전 경비", "continuity_id": &"temple_guard", "path": "res://assets/art/pixel/npcs/temple_guard.png"},
	{"chapter": 3, "id": &"miriam_day", "name": "미리암", "continuity_id": &"miriam", "path": "res://assets/art/pixel/npcs/miriam.png"},
	{"chapter": 3, "id": &"miriam_night", "name": "미리암", "continuity_id": &"miriam", "path": "res://assets/art/pixel/npcs/miriam.png"},
	{"chapter": 3, "id": &"jonah_day", "name": "상인 요나", "continuity_id": &"jonah", "path": "res://assets/art/pixel/npcs/merchant_jonah.png"},
	{"chapter": 3, "id": &"jonah_night", "name": "상인 요나", "continuity_id": &"jonah", "path": "res://assets/art/pixel/npcs/merchant_jonah.png"},
	{"chapter": 3, "id": &"waiting_traveler", "name": "갈릴리에서 온 순례자", "continuity_id": &"well_pilgrim", "path": "res://assets/art/pixel/npcs/well_pilgrim.png"},
	{"chapter": 3, "id": &"frightened_runner", "name": "도망쳐 온 청년", "continuity_id": &"frightened_runner", "path": "res://assets/art/pixel/npcs/frightened_runner.png"},
	{"chapter": 3, "id": &"guard_relative", "name": "성전 경비의 친척", "continuity_id": &"guard_relative", "path": "res://assets/art/pixel/npcs/guard_relative.png"},
	{"chapter": 4, "id": &"fireplace", "name": "뜰에서 온 하녀", "continuity_id": &"courtyard_servant", "path": "res://assets/art/biblical_cast/servant.png"},
	{"chapter": 4, "id": &"passerby", "name": "로마 병사", "continuity_id": &"trial_soldier", "path": "res://assets/art/biblical_cast/soldier.png"},
	{"chapter": 4, "id": &"crowd_echo", "name": "재판장 안내인", "continuity_id": &"trial_herald", "path": "res://assets/art/biblical_cast/herald.png"},
	{"chapter": 4, "id": &"mother", "name": "예루살렘의 어머니", "continuity_id": &"trial_mother", "path": "res://assets/art/biblical_cast/mother.png"},
	{"chapter": 5, "id": &"silent_witness", "name": "막달라 마리아", "continuity_id": &"mary_magdalene", "path": "res://assets/art/biblical_cast/mary.png"},
	{"chapter": 5, "id": &"traveler", "name": "구레네 사람 시몬", "continuity_id": &"simon_of_cyrene", "path": "res://assets/art/biblical_cast/simon.png"},
	{"chapter": 6, "id": &"rumor_market", "name": "살로메", "continuity_id": &"salome", "path": "res://assets/art/biblical_cast/salome.png"},
	{"chapter": 6, "id": &"miriam_testimony", "name": "막달라 마리아", "continuity_id": &"mary_magdalene", "path": "res://assets/art/biblical_cast/mary.png"}
]

static func reuse_conflicts() -> Array[String]:
	var owners: Dictionary = {}
	var conflicts: Array[String] = []
	for entry: Dictionary in ENTRIES:
		var path: String = entry.path
		var identity: StringName = entry.continuity_id
		if owners.has(path) and owners[path] != identity:
			conflicts.append("%s: %s / %s" % [path, owners[path], identity])
		else:
			owners[path] = identity
	return conflicts
