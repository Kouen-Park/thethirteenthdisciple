# The Thirteenth Disciple

> “당신은 그를 보았습니까?”

《The Thirteenth Disciple》은 예수의 생애를 이름 없는 일반 군중의 시선으로 탐험하는 PC용 2D 픽셀 아트 내러티브 어드벤처입니다.

플레이어는 예수에 대해 아는 것이 없는 예루살의 일반 시민입니다. 군중 속에서 소문을 듣고, 종려잎·버려진 겉옷·발자국과 주변 인물을 조사하며 그가 누구였는지 조금씩 알아갑니다. 이 게임은 정답을 전달하기보다, 평범한 사람이 무엇을 보고 믿으며 어떤 선택을 하는지 직접 경험하게 합니다.

## 핵심 특징

- PC, 기준 해상도 1280×720
- WASD 8방향 월드 탐색
- E키로 환경·흔적·인물 조사
- 스페이스바로 대사 전체 표시 및 다음 대사 진행 (E는 대사를 넘기지 않습니다)
- ESC로 설정 창을 닫거나 게임에서 장면 선택으로 돌아가기 확인창을 엽니다.
- 시작 메뉴와 장면 선택은 키보드 방향키·Tab·Enter로도 조작할 수 있습니다. 진행도 초기화에는 확인이 필요합니다.
- 1장 도입: 소란에 의문을 품고 요나·미리암에게 사정을 물은 뒤, 길 위의 세 흔적을 조사합니다.
- 예수와 대화한 뒤에도 자유 탐색이 이어집니다. 주민 8명의 서로 다른 의견은 E로 선택적으로 듣고 Space로 진행하며, 들은 의견은 관찰 기록에 저장됩니다.
- 세 흔적 조사 후 예수가 오른쪽 샛길에서 큰 길로 들어오면, 플레이어가 가까이 다가가 마주 보고 대화합니다. 나귀 보행은 이동할 때만 재생되며, 대화 후에는 예수가 먼저 성문 안으로 향합니다.
- 준비되면 위쪽 성문의 ‘성전으로 향하는 입구’에서 E를 눌러 들어갑니다. 주민 대화를 모두 듣지 않아도 2장으로 진행할 수 있습니다.
- 인물의 위치에 따라 머리 위에 뜨는 월드 스페이스 말풍선
- 서로 다른 소문과 증언, 행동 후에 남은 흔적을 통한 서사
- 역사적 사건은 변하지 않지만, 관찰과 선택은 후속 대사와 에필로그의 회상에 반영

## 조작

| 키 | 기능 |
| --- | --- |
| WASD / 방향키 | 8방향 이동 |
| E | 가까운 대상 조사 |
| Space | 대사 전체 표시 / 다음 대사 |
| J | 기록 수첩 열기 / 닫기 (탐색 중) |
| P | 같은 자리에서 일시정지 / 재개, 음량·대사 속도 조절 |
| Esc | 열린 퍼즐·선택 닫기 / 나가기 확인 |

## 이야기 구성

예루살 입성에서 시작해 성전의 소문, 체포와 재판, 십자가, 빈 무덤과 부활의 증언으로 이어집니다. 본편은 연속적으로 진행되며, 완료한 장은 메인 메뉴에서 다시 방문할 수 있습니다.

‘열세 번째 제자’는 주인공의 직함이 아닙니다. 목격과 선택의 여정이 끝난 뒤, 플레이어 자신에게 남는 열린 질문입니다.

## 개발 상태

현재 1–6장을 탐색형 월드 챕터로 연결했고, 선택 회상과 크레딧이 있는 에필로그까지 플레이할 수 있습니다. 각 장에는 성서 지식이나 점수를 요구하지 않는 짧은 관찰 퍼즐이 포함됩니다. 2장은 2048×720 성전 시장을 가로질러 요나·미리암의 상반된 증언을 듣고, 흩어진 동전을 발에 밟히지 않게 모으고, 뒤집힌 상을 세우지 않은 채 통로 밖으로 밀고, 가려졌던 기도 자리의 천을 펼칩니다. 각 행동은 성전 정화 사건을 되돌리지 않고 그 이후의 공간을 돌보는 방식으로 구성됩니다. 4–6장은 새 2048×720 배경 위에서 흔적과 증언을 조사하고, 장별 관찰 퍼즐과 세 가지 행동 선택을 거쳐 다음 장으로 이어지는 첫 월드 버전입니다. 이전 장을 완료하면 순서대로 열리며 출시 실행에서도 3장 이후 계속 진행됩니다. 후반부 범위와 검증은 [후반부 제작 문서](docs/late_chapters_implementation.md)에 정리했습니다.

3장은 같은 2048×720 우물가가 늦은 오후·해질녘·밤으로 바뀌며, 남겨진 물건과 증언을 조사하고 등불의 방향을 기름 자국에 맞춰 행렬의 길을 잇습니다. 소리를 따라감·거리를 둠·청년을 도움의 행동 선택을 기록하고 재판장 방향으로 나갑니다. 세부 흐름과 검증 범위는 [3장 제작 문서](docs/chapter03_implementation.md)에 정리했습니다. 장면 경로와 비트 조건은 `ChapterDefinition`을 통해 한 곳에서 조회하며, 저장 데이터는 버전이 지정된 관찰·선택·퍼즐 결과를 보존합니다.

