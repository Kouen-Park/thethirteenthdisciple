class_name StoryData
extends RefCounted

const CHAPTER_ONE_OPENING := [
	"성전에 가는 길인데… 오늘은 성문 앞이 왜 이렇게 소란스럽지?",
	"사람들이 한쪽으로 몰려간다. 장날이라기엔 들려오는 말들이 낯설다.",
	"누군가를 기다리는 걸까? 길가 사람들에게 무슨 일인지 물어보자."
]

## 조건 기반 월드 내러티브의 공개 데이터 계약입니다.
## 1장은 beats를 실제 플레이 루프에 사용하며, lines는 후속 장 제작 중 호환을 위해 임시 유지합니다.
const CHAPTER_BEATS := {
	"chapter_01": [
		{"id": &"arrival", "completion": &"intro_dismissed", "next": &"approach"},
		{"id": &"approach", "completion": &"required_interactions", "required": [&"palm_leaf", &"discarded_cloak", &"footprints", &"merchant_jonah", &"miriam"], "next": &"encounter"},
		{"id": &"encounter", "completion": &"world_dialogue_finished", "next": &"aftermath"},
		{"id": &"aftermath", "completion": &"temple_entrance_entered", "optional_interactions": [&"crowd_elder", &"crowd_potter", &"crowd_weaver", &"crowd_porter", &"crowd_traveler", &"crowd_mother", &"crowd_youth", &"crowd_pilgrim"], "next": &"complete"}
	],
	"chapter_02": [
		{"id": &"arrival", "completion": &"intro_dismissed", "next": &"investigation"},
		{"id": &"investigation", "completion": &"requirement_groups", "requirements": [
			{"ids": [&"scattered_coins", &"empty_table", &"prayer_corner"], "minimum": 2},
			{"ids": [&"merchant_jonah", &"miriam"], "minimum": 2}
		], "next": &"reflection"},
		{"id": &"reflection", "completion": &"choice_recorded", "next": &"aftermath"},
		{"id": &"aftermath", "completion": &"temple_exit_entered", "optional_interactions": [&"temple_guard"], "next": &"complete"}
	],
	"chapter_03": [
		{"id": &"arrival", "completion": &"intro_dismissed", "next": &"day_waiting"},
		{"id": &"day_waiting", "completion": &"required_interactions", "required": [&"waiting_well", &"waiting_cloth", &"miriam_day"], "optional_interactions": [&"jonah_day", &"waiting_traveler"], "next": &"dusk"},
		{"id": &"dusk", "completion": &"wait_until_night", "next": &"night_rumors"},
		{"id": &"night_rumors", "completion": &"requirement_groups", "requirements": [
			{"ids": [&"broken_lantern", &"drag_marks", &"abandoned_sandal"], "minimum": 3},
			{"ids": [&"miriam_night", &"jonah_night"], "minimum": 1}
		], "optional_interactions": [&"closed_door", &"frightened_runner", &"guard_relative"], "next": &"route"},
		{"id": &"route", "completion": &"route_connected", "next": &"reflection"},
		{"id": &"reflection", "completion": &"choice_recorded", "next": &"aftermath"},
		{"id": &"aftermath", "completion": &"court_road_entered", "next": &"complete"}
	],
	"chapter_04": [{"id": &"trial_crowd", "completion": &"required_interactions", "next": &"complete"}],
	"chapter_05": [{"id": &"silent_witnesses", "completion": &"required_interactions", "next": &"complete"}],
	"chapter_06": [{"id": &"empty_tomb_testimonies", "completion": &"required_interactions", "next": &"complete"}]
}

static func get_beats(chapter_id: StringName) -> Array:
	return CHAPTER_BEATS.get(String(chapter_id), []).duplicate(true)

