# DialogueController / InteractionController 연결 가이드

## 1. 씬 노드 추가

`scenes/common/chapter_scene.tscn`의 루트 `ChapterScene` 아래에 다음 노드를 추가한다.

```text
ChapterScene
├── DialogueController      (Node, script: scripts/dialogue_controller.gd)
└── InteractionController   (Node, script: scripts/interaction_controller.gd)
```

컨트롤러는 UI를 직접 찾지 않는다. `chapter_scene.gd`의 `_ready()`에서 UI 참조를 주입한다.

```gdscript
@onready var dialogue_controller: DialogueController = $DialogueController
@onready var interaction_controller: InteractionController = $InteractionController

func _ready() -> void:
    dialogue_controller.setup(
        $DialoguePanel/Box/Speaker,
        $DialoguePanel/Box/Dialogue,
        $DialoguePanel/Box/Advance,
        $DialoguePanel/Box/ChoiceA,
        $DialoguePanel/Box/ChoiceB
    )
    dialogue_controller.set_text_speed(GameState.text_speed)
    dialogue_controller.line_started.connect(_on_line_started)
    dialogue_controller.line_finished.connect(_on_line_finished)
    dialogue_controller.choice_selected.connect(_on_choice_selected)
    dialogue_controller.sequence_finished.connect(_finish_chapter)

    interaction_controller.setup(
        $InteractionPanel/Box/Action,
        $InteractionPanel/Box/Hint
    )
    interaction_controller.completed.connect(_on_interaction_completed)
    interaction_controller.progress_changed.connect(_on_interaction_progress)

    var chapter: Dictionary = Story.CHAPTERS[chapter_index]
    dialogue_controller.start(chapter.lines)
```

기존 코드와 동시에 사용하면 Advance와 Choice signal이 중복 연결되므로, 컨트롤러로 이전한 뒤에는 `chapter_scene.gd`의 다음 연결과 대화 상태 변수를 제거한다.

```gdscript
# 제거 대상 예시
$DialoguePanel/Box/Advance.pressed.connect(_advance)
$DialoguePanel/Box/ChoiceA.pressed.connect(_choose.bind(0))
$DialoguePanel/Box/ChoiceB.pressed.connect(_choose.bind(1))
var line_index := 0
var waiting_for_choice := false
var is_typing := false
```

## 2. ChapterScene에 남길 오케스트레이션 코드

ChapterScene은 데이터와 화면의 연결만 담당한다. 기존 `_apply_line_event()`와 `_apply_line_sound()`는 `line_started` signal에서 실행한다.

```gdscript
func _on_line_started(line: Dictionary, _index: int) -> void:
    dialogue_panel.show()
    interaction_panel.hide()
    _apply_line_event(str(line.get("event", "")))
    _apply_line_sound(str(line.get("sound", "")))

    var interaction_data: Dictionary = line.get("interaction", {})
    if not interaction_data.is_empty():
        # 대사를 다 읽은 후 _on_line_finished에서 시작한다.
        pass

func _on_line_finished(line: Dictionary, _index: int) -> void:
    var interaction_data: Dictionary = line.get("interaction", {})
    if not interaction_data.is_empty():
        dialogue_panel.hide()
        interaction_panel.show()
        interaction_controller.start(interaction_data, _resolve_interaction(interaction_data))

func _resolve_interaction(data: Dictionary) -> Node:
    var interaction_type := String(data.get("type", "button_steps"))
    if interaction_type == "palm_drag":
        return $InteractionPanel/Box/PalmDrag
    return null

func _on_interaction_completed(_data: Dictionary) -> void:
    interaction_panel.hide()
    dialogue_panel.show()
    # InteractionController가 완료한 뒤 다음 대사로 이동한다.
    dialogue_controller.advance()

func _on_interaction_progress(current: int, total: int) -> void:
    # 필요하면 여기서 전용 피드백, 효과음, 서사 변수 갱신을 처리한다.
    if current > 0:
        $Audio/SFX.play()
```

## 3. 중요한 동작 차이

새 `DialogueController`는 선택지 응답을 같은 line의 응답으로 표시한 후, 다음 `advance()` 입력에서 다음 원본 대사로 이동한다. 따라서 기존 `_choose()`의 응답 표시와 동일한 사용자 경험을 유지한다.

새 `InteractionController`는 두 종류를 지원한다. `child_interaction`이 전달되면 `completed`와 `progress_changed` signal을 연결해 종려잎 드래그 같은 커스텀 입력을 위임한다. 전달하지 않으면 `steps` 배열을 자체적으로 처리해 기존의 버튼 단계 상호작용을 실행한다.

```gdscript
# 커스텀 드래그
interaction_controller.start({
    "type": "palm_drag",
    "instruction": "종려잎 세 장을 빛나는 길 위로 끌어 놓으세요.",
    "required": 3
}, $InteractionPanel/Box/PalmDrag)

# 버튼 단계
interaction_controller.start({
    "title": "발을 씻기기",
    "steps": ["대야에 물을 천천히 붓는다", "발 위로 물을 흘려 보낸다", "수건으로 조심스레 닦는다"]
})
```

## 4. 이전 순서

처음에는 기존 `chapter_scene.gd`를 삭제하지 말고, 제1장 복제 씬에서 컨트롤러를 연결한다. 대화 재생과 종려잎 완료가 정상 작동하는 것을 확인한 뒤 기존 `_show_line()`, `_advance()`, `_choose()`, `_begin_interaction()`, `_complete_interaction_step()`를 제거한다. 마지막으로 `_process()`의 타이프라이터 처리와 `line_index` 기반 코드를 제거한다.

현재 `PalmDragInteraction`의 signal 시그니처는 `progress_changed(placed_count, required_count)`와 `completed`이므로 `InteractionController`와 바로 연결할 수 있다. 새로운 상호작용도 같은 signal 계약을 지키면 ChapterScene을 수정하지 않고 교체할 수 있다.
