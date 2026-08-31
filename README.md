# THE THIRTEENTH DISCIPLE

예수의 고난과 부활을 관찰하고, 장면마다 손으로 참여하는 모바일 세로형 내러티브 게임입니다.

## 게임 흐름

`첫 화면 → 챕터 선택 → 장면 진행 → 다음 챕터 해금 → 에필로그`

- 시작 화면에서 이야기 시작과 설정을 선택합니다.
- 설정에서는 대화 속도와 저장된 진행도를 관리합니다.
- 각 챕터를 완료하면 다음 챕터가 해금됩니다.
- 제6장 부활을 마치면 에필로그가 자동으로 열립니다.

## 씬 구조

| 역할 | 파일 |
| --- | --- |
| 첫 화면 | `scenes/menu/main_menu.tscn` |
| 챕터 선택 | `scenes/menu/chapter_select.tscn` |
| 공통 챕터 노드/UI | `scenes/common/chapter_scene.tscn` |
| 1~6장 | `scenes/chapters/chapter_01_entry.tscn` ~ `chapter_06_resurrection.tscn` |
| 에필로그 | `scenes/chapters/epilogue.tscn` |

각 장 씬은 공통 챕터 씬을 상속하며, Godot 에디터에서 다음 노드를 확인하고 편집할 수 있습니다.

- `SceneArt`: 장면별 임시 배경과 움직임
- `Header`: 장 제목, 장소, 나가기 버튼
- `DialoguePanel`: 한 글자씩 진행되는 대사와 선택지
- `InteractionPanel`: 장면의 손동작 상호작용

## 코드 구조

- `story_data.gd`: 여섯 장의 대사, 선택지, 상호작용 단계
- `scene_art.gd`: 픽셀아트를 넣기 전 사용하는 움직이는 임시 무대
- `scripts/chapter_scene.gd`: 공통 대화·선택지·상호작용·챕터 완료 처리
- `scripts/game_state.gd`: 챕터 해금과 대화 속도 저장
- `scripts/main_menu.gd`, `scripts/chapter_select.gd`, `scripts/epilogue.gd`: 메뉴와 에필로그 흐름

## 픽셀아트 적용 시

현재 `SceneArt`는 코드로 만든 임시 연출입니다. 픽셀 배경이나 캐릭터가 준비되면 각 챕터 씬의 `SceneArt` 노드를 `Sprite2D`, `AnimatedSprite2D`, 타일맵 등으로 교체하거나 함께 배치하면 됩니다. 대화와 진행 구조는 그대로 유지됩니다.

## 제1장 완성형 연출

제1장에는 실제 세로형 픽셀아트 배경과 플레이어 제자, 예수와 나귀, 환호하는 군중 스프라이트가 적용되어 있습니다. 공통 챕터 씬의 `BackgroundLayer`는 제1장에서만 활성화되며, `CharacterLayer`의 `CrowdGroup`, `JesusDonkey`, `PlayerDisciple` 노드가 대본 이벤트에 따라 위치·크기·투명도 애니메이션으로 등장합니다. `CharacterLeft`, `CharacterCenter`, `CharacterRight` 슬롯은 이후 등장인물 확장용으로 유지됩니다.

- 배경: `assets/art/chapter01/background.png`
- 플레이어 제자: `assets/art/chapter01/player_disciple.png`
- 예수와 나귀: `assets/art/chapter01/jesus_donkey.png`
- 군중 그룹: `assets/art/chapter01/crowd_group.png`
- 효과음: `assets/audio/chapter01/`
- 종려잎 드래그: `scripts/palm_drag_interaction.gd`
- 대사·연출·사운드 이벤트: `story_data.gd`, `scripts/chapter_scene.gd`

제1장의 종려잎 상호작용은 마우스와 모바일 터치를 모두 지원합니다. 세 장의 종려잎을 빛나는 길 영역으로 끌어 놓으면 이야기가 자동으로 이어집니다. 장면 진입과 종료에는 화면·환경음 페이드가 적용됩니다.

시작 화면은 제1장 배경과 황금빛·짙은 갈색 패널 스타일을 공유합니다. 설정 화면의 전체 음량 슬라이더는 `GameState.master_volume`에 저장되며, 재실행 시 Master 오디오 버스에 자동 적용됩니다. 음량을 0%로 내리면 Master 버스가 음소거됩니다.

## 실행

Godot 4.7 이상에서 프로젝트를 열고 실행합니다. 기본 시작 씬은 `scenes/menu/main_menu.tscn`입니다.
