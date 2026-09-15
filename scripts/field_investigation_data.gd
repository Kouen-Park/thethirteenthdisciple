extends RefCounted

static func action(id: String, pos: Vector2, kind: String, label: String, result: String, requires: Array = [], item := "", hint := "주변의 흔적을 먼저 살펴보세요.", art := "") -> Dictionary:
	return {"id": id, "pos": pos, "kind": kind, "label": label, "result": result, "requires": requires, "item": item, "hint": hint, "art": art if not art.is_empty() else kind}

static func for_chapter(number: int) -> Array:
	if number in [2, 3]: return spatial_for_chapter(number)
	match number:
		1: return [
			action("road", Vector2(870, 620), "inspect", "길의 발자국 방향 살피기", "발자국은 성문을 향합니다. 환영의 가지를 놓을 곳은 길의 가장자리입니다."),
			action("palm_a", Vector2(520, 590), "pickup", "떨어진 종려 가지 들기", "가지를 들었습니다. 행렬이 지나갈 길의 가장자리에 놓아 주세요.", ["road"], "palm", "발자국을 먼저 살펴 길의 방향을 확인하세요.", "branch"),
			action("edge_a", Vector2(1040, 640), "place", "첫 번째 길 가장자리에 가지 놓기", "가지가 실제 길 위에 놓였습니다. 성문 쪽에도 환영의 길을 이어 봅시다.", ["palm_a"], "palm", "종려 가지를 들고 오세요."),
			action("palm_b", Vector2(750, 540), "pickup", "두 번째 가지 들기", "다음 가지는 성문 가까운 빈 곳으로 옮기면 됩니다.", ["edge_a"], "palm", "먼저 들고 있는 가지를 놓아 주세요.", "branch"),
			action("edge_b", Vector2(1250, 565), "place", "성문 가까이에 가지 놓기", "환영의 가지가 길을 따라 이어졌습니다.", ["palm_b"], "palm", "두 번째 가지가 필요합니다."),
			action("stand_back", Vector2(980, 665), "inspect", "행렬을 위해 한 걸음 물러서기", "길을 비웠습니다. 나귀를 타신 예수님이 다가오십니다.", ["edge_b"])
		]
		4: return [
			action("outer_echo", Vector2(1410, 640), "inspect", "군중 뒤편에서 들리는 말 기록", "뒤편에서는 유죄라는 외침만 들립니다. 질문과 판결은 문 가까이에서 확인해야 합니다."),
			action("listening_screen", Vector2(1160, 650), "push", "문 옆 시야를 가린 빈 받침 밀기", "문 옆으로 다가설 공간이 생겼습니다.", ["outer_echo"]),
			action("pilate_question", Vector2(1010, 495), "inspect", "문 가까이에서 총독의 질문 듣기", "빌라도는 예수님이 무슨 악한 일을 했느냐고 묻습니다. 군중의 외침은 그 질문의 답이 아닙니다. (마가복음 15:14 요약)", ["listening_screen"]),
			action("barabbas", Vector2(720, 625), "inspect", "풀려나는 죄수 쪽 확인", "풀려난 사람은 바라바입니다. 예수님과 같은 사람이 아닙니다. (마가복음 15:15)", ["pilate_question"]),
			action("verdict", Vector2(1550, 475), "inspect", "병사들이 나오는 문에서 판결 확인", "빌라도는 예수님을 십자가형에 넘겼습니다. 방금 들은 질문, 바라바의 석방, 예수님에 대한 판결을 구분해 기록합니다.", ["barabbas"]),
			action("safe_exit", Vector2(1810, 630), "inspect", "군중 가장자리의 통행로 확인", "아이와 함께 빠져나갈 길이 보입니다. 이제 내가 어디에 설지 선택할 수 있습니다.", ["verdict"])
		]
		5: return [
			action("slope", Vector2(960, 635), "inspect", "언덕 아래 좁아지는 통로 조사", "행렬은 이미 언덕 위로 올라갔습니다. 아래쪽에는 지친 사람들이 남아 있습니다."),
			action("obstruction", Vector2(1030, 650), "push", "통로에 걸린 빈 운반틀 밀기", "가장자리 통로가 열렸습니다. 목격자들이 서로 밀리지 않고 머물 수 있습니다.", ["slope"]),
			action("water_jar", Vector2(580, 620), "pickup", "주민을 위한 물 항아리 들기", "이 물은 언덕 아래 남은 사람들을 위한 것입니다.", [], "water", "", "jar"),
			action("water_shelter", Vector2(1330, 635), "place", "낮은 담의 그늘에 물 놓기", "물 항아리를 발길에서 벗어난 그늘에 두었습니다.", ["obstruction", "water_jar"], "water", "통로를 비우고 물 항아리를 가져오세요."),
			action("resting_mat", Vector2(850, 540), "pickup", "남은 깔개 들기", "무릎을 쉬게 할 깔개입니다. 혼자 서 있는 목격자 곁으로 가져갑니다.", ["water_shelter"], "rest", "물을 먼저 안전한 곳에 놓아 주세요.", "cloth"),
			action("beside_witness", Vector2(1550, 600), "place", "목격자 곁에 깔개 놓기", "아무 말 없이 앉을 자리를 마련했습니다.", ["resting_mat"], "rest", "깔개를 가져오세요."),
			action("look_hill", Vector2(1730, 510), "inspect", "함께 언덕 바라보기", "고개를 들어 언덕을 바라봅니다. 예수님의 죽음을 앞두고 하늘이 어두워집니다.", ["beside_witness"])
		]
		_: return [
			action("burial_place", Vector2(650, 625), "inspect", "장사 지점을 적은 기록 확인", "여자들은 예수님이 어디에 묻히셨는지 보아 두었습니다. 지금 살필 곳은 그 무덤입니다. (마가복음 15:47)"),
			action("stone", Vector2(1460, 625), "inspect", "이미 옮겨진 돌의 위치 확인", "돌은 이미 옮겨져 있습니다. 내가 밀어 열 필요가 없습니다. 입구로 다가가 안쪽을 살펴봅시다.", ["burial_place"]),
			action("entrance_view", Vector2(1620, 480), "inspect", "입구에서 무덤 안쪽 살피기", "시신이 놓였던 자리는 비어 있습니다. 안에는 세마포가 남아 있습니다. (요한복음 20:5–7)", ["stone"]),
			action("linen_view", Vector2(1540, 545), "inspect", "손대지 않고 세마포 위치 관찰", "몸을 쌌던 세마포와 머리를 쌌던 수건은 따로 놓여 있었습니다. 물건을 가져가지 않고 위치를 기록합니다.", ["entrance_view"], "", "입구에서 안쪽을 먼저 살펴보세요.", "linen"),
			action("women_report", Vector2(1030, 640), "inspect", "여자들이 전한 소식과 기록 대조", "빈 무덤에 대한 관찰과 예수님이 살아나셨다는 소식을 나누어 적었습니다. 마리아가 전한 만남의 이야기도 다시 확인해야겠습니다.", ["linen_view"]),
			action("mary_report", Vector2(1130, 500), "inspect", "막달라 마리아의 만남에 관한 증언 확인", "막달라 마리아는 부활하신 예수님을 만난 뒤 제자들에게 주님을 보았다고 전했습니다. (요한복음 20:18 요약)", ["women_report"]),
			action("return_road", Vector2(1820, 620), "inspect", "제자들에게 이어지는 길 확인", "무덤을 바라보던 걸음을 돌립니다. 예수님이 살아나셨다는 증언은 이제 다른 사람들에게 전해집니다.", ["mary_report"])
		]

