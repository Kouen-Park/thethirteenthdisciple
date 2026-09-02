class_name StoryData
extends RefCounted

## 조건 기반 월드 내러티브의 공개 데이터 계약입니다.
## 1장은 beats를 실제 플레이 루프에 사용하며, lines는 후속 장 제작 중 호환을 위해 임시 유지합니다.
const CHAPTER_BEATS := {
	"chapter_01": [
		{"id": &"arrival", "completion": &"intro_dismissed", "next": &"approach"},
		{"id": &"approach", "completion": &"required_interactions", "required": [&"palm_leaf", &"discarded_cloak", &"footprints"], "next": &"encounter"},
		{"id": &"encounter", "completion": &"world_dialogue_finished", "next": &"complete"}
	],
	"chapter_02": [{"id": &"temple_aftermath", "completion": &"required_interactions", "next": &"complete"}],
	"chapter_03": [{"id": &"night_rumors", "completion": &"required_interactions", "next": &"complete"}],
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
			{"speaker": "나", "text": "며칠이 지났는데도 사람들은 여전히 그 사람 이야기를 한다.", "sound": "wind_only"},
			{"speaker": "상인 요나", "text": "성전 장사꾼들의 상을 뒤집었다더군. 질서를 망친 거야."},
			{"speaker": "미리암", "text": "아니, 사람들은 기도하러 왔는데 물건값부터 묻고 있었대."},
			{"speaker": "나", "text": "누가 옳은지 말이 아니라 흔적으로 확인해 보자.", "interaction": {"type": "observation", "title": "성전 앞 재구성", "instruction": "뒤집힌 물건과 사람들의 흔적을 조사하세요.", "options": [{"id": "scattered_coins", "label": "흩어진 동전", "description": "동전은 흙먼지 속에 흩어졌지만, 아무도 먼저 줍지 않았다."}, {"id": "empty_table", "label": "비어 있는 상", "description": "팔 물건은 사라지고, 상판에 손바닥 자국만 남았다."}, {"id": "prayer_corner", "label": "기도하던 자리", "description": "사람들이 조용히 앉을 수 있는 작은 공간이 드러났다."}]}},
			{"speaker": "나", "text": "사람들은 같은 장면을 보고 서로 다른 것을 말한다."},
			{"speaker": "예수", "text": "당신은 무엇을 찾으러 왔습니까?"},
			{"speaker": "나", "text": "당신이 어떤 사람인지 확인하러 왔습니다."},
			{"speaker": "예수", "text": "확인한 뒤에는, 본 것을 어떻게 하겠습니까?"},
			{"speaker": "나", "text": "아직 결정하지 못했습니다."},
			{"speaker": "나", "text": "그분은 성전 안으로 사라졌고, 나는 엎어진 상만 한참 바라보았다.", "event": "prepare_exit"}
		]
	},
	{
		"title": "제3장 · 사라진 자리",
		"place": "예루살렘 외곽의 우물과 좁은 골목",
		"palette": {"sky": Color("#b7a078"), "ground": Color("#76685d"), "accent": Color("#e7d3a2")},
		"lines": [
			{"speaker": "나", "text": "사람들은 그분이 다시 나타날 거라고 말했지만, 내가 도착하면 늘 자리가 비어 있었다.", "sound": "wind_only"},
			{"speaker": "나", "text": "오늘은 그분이 지나간 뒤에 남은 것들을 찾아보자.", "interaction": {"type": "observation", "title": "사라진 자리", "instruction": "사람들이 남긴 흔적을 조사하세요.", "options": [{"id": "well", "label": "물을 나눈 우물", "description": "두 사람이 함께 물을 마신 흔적이 있다."}, {"id": "toy", "label": "아이의 작은 장난감", "description": "아이의 손에서 떨어진 장난감이다. 누군가 주워 한쪽에 놓았다."}, {"id": "resting_place", "label": "비워진 자리", "description": "누군가 오래 앉아 있다가 떠난 듯, 바닥만 따뜻하게 남아 있다."}]}},
			{"speaker": "미리암", "text": "우리 동생은 그분을 만나지 못했어. 나는 계속 그분을 기다리라고만 했고."},
			{"speaker": "상인 요나", "text": "기대하게 만드는 것과 도와주는 건 다르지. 그 사람은 사람들을 기다리게만 해."},
			{"speaker": "나", "text": "기다리는 일도 누군가에게는 상처가 될 수 있나?"},
			{"speaker": "나", "text": "멀리서 그분의 뒷모습을 보았다. 이번에도 나는 한 걸음 늦었다.", "event": "prepare_exit"}
		]
	},
	{
		"title": "제4장 · 서로 다른 외침",
		"place": "예루살렘의 골목과 재판장 밖 · 밤",
		"palette": {"sky": Color("#3b3a4e"), "ground": Color("#51454a"), "accent": Color("#d6a46c")},
		"lines": [
			{"speaker": "나", "text": "며칠 전 왕이라 부르던 사람들이 오늘은 다른 이름을 외치고 있다.", "sound": "wind_only"},
			{"speaker": "나", "text": "누가 먼저 외치기 시작했는지, 그 목소리가 어디서 오는지 찾아가 보자.", "interaction": {"type": "observation", "title": "외침의 근원", "instruction": "골목에 남은 목소리의 흔적을 조사하세요.", "options": [{"id": "torch", "label": "꺼져 가는 횃불", "description": "불빛이 흔들릴 때마다 사람들의 얼굴이 다른 표정으로 보인다."}, {"id": "closed_door", "label": "닫힌 문", "description": "문 안에서는 숨죽인 목소리가 들리지만 아무도 나오지 않는다."}, {"id": "crowd_echo", "label": "벽에 남은 외침", "description": "같은 말이 여러 사람의 입을 거치며 조금씩 달라졌다."}]}},
			{"speaker": "행인", "text": "저 사람도 그와 함께 있었잖소?"},
			{"speaker": "나", "text": "나는 그분을 잘 알지 못합니다."},
			{"speaker": "나", "text": "그 말은 거짓말은 아니었다. 하지만 침묵도 진실의 일부일까?"},
			{"speaker": "나", "text": "그분과 눈이 마주쳤다. 질문할 시간은 없었다.", "event": "reveal_characters"},
			{"speaker": "나", "text": "나는 아무것도 하지 않았다. 그래서인지, 그 밤의 소리가 더 오래 남았다.", "event": "prepare_exit"}
		]
	},
	{
		"title": "제5장 · 끝까지 바라본 사람들",
		"place": "십자가의 길과 골고다 언덕",
		"palette": {"sky": Color("#77727a"), "ground": Color("#554d4e"), "accent": Color("#c2a18a")},
		"lines": [
			{"speaker": "나", "text": "나는 그분을 따라간 것이 아니다. 사람들이 오늘 무엇을 외치는지 확인하러 왔다.", "sound": "wind_only"},
			{"speaker": "나", "text": "길 위에 남은 작은 것들을 치워 보자.", "interaction": {"type": "observation", "title": "끝까지 바라보기", "instruction": "길가의 작은 흔적을 조사하세요.", "options": [{"id": "empty_bowl", "label": "비어 있는 그릇", "description": "누군가 물을 건네고 그릇만 돌려받지 못했다."}, {"id": "fallen_cloth", "label": "떨어진 천 조각", "description": "사람이 밀려난 자리에서 천 조각이 찢겨 있다."}, {"id": "silent_witness", "label": "고개를 돌린 사람", "description": "끝까지 보았지만 아무 말도 하지 않는 사람이 서 있다."}]}},
			{"speaker": "나", "text": "물 한 그릇을 건넬까, 곁에 서 있을까, 아니면 끝까지 바라보기만 할까?", "interaction": {"type": "button_steps", "title": "작은 선택", "instruction": "어떤 행동을 할지 선택하세요.", "steps": ["물을 건넨다", "곁에 선다", "끝까지 바라본다"]}},
			{"speaker": "나", "text": "그분이 마지막으로 사람들을 바라보았다. 나는 그 시선을 피하지 못했다.", "event": "focus_jesus"},
			{"speaker": "나", "text": "그분이 특별한 사람인지 아직 확신할 수 없다. 하지만 마지막 순간의 눈빛은 잊히지 않는다.", "event": "crowd_fade"}
		]
	},
	{
		"title": "제6장 · 빈자리의 증언",
		"place": "무덤 근처와 새벽길",
		"palette": {"sky": Color("#8db4c7"), "ground": Color("#677b72"), "accent": Color("#f1dfad")},
		"lines": [
			{"speaker": "나", "text": "사흘 뒤, 사람들은 또 다른 이야기를 시작했다. 이번에는 그분의 몸이 사라졌다는 이야기였다.", "sound": "wind_only"},
			{"speaker": "나", "text": "빈 무덤보다 먼저, 사람들이 무엇을 보았다고 말하는지 들어 보자.", "interaction": {"type": "observation", "title": "빈자리의 증언", "instruction": "서로 다른 증언을 조사하세요.", "options": [{"id": "empty_tomb", "label": "열린 무덤", "description": "돌문은 옆으로 밀려 있고, 안쪽에는 아무것도 없다."}, {"id": "miriam_testimony", "label": "미리암의 증언", "description": "미리암은 자신이 본 것을 말하지만, 아무도 쉽게 믿어 주지 않는다."}, {"id": "rumor_market", "label": "시장에 퍼진 소문", "description": "훔쳐 갔다는 말과 살아났다는 말이 서로 겹쳐 들린다."}]}},
			{"speaker": "미리암", "text": "나는 그분이 여기 계시지 않다는 것만은 보았어. 그 이상은... 나도 모르겠어."},
			{"speaker": "상인 요나", "text": "사람들은 빈자리에 원하는 이야기를 채우지. 너도 그러려는 거냐?"},
			{"speaker": "나", "text": "내가 본 것과 들은 것을 구분해 보겠습니다."},
			{"speaker": "나", "text": "나는 그분의 부활을 직접 보지 못했다. 그러나 그분이 지나간 자리에서 사람들이 달라지는 것은 보았다.", "event": "prepare_exit"},
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