월드 아트는 2장 성전 시장의 픽셀 아트 스타일을 기준으로 통일합니다. 해상도, 3/4 시점, 팔레트, 광원, 레이어 분리와 재사용 생성 프롬프트는 [`assets/art/ART_DIRECTION.md`](assets/art/ART_DIRECTION.md)에 정의되어 있습니다. 1장 성문 배경도 이 규격에 맞춘 새 버전을 사용합니다.
1장의 종려잎·버려진 겉옷·발자국도 같은 규격으로 정리한 독립 투명 오브젝트를 사용하며, 원본과 스타일 정리 과정은 `tools/restyle_interactables_ch02.gd`에 남아 있습니다.

### 주요 구조

1장 연출은 보행 프레임에 맞춘 발소리, 플레이어 위치 기준 군중 공간 음향,
종려잎·겉옷·발자국별 조사 효과음과 군중이 갈라지며 조용해지는 등장 연출을 포함합니다.
발소리는 Kenney의 CC0 폴리 5종을 바로 직전 샘플과 겹치지 않게 재생하며,
종려잎은 식물 바스락거림, 겉옷은 옷감, 발자국 조사는 낮은 지면 소리로 구분합니다.
`scripts/chapter_audio.gd`에서 샘플·음량·미세한 피치 변주와 거리 감쇠를 조정합니다.
출처와 재질 대체 내역은 [오디오 크레딧](assets/audio/chapter01/kenney/CREDITS.md)에 기록했습니다.
기존 합성 폴리와 `tools/build_foley.gd`는 비교용으로 보존했으며 현재 조사·보행에는 사용하지 않습니다.
군중·바람 배경 루프는 기존 자산을 유지합니다. 최종 믹스는 헤드폰과 스피커 청취 검수가 필요합니다.

카메라는 부드러운 추적 계산 후 정수 픽셀에 정렬하고 월드 경계를 제한합니다.
1–6장 월드는 2048×720이고 화면은 1280×720이므로, 카메라가 좌우로 추적하면서
월드 바깥은 노출하지 않습니다.

- `scripts/chapter_director.gd`: 비트, 필수 조사, 장 완료 조건
- `scripts/world_chapter_base.gd`: 월드형 후속 장의 이동·말풍선·저장·전환 공통 기반
- `scripts/chapter_03_garden.gd`: 3장 시간 변화, 조사, 등불 경로 퍼즐과 세 행동 선택
- `tests/run_chapter03_playthrough_tests.gd`: 3장 세 선택의 전체 진행과 입력·힌트 회귀 테스트
- `scripts/chapter_02_temple.gd`: 2장 조사, 증언, 성찰 선택과 출구 연출
- `tests/run_chapter02_playthrough_tests.gd`: 2장 필수 루트 전체 흐름 회귀 테스트
- `scripts/story_state.gd`: 장별 관찰·선택·완료 상태
- `scripts/player_controller.gd`: 8방향 `CharacterBody2D` 이동
- `scripts/interaction_scanner.gd`: 가장 가까운 월드 상호작 대상 선택
- `scripts/speech_bubble_controller.gd`: 인물을 따라가는 월드 말풍선
- `story_data.gd`: 장별 비트와 내러티브 데이터

## 실행

Godot 4.7 이상에서 `project.godot`를 열고 프로젝트를 실행합니다. 기본 시작 장면은 `scenes/menu/main_menu.tscn`입니다.

헤드리스 로드 검증:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

스토리 및 연출 회귀 검증:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_story_tests.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_cutscene_tests.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_presentation_tests.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_chapter02_playthrough_tests.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_chapter03_playthrough_tests.gd
```

후반부 전체 선택 경로 검증:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_late_chapter_playthrough_tests.gd
```

전체 플레이 다듬기와 검증 범위는 [2026-09-11 작업 기록](docs/polish_pass.md)에 정리했습니다.

일시정지 중에는 대사, 퍼즐과 연출이 멈추며 `P` 또는 Esc로 같은 상태에서 이어갑니다. 음량과 대사 속도는 즉시 저장됩니다. 장면 선택으로 나갔다가 다시 방문하면 해당 장의 처음부터 시작합니다.

전체 회귀 검증은 `sh tools/run_polish_regressions.sh`로 순서대로 실행합니다. 수첩·일시정지·상호작용·실제 이동 경로 검증도 포함합니다.


## 2026-09-11 성경 기준 개편

여섯 장에 성경 사건 연결과 현장 조사 39개를 추가했습니다. E로 조사·운반·배치, E+D/→로 밀기, 등불 근처 E로 방향 조절, J로 성경 근거와 조사 기록을 확인합니다. 장 사이의 긴 본문 설명은 식사·기도·체포·재판·십자가 행렬·죽음·장사·빈 무덤을 짧은 연속 장면으로 보여 주는 컷신으로 바꿨습니다. 성경 구절 출처는 J 수첩에서 계속 확인할 수 있습니다. 컷신에는 예수님·베드로·유다·빌라도·바라바·순례자와 호송병을 구분한 전용 픽셀 캐릭터를 사용하며, 현재 주인공은 방향별 네 프레임 보행을 사용합니다.

본문 출처, 창작 범위, 장별 역할과 검증 방법은 [개편 기록](docs/biblical_revision.md)을 참고하세요. 이전 문서의 모달 퍼즐 설명은 현재 현장 조사 흐름으로 대체됩니다.