static func spatial_for_chapter(number: int) -> Array:
	if number == 2:
		return [
			action("table_track", Vector2(1010, 630), "inspect", "긁힌 바닥 살피기", "받침 아래로 긁힌 자국이 이어진다. 주변에 받침을 옮겨 둘 빈 공간이 있다."),
			action("table_move", Vector2(1100, 620), "push", "받침 밀기 · E + 좌우 이동", "사람이 지나갈 공간이 생겼다."),
			action("coin_lot", Vector2(620, 610), "pickup", "흩어진 동전 모으기", "주인이 찾을 수 있도록 한곳에 모아 두자.", [], "coins", "", "coin"),
			action("return_coins", Vector2(790, 645), "place", "회수용 천", "동전을 천 위에 모았다.", [], "coins", "동전을 가져와 이곳에 놓을 수 있다.", "cloth"),
			action("mat", Vector2(1390, 530), "pickup", "말린 깔개 들기", "통로를 지나 깔개를 가져왔다.", [], "mat", "", "cloth"),
			action("prayer_space", Vector2(1580, 610), "place", "벽 곁의 빈 자리", "통행하는 길을 피해 깔개를 펼쳤다.", [], "mat", "깔개를 펼칠 만한 조용한 자리다."),
			action("listen_again", Vector2(1650, 475), "inspect", "가르침 되새기기", "예수님은 성전이 모든 민족이 기도하는 집이라고 가르치셨다. (마가복음 11:17 요약)")]
	return [
		action("oil", Vector2(990, 630), "inspect", "기름 자국 살피기", "희미한 자국이 담 아래로 이어진다. 어두워서 갈라지는 지점은 잘 보이지 않는다."),
		action("working_lamp", Vector2(850, 620), "pickup", "작은 등불 들기", "등불을 받침에 놓으면 방향을 바꾸며 바닥을 살필 수 있다.", [], "lamp", "", "lamp"),
		action("lamp_rest", Vector2(1330, 610), "place", "등불 받침 · 놓기 / 방향 바꾸기", "등불을 놓았다. E로 방향을 바꾸며 흔적을 살펴보자.", [], "lamp", "등불을 놓을 수 있는 받침이다."),
		action("side_path", Vector2(1330, 450), "inspect", "담 쪽의 발자국", "적은 수의 발자국이 막다른 담 쪽으로 흩어진다."),
		action("crowd_path", Vector2(1550, 610), "inspect", "큰길의 발자국", "여러 사람이 겹쳐 밟은 자국이 큰길로 이어진다."),
		action("torch_watch", Vector2(1640, 490), "inspect", "멀리 움직이는 횃불 살피기", "여럿이 든 횃불이 큰길 너머로 멀어진다. 바닥의 흔적과 같은 방향이다."),
		action("wrong_road", Vector2(1390, 430), "inspect", "담 아래 길 확인", "담에서 길이 막힌다. 돌아가 다른 흔적을 확인하자."),
		action("court_direction", Vector2(1850, 610), "inspect", "행렬이 향한 큰길", "흔적과 횃불이 이어지는 길에 도착했다.")]