const CHAPTERS := [
	{
		"title": "제1장 · 군중 속의 낯선 사람",
		"place": "예루살렘 성문 밖 언덕길 · 종려주일",
		"palette": {"sky": Color("#d9a85f"), "ground": Color("#9b6045"), "accent": Color("#f3d58b")},
		"lines": [
			{"speaker": "나", "text": "오늘은 일찍 돌아가야 한다. 시장은 벌써 너무 시끄럽다.", "event": "intro_whisper", "sound": "wind_only"},
			{"speaker": "나", "text": "...방금 누군가 이 길을 지나간 것 같은데.", "event": "distant_witness", "sound": "distant_steps"},
			{"speaker": "나", "text": "저 아래에서 무슨 일이 벌어지는 거지?", "sound": "footsteps"},
			{"speaker": "나", "text": "무엇을 먼저 살펴볼까?", "interaction": {"type": "observation", "title": "흔적 살펴보기", "instruction": "주변의 흔적을 조사해 보세요.", "options": [{"id": "palm_leaf", "label": "길 위의 종려잎", "description": "흙먼지가 잎맥 사이에 박혀 있다. 누군가 급하게 내려놓은 듯하다."}, {"id": "discarded_cloak", "label": "벗겨진 겉옷", "description": "옷자락에는 먼지가 묻어 있다. 주인은 옷보다 환호를 먼저 택한 모양이다."}, {"id": "footprints", "label": "성문으로 향한 발자국", "description": "발자국이 하나의 방향으로 몰려 있다. 보이지 않는 무언가를 따라간 흔적이다."}]}},
			{"speaker": "나", "text": "사람들은 저 사람을 기다리고 있다. 하지만 누구도 같은 말을 하지는 않는다."},
			{"speaker": "상인 요나", "text": "갈릴리에서 온 떠돌이 설교자야. 오늘은 왕이라도 된 줄 아는 모양이지."},
			{"speaker": "미리암", "text": "내 동생은 그분이 아픈 사람의 손을 잡는 걸 봤대. 왕처럼 굴지는 않았다고 하더라."},
			{"speaker": "나", "text": "소문만으로는 알 수 없다. 직접 봐야겠다.", "sound": "crowd_swell"},
			{"speaker": "나", "text": "나도 이 길에 잎을 놓을까?", "interaction": {"type": "palm_drag", "title": "길을 준비하기", "instruction": "종려잎 세 장을 길 위에 놓으세요.", "required": 3}},
			{"speaker": "나", "text": "사람들이 양옆으로 물러섰다. 길 하나가 조용히 열렸다.", "event": "path_opens", "sound": "crowd_part"},
			{"speaker": "나", "text": "먼저 발소리가 들렸다. 그 다음, 모두의 시선이 한 곳에 멈췄다."},
			{"speaker": "나", "text": "저 사람이... 사람들이 기다리던 사람인가?", "event": "reveal_characters"},
			{"speaker": "예수", "text": "당신도 길을 내어 주었군요."},
			{"speaker": "나", "text": "사람들은 당신을 왜 기다리고 있습니까?", "event": "focus_jesus"},
			{"speaker": "예수", "text": "사람마다 기다리는 것이 다르지요. 당신은 무엇을 기다립니까?", "choices": ["사람들을 기다립니다.", "저 자신을 기다립니다."], "responses": [{"speaker": "나", "text": "사람들이 어디로 가는지 보고 싶습니다."}, {"speaker": "나", "text": "아직 제 마음도 잘 모르겠습니다."}]},
			{"speaker": "나", "text": "...아직은 모르겠습니다."},
			{"speaker": "나", "text": "나는 그분을 몰랐다. 하지만 오늘 본 것을 그냥 소문이라고 부르고 싶지는 않았다.", "event": "crowd_fade"}
		]
	},
	{
		"title": "제2장 · 성전의 소음",
		"place": "예루살렘 성전 바깥 시장",
		"palette": {"sky": Color("#c18a55"), "ground": Color("#73504a"), "accent": Color("#e7c47b")},
		"lines": [
			{"speaker": "나", "text": "환호하던 사람을 따라왔지만, 내가 도착했을 때는 이미 소란이 끝나 있었다."},
			{"speaker": "나", "text": "그가 떠난 자리에는 말보다 더 오래 남은 것들이 있다."}
		]
	},
	{
		"title": "제3장 · 기다림 뒤에 남은 발소리",
		"place": "예루살렘 외곽의 우물과 감람산에서 내려오는 길",
		"palette": {"sky": Color("#b7a078"), "ground": Color("#76685d"), "accent": Color("#e7d3a2")},
		"lines": [
			{"speaker": "나", "text": "낮에는 그분을 기다리던 자리가 비어 있었다. 밤이 되자 그 자리로 급한 발소리가 돌아왔다.", "sound": "wind_only"},
			{"speaker": "나", "text": "우물가의 기다림과 골목에 남은 체포의 흔적을 이어 보자.", "interaction": {"type": "observation", "title": "낮과 밤의 흔적", "instruction": "사람들이 남긴 흔적을 조사하세요.", "options": [{"id": "waiting_well", "label": "물을 나눈 우물", "description": "낮 동안 누군가 오래 기다린 흔적이 남아 있다."}, {"id": "broken_lantern", "label": "부서진 등불", "description": "급히 버린 등불 아래로 기름이 한 방향으로 번졌다."}, {"id": "drag_marks", "label": "골목의 끌린 흔적", "description": "여러 사람이 한 사람을 에워싸고 재판장 쪽으로 지나갔다."}, {"id": "abandoned_sandal", "label": "버려진 신발", "description": "달아나던 누군가가 신발 한 짝을 남겼다."}]}},
			{"speaker": "미리암", "text": "낮에는 기다렸고, 밤에는 모두가 문을 닫았어."},
			{"speaker": "상인 요나", "text": "체포가 정당하다면 왜 이렇게 어둠 속에서 서둘렀겠나."},
			{"speaker": "나", "text": "등불과 기름 자국이 가리키는 길을 이어 보자.", "puzzle": {"id": &"lantern_route", "title": "밤의 이동 경로", "steps": [
				{"prompt": "행렬이 출발한 흔적은?", "answer": &"broken_lantern", "hint": "가장 먼저 버려진 빛을 찾자.", "options": [{"id": &"broken_lantern", "label": "부서진 등불"}, {"id": &"drag_marks", "label": "끌린 흔적"}, {"id": &"abandoned_sandal", "label": "버려진 신발"}]},
				{"prompt": "여러 사람이 한 사람을 에워싼 방향은?", "answer": &"drag_marks", "hint": "땅 위에 길게 이어진 자국이 있다.", "options": [{"id": &"broken_lantern", "label": "등불"}, {"id": &"drag_marks", "label": "끌린 흔적"}, {"id": &"abandoned_sandal", "label": "신발"}]},
				{"prompt": "누군가 행렬에서 달아난 마지막 흔적은?", "answer": &"abandoned_sandal", "hint": "급히 떠난 사람은 한 짝을 챙기지 못했다.", "options": [{"id": &"broken_lantern", "label": "등불"}, {"id": &"drag_marks", "label": "끌린 흔적"}, {"id": &"abandoned_sandal", "label": "버려진 신발"}]}
			]}},
			{"speaker": "나", "text": "기름 자국과 발소리는 재판장 방향으로 이어진다."},
			{"speaker": "나", "text": "나는 그 소리를 따라갈지, 멀리 설지, 달아나는 사람을 도울지 정해야 했다.", "choices": ["소리를 따라간다", "거리를 두고 지켜본다", "달아나는 청년을 돕는다"], "choice_ids": [&"followed_sound", &"stayed_back", &"helped_runner"], "responses": [{"speaker": "나", "text": "발소리를 놓치지 않고 재판장 쪽으로 향했다."}, {"speaker": "나", "text": "보이지 않을 만큼 멀어지지는 않되, 군중과 거리를 두었다."}, {"speaker": "나", "text": "넘어진 청년이 다시 달릴 수 있도록 손을 내밀었다."}], "event": "prepare_exit"}
		]
	},
	{
		"title": "제4장 · 서로 다른 외침",
		"place": "재판장 바깥 · 동틀 무렵",
		"palette": {"sky": Color("#3b3a4e"), "ground": Color("#51454a"), "accent": Color("#d6a46c")},
		"lines": [
			{"speaker": "나", "text": "며칠 전 왕이라 부르던 사람들이 오늘은 다른 이름을 외치고 있다.", "sound": "wind_only"},
			{"speaker": "나", "text": "누가 먼저 외치기 시작했는지, 그 목소리가 어디서 오는지 찾아가 보자.", "interaction": {"type": "observation", "title": "외침의 근원", "instruction": "골목에 남은 목소리의 흔적을 조사하세요.", "options": [{"id": "torch", "label": "꺼져 가는 횃불", "description": "불빛이 흔들릴 때마다 사람들의 얼굴이 다른 표정으로 보인다."}, {"id": "closed_door", "label": "닫힌 문", "description": "문 안에서는 숨죽인 목소리가 들리지만 아무도 나오지 않는다."}, {"id": "crowd_echo", "label": "벽에 남은 외침", "description": "같은 말이 여러 사람의 입을 거치며 조금씩 달라졌다."}]}},
			{"speaker": "행인", "text": "저 사람도 그와 함께 있었잖소?"},
			{"speaker": "나", "text": "총독의 질문, 군중의 요구, 실제 판결을 현장에서 연결해 보자.", "puzzle": {"id": &"trial_evidence_links", "title": "재판장의 기록 연결", "steps": [
				{"prompt": "가장 먼저 들린 말은?", "answer": &"question", "hint": "처음의 목소리는 아직 단정하지 않았다.", "options": [{"id": &"verdict", "label": "그는 유죄다"}, {"id": &"question", "label": "그가 무엇을 했나?"}, {"id": &"chant", "label": "끌고 가라"}]},
				{"prompt": "질문 뒤에 퍼진 단정은?", "answer": &"verdict", "hint": "사실을 묻던 말이 곧 결론으로 변했다.", "options": [{"id": &"question", "label": "무엇을 했나?"}, {"id": &"verdict", "label": "그는 유죄다"}, {"id": &"chant", "label": "끌고 가라"}]},
				{"prompt": "마지막에 군중이 함께 외친 말은?", "answer": &"chant", "hint": "한 사람의 단정이 모두의 행동을 재촉했다.", "options": [{"id": &"question", "label": "질문"}, {"id": &"verdict", "label": "단정"}, {"id": &"chant", "label": "끌고 가라"}]}
			]}},
			{"speaker": "나", "text": "나는 그분을 잘 알지 못합니다."},
			{"speaker": "나", "text": "그 말은 거짓말은 아니었다. 하지만 침묵도 진실의 일부일까?"},
			{"speaker": "나", "text": "그분과 눈이 마주쳤다. 질문할 시간은 없었다.", "event": "reveal_characters"},
			{"speaker": "나", "text": "판결 뒤, 나는 어디에서 무엇을 할 것인가?", "choices": ["아이와 주민을 안전한 길로 돕는다", "판결이 집행되는 자리에 남아 기록한다", "군중 가장자리에서 기도한다"], "choice_ids": [&"protected_family", &"recorded_verdict", &"prayed_at_edge"], "responses": [{"speaker": "나", "text": "아이를 데리고 나온 주민과 함께 담을 따라 열린 길로 움직였다."}, {"speaker": "나", "text": "바라바가 풀려나고 예수님이 십자가형에 넘겨진 일을 분명히 기록했다."}, {"speaker": "나", "text": "외침과 행렬에서 한 걸음 물러나, 그 길을 바라보며 기도했다."}], "event": "prepare_exit"}
		]
	},
	{
		"title": "제5장 · 끝까지 바라본 사람들",
		"place": "골고다 언덕 아래 · 빛이 흐려지는 오후",
		"palette": {"sky": Color("#77727a"), "ground": Color("#554d4e"), "accent": Color("#c2a18a")},
		"lines": [
			{"speaker": "나", "text": "나는 그분을 따라간 것이 아니다. 사람들이 오늘 무엇을 외치는지 확인하러 왔다.", "sound": "wind_only"},
			{"speaker": "나", "text": "길 위에 남은 작은 것들을 치워 보자.", "interaction": {"type": "observation", "title": "끝까지 바라보기", "instruction": "길가의 작은 흔적을 조사하세요.", "options": [{"id": "empty_bowl", "label": "비어 있는 그릇", "description": "누군가 물을 건네고 그릇만 돌려받지 못했다."}, {"id": "fallen_cloth", "label": "떨어진 천 조각", "description": "사람이 밀려난 자리에서 천 조각이 찢겨 있다."}, {"id": "silent_witness", "label": "고개를 돌린 사람", "description": "끝까지 보았지만 아무 말도 하지 않는 사람이 서 있다."}]}},
			{"speaker": "나", "text": "시몬의 길과 십자가 아래 병사들의 행동을 흔적으로 연결하자.", "puzzle": {"id": &"passion_evidence_links", "title": "골고다 길의 흔적", "steps": [
				{"prompt": "아이와 노인이 지나갈 수 있도록 먼저 비울 곳은?", "answer": &"edge", "hint": "행렬의 중심보다 가장자리에 작은 길이 남아 있다.", "options": [{"id": &"center", "label": "행렬 한가운데"}, {"id": &"edge", "label": "길 가장자리"}, {"id": &"hill", "label": "언덕 위"}]},
				{"prompt": "물을 놓아도 사람에게 밟히지 않을 곳은?", "answer": &"wall", "hint": "사람의 흐름과 닿으면서도 발길에서 벗어난 곳을 찾자.", "options": [{"id": &"road", "label": "길 중앙"}, {"id": &"wall", "label": "낮은 담 옆"}, {"id": &"crowd", "label": "군중 뒤"}]}
			]}},
			{"speaker": "나", "text": "지금 내가 할 수 있는 작은 행동을 고른다.", "choices": ["물을 길가에 둔다", "혼자 선 사람 곁에 선다", "멀리서 끝까지 바라본다"], "choice_ids": [&"offered_water", &"stood_beside", &"kept_watching"], "responses": [{"speaker": "나", "text": "누가 마실지는 몰라도 그릇을 손이 닿는 곳에 두었다."}, {"speaker": "나", "text": "아무 말 없이 혼자 선 사람의 곁을 지켰다."}, {"speaker": "나", "text": "고개를 돌리지 않고 사람들이 떠날 때까지 남았다."}]},
			{"speaker": "나", "text": "그분이 마지막으로 사람들을 바라보았다. 나는 그 시선을 피하지 못했다.", "event": "focus_jesus"},
			{"speaker": "나", "text": "그분이 특별한 사람인지 아직 확신할 수 없다. 하지만 마지막 순간의 눈빛은 잊히지 않는다.", "event": "crowd_fade"}
		]
	},
	{
		"title": "제6장 · 빈자리의 증언",
		"place": "무덤으로 향하는 정원 · 사흘 뒤 새벽",
		"palette": {"sky": Color("#8db4c7"), "ground": Color("#677b72"), "accent": Color("#f1dfad")},
		"lines": [
			{"speaker": "나", "text": "사흘 뒤, 사람들은 또 다른 이야기를 시작했다. 이번에는 그분의 몸이 사라졌다는 이야기였다.", "sound": "wind_only"},
			{"speaker": "나", "text": "빈 무덤보다 먼저, 사람들이 무엇을 보았다고 말하는지 들어 보자.", "interaction": {"type": "observation", "title": "빈자리의 증언", "instruction": "서로 다른 증언을 조사하세요.", "options": [{"id": "empty_tomb", "label": "열린 무덤", "description": "돌문은 옆으로 밀려 있고, 안쪽에는 아무것도 없다."}, {"id": "miriam_testimony", "label": "미리암의 증언", "description": "미리암은 자신이 본 것을 말하지만, 아무도 쉽게 믿어 주지 않는다."}, {"id": "rumor_market", "label": "시장에 퍼진 소문", "description": "훔쳐 갔다는 말과 살아났다는 말이 서로 겹쳐 들린다."}]}},
			{"speaker": "미리암", "text": "나는 그분이 여기 계시지 않다는 것만은 보았어. 그 이상은... 나도 모르겠어."},
			{"speaker": "상인 요나", "text": "사람들은 빈자리에 원하는 이야기를 채우지. 너도 그러려는 거냐?"},
			{"speaker": "나", "text": "장사 장소와 무덤의 상태, 전해진 소식을 출처에 맞게 연결하자.", "puzzle": {"id": &"resurrection_evidence_links", "title": "무덤과 증언의 연결", "steps": [
				{"prompt": "돌문이 옆으로 밀려 있었다.", "answer": &"seen", "hint": "내 눈앞의 상태를 말하고 있다.", "options": [{"id": &"seen", "label": "직접 본 것"}, {"id": &"heard", "label": "전해 들은 것"}, {"id": &"inferred", "label": "추론한 것"}]},
				{"prompt": "미리암은 그분이 여기 계시지 않는다고 말했다.", "answer": &"heard", "hint": "미리암이 본 범위를 내가 전해 들었다.", "options": [{"id": &"seen", "label": "직접 본 것"}, {"id": &"heard", "label": "전해 들은 것"}, {"id": &"inferred", "label": "추론한 것"}]},
				{"prompt": "빈 무덤은 누군가 살아났다는 뜻이다.", "answer": &"inferred", "hint": "빈 공간만으로 원인을 직접 보지는 못했다.", "options": [{"id": &"seen", "label": "직접 본 것"}, {"id": &"heard", "label": "전해 들은 것"}, {"id": &"inferred", "label": "추론한 것"}]}
			]}},
			{"speaker": "나", "text": "내가 본 것과 들은 것을 구분해 보겠습니다."},
			{"speaker": "나", "text": "이 증언 앞에서 나는 어떻게 남을 것인가?", "choices": ["증언을 믿고 전하러 간다", "들은 일을 더 확인하며 따라간다", "이 말씀을 마음에 두고 걸어간다"], "choice_ids": [&"trusted_testimony", &"needed_proof", &"remained_open"], "responses": [{"speaker": "나", "text": "마리아가 전한 부활의 소식을 믿고 다른 이들에게도 전하러 간다."}, {"speaker": "나", "text": "빈 무덤과 만남의 증언을 들었다. 제자들에게 가서 그 뒤의 이야기도 듣고 싶다."}, {"speaker": "나", "text": "예수님이 살아나셨다는 말씀을 마음에 두고 제자들이 있는 곳으로 간다."}], "event": "prepare_exit"},
			{"speaker": "나", "text": "그분을 찾고 있습니까?", "event": "reveal_characters"},
			{"speaker": "나", "text": "아니요. 아직은... 무엇을 찾고 있는지 알아가는 중입니다."}
		]
	},
	{
		"title": "에필로그 · 당신은 어디에 서 있었습니까",
		"place": "새벽의 빈길",
		"palette": {"sky": Color("#b4c9c5"), "ground": Color("#65716c"), "accent": Color("#f4e5b5")},
		"lines": [
			{"speaker": "나", "text": "나는 그분을 처음부터 믿지 않았다."},
			{"speaker": "나", "text": "나는 그분을 끝까지 이해하지도 못했다."},
			{"speaker": "나", "text": "하지만 나는 그분이 지나간 자리를 보았다.", "event": "epilogue_memory"},
			{"speaker": "질문", "text": "당신은 그날, 군중 속에서 무엇을 보았습니까?", "event": "epilogue_question"},
			{"speaker": "질문", "text": "모두가 외칠 때, 당신은 어떤 목소리를 내고 있었습니까?"},
			{"speaker": "질문", "text": "만약 그 사람이 오늘 당신 앞을 지나간다면, 당신은 그냥 지나치겠습니까?", "event": "epilogue_final"},
			{"speaker": "끝", "text": "이야기는 끝났습니다. 이제, 당신이 무엇을 보았는지 남았습니다.", "event": "prepare_exit"}
		]
	}
]

