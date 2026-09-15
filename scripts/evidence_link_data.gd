extends RefCounted

static func get_data(number: int) -> Dictionary:
	match number:
		4:
			return {
				"instruction": "재판장의 말과 행동을 연결하세요. 한 기록에서 E를 누른 뒤 관련 기록까지 걸어가 E를 누릅니다.",
				"destination": Vector2(1810, 620),
				"destination_label": "판결이 집행된 성 밖 길",
				"sources": [
					_source("pilate_question", Vector2(900, 500), "빌라도의 질문", "빌라도는 예수님이 무슨 악한 일을 했느냐고 물었다. (마가복음 15:14 요약)", "question"),
					_source("crowd_demand", Vector2(1260, 570), "군중의 요구", "군중은 질문에 죄목을 답하지 않고 십자가에 못 박으라고 더욱 외쳤다. (마가복음 15:13–14 요약)", "voices"),
					_source("barabbas_release", Vector2(1420, 620), "바라바의 석방", "빌라도는 군중이 요구한 바라바를 풀어 주었다. (마가복음 15:15 요약)", "gate"),
					_source("verdict_handover", Vector2(1580, 485), "예수님을 넘긴 판결", "빌라도는 예수님을 채찍질하고 십자가에 못 박히도록 넘겨주었다. (마가복음 15:15 요약)", "escort")
				],
				"links": [
					_link("pilate_question", "crowd_demand", "총독의 질문과 군중의 외침을 구분했다. 외침은 ‘무슨 악을 행했는가’라는 질문의 답이 아니었다."),
					_link("barabbas_release", "verdict_handover", "같은 판결 자리에서 바라바는 풀려나고 예수님은 십자가형에 넘겨졌다.")
				],
				"hints": ["먼저 질문과 그 뒤에 나온 군중의 반응을 연결해 보세요.", "석방된 사람과 형벌에 넘겨진 사람을 서로 구분해 기록하세요.", "두 연결이 완성되면 성 밖으로 이어지는 오른쪽 길까지 직접 걸어가세요."]
			}
		5:
			return {
				"instruction": "골고다로 이어진 흔적과 현장의 행동을 연결하세요.",
				"destination": Vector2(1770, 610),
				"destination_label": "십자가 아래에서 바라볼 자리",
				"sources": [
					_source("forced_simon", Vector2(760, 600), "시몬이 붙들린 자리", "시골에서 오던 구레네 사람 시몬은 예수님의 십자가를 지도록 강요받았다. (마가복음 15:21 요약)", "person"),
					_source("crossbeam_marks", Vector2(1040, 575), "골고다로 이어진 무거운 자국", "무거운 나무를 끌고 간 흔적이 골고다 방향으로 이어진다.", "trail"),
					_source("divided_garments", Vector2(1320, 600), "나누어진 옷과 제비", "병사들은 예수님의 옷을 나누며 제비를 뽑았다. (마가복음 15:24 요약)", "cloth"),
					_source("soldier_post", Vector2(1570, 555), "십자가 곁의 병사들", "형을 집행한 병사들이 십자가 곁을 지키고 있다.", "soldier")
				],
				"links": [
					_link("forced_simon", "crossbeam_marks", "시몬이 진 십자가의 흔적이 예수님을 끌고 간 골고다 길로 이어진다."),
					_link("divided_garments", "soldier_post", "옷을 나누고 제비를 뽑은 이들은 형을 집행하던 병사들이었다.")
				],
				"hints": ["시몬에게 일어난 일과 길에 남은 무거운 흔적을 연결하세요.", "옷 곁의 흔적을 십자가를 지키는 사람들과 연결하세요.", "연결을 마치면 오른쪽의 머물 자리까지 걸어가세요."]
			}
		_:
			return {
				"instruction": "무덤에서 확인한 상태와 사람들이 전한 증언을 출처에 맞게 연결하세요.",
				"destination": Vector2(1810, 620),
				"destination_label": "제자들에게 돌아가는 길",
				"sources": [
					_source("burial_record", Vector2(620, 610), "여자들이 보아 둔 장사 장소", "막달라 마리아와 요세의 어머니 마리아는 예수님을 모신 곳을 보았다. (마가복음 15:47 요약)", "record"),
					_source("moved_stone", Vector2(1390, 615), "옮겨진 돌", "여자들이 도착했을 때 매우 큰 돌은 이미 옮겨져 있었다. (마가복음 16:4 요약)", "stone"),
					_source("empty_place", Vector2(1580, 485), "시신이 놓였던 빈자리", "예수님의 시신이 놓였던 자리는 비어 있었다.", "tomb"),
					_source("linen_order", Vector2(1490, 555), "남겨진 세마포", "세마포와 머리를 쌌던 수건은 따로 놓여 있었다. (요한복음 20:5–7 요약)", "linen"),
					_source("women_message", Vector2(930, 610), "여자들이 들은 소식", "여자들은 예수님이 살아나셨다는 소식을 들었다. (마가복음 16:6 요약)", "voices"),
					_source("mary_witness", Vector2(1130, 490), "막달라 마리아의 만남", "막달라 마리아는 부활하신 예수님을 만났고 제자들에게 주님을 보았다고 전했다. (요한복음 20:11–18 요약)", "person")
				],
				"links": [
					_link("burial_record", "moved_stone", "여자들이 기억한 바로 그 무덤에서 돌이 옮겨진 것을 확인했다."),
					_link("empty_place", "linen_order", "빈자리와 남겨진 세마포의 위치를 함께 기록했다."),
					_link("women_message", "mary_witness", "무덤에서 들은 부활의 소식은 마리아가 부활하신 예수님을 만난 증언으로 이어졌다.")
				],
				"hints": ["장사 장소를 기억한 기록과 지금 보이는 무덤 입구를 연결하세요.", "무덤 안의 빈자리와 남겨진 세마포를 함께 살펴보세요.", "여자들이 들은 소식과 마리아가 직접 만났다고 전한 증언을 구분해 연결하세요."]
			}

static func _source(id: String, position: Vector2, label: String, detail: String, art: String) -> Dictionary:
	return {"id": id, "pos": position, "label": label, "detail": detail, "art": art}

static func _link(first: String, second: String, result: String) -> Dictionary:
	return {"first": first, "second": second, "result": result}