const SCENE_PATHS := [
	"res://scenes/chapters/chapter_01_entry.tscn",
	"res://scenes/chapters/chapter_02_temple.tscn",
	"res://scenes/chapters/chapter_03_garden.tscn",
	"res://scenes/chapters/chapter_04_trial.tscn",
	"res://scenes/chapters/chapter_05_golgotha.tscn",
	"res://scenes/chapters/chapter_06_resurrection.tscn",
	"res://scenes/chapters/epilogue.tscn"
]

const PRODUCTION_READY := [true, true, true, true, true, true, true]

static func get_scene_path(chapter_number: int) -> String:
	return SCENE_PATHS[clampi(chapter_number, 1, SCENE_PATHS.size()) - 1]

static func get_definition(chapter_number: int) -> ChapterDefinition:
	var index := clampi(chapter_number, 1, CHAPTERS.size()) - 1
	var chapter: Dictionary = CHAPTERS[index]
	var optional: Array[StringName] = []
	var reflection_choices: Array[StringName] = []
	for line: Dictionary in chapter.get("lines", []):
		if line.has("choice_ids"):
			reflection_choices.assign(line.choice_ids)
	for beat in CHAPTER_BEATS.get("chapter_%02d" % (index + 1), []):
		optional.append_array(beat.get("optional_interactions", []))
	return ChapterDefinition.from_dictionary({
		"id": "chapter_%02d" % (index + 1),
		"number": index + 1,
		"title": chapter.title,
		"place": chapter.place,
		"scene_path": SCENE_PATHS[index],
		"next_scene_path": SCENE_PATHS[mini(index + 1, SCENE_PATHS.size() - 1)],
		"beats": CHAPTER_BEATS.get("chapter_%02d" % (index + 1), []),
		"optional_interactions": optional,
		"reflection_choices": reflection_choices,
		"production_ready": PRODUCTION_READY[index]
	})
