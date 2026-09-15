# AI Rebuild Prompt

아래 프로젝트를 `39d5189` 커밋을 안정적인 기준점으로 삼아 다시 개발하라.

작업을 시작하기 전에 [`docs/PROJECT_PLAN_ARCHIVE.md`](PROJECT_PLAN_ARCHIVE.md)를 반드시 읽어라. 이 문서는 다른 계획 모드 채팅과 SecondBrain에서 회수한 원래 제품 비전, 장별 설계 결정, 폐기된 접근, 현재 구현 상태와 미검증 항목을 합친 기준 문서다. 저장소 코드·테스트는 구현 상태의 권위이고, 아카이브와 SecondBrain은 설계 의도와 검증 한계를 설명하는 자료다.

## 목표

게임의 기존 플레이 흐름을 보존하면서, 복구된 스토리 시스템과 아트 디렉션을 기준으로 챕터 1~6과 에필로그를 일관된 Godot 4 프로젝트로 완성한다. 원본이 없는 배경을 캡처 화면으로 위장해 사용하지 말고, 교체 가능한 리소스 경계를 유지한다.

## 절대 규칙

- `assets/art/ART_DIRECTION.md`를 모든 월드 배경·캐릭터·조사물 제작의 기준으로 사용한다.
- 배경에는 UI, 대사창, 버튼, 플레이어, NPC, 조사물을 굽지 않는다.
- 배경은 2048x720 RGB PNG, Nearest 필터, 3/4 탑다운, 하단 보행 영역을 따른다.
- 캐릭터와 조사물은 투명 PNG와 별도 Godot 노드로 배치한다.
- `assets/art/chapter02/temple_market.png`, `assets/art/chapter03/courtyard.png`, `assets/art/late_chapters/*.png`는 캡처 기반 임시 fallback이다. 최종 원본으로 취급하지 말고 교체 대상으로 표시한다.
- `.import`와 `.godot` 생성물을 수동 편집하거나 소스처럼 취급하지 않는다.
- 기존 원본을 찾지 못했다는 이유로 임의의 새 스토리나 캐릭터를 추가하지 말고, 변경 근거를 기록한다.
- 과거 계획의 모달 퀴즈·증거 분류·예수님의 창작 질문 대사를 되살리지 않는다. 현재 방향은 사건을 되돌리는 정답 선택이 아니라, 사건 뒤의 공간을 실제로 걷고 조사·운반·배치·밀기·등불 조절하는 현장 상호작용이다.
- 성경 사건의 결과를 바꾸지 않는다. 종려잎은 치우지 않고 환영의 흔적으로 다루며, 성전의 뒤집힌 상은 다시 세우지 않고 통로를 확보한다.
- 인물 연속성을 지킨다. 요나·미리암은 1~3장, 막달라 마리아는 5~6장에서 동일한 continuity id와 외형을 사용하고, 서로 다른 인물에 같은 PNG를 재사용하지 않는다.
- 모든 변경 후 Godot headless import와 회귀 테스트를 실행한다.

## 이미 보존된 자산

- `assets/art/ART_DIRECTION.md`
- `README.md`, `docs/*.md`
- `story_data.gd`, `scripts/story_state.gd`, `scripts/biblical_context.gd`, `scripts/npc_cast.gd`
- 조사·퍼즐 시스템: `scripts/field_investigation.gd`, `scripts/spatial_investigation.gd`, `scripts/evidence_link_investigation.gd`, `scripts/lantern_route_puzzle.gd`, `scripts/narrative_puzzle.gd`, `scripts/journey_journal.gd`
- `assets/art/pixel/npcs/`, `assets/art/player_walk/`, `assets/art/pixel/interactables/`
- `assets/art/biblical_cast/`, `assets/art/cutscene_cast/`
- Chapter 2 오디오와 재생성 도구

## 기존 계획 대비 현재 구현 판정 (2026-09-15)

다음 판정은 `README.md`, `game_script_THE THIRTEENTH DISCIPLE.md`, `docs/biblical_revision.md`, `docs/chapter03_implementation.md`, `docs/late_chapters_implementation.md`, `docs/polish_pass.md`와 현재 Godot 테스트 결과를 대조한 것이다. `PASS`는 코드와 자동 테스트로 확인된 항목이고, `PARTIAL`은 실행은 되지만 계획의 품질 기준이나 사람 검수가 남은 항목이다.

### PASS — 이미 구현되어 보존해야 하는 것

- 1~6장과 에필로그의 연속 장면 경로, 장 완료와 장면 선택 잠금
- WASD/방향키 8방향 이동, E 조사, Space 대사, J 수첩, P 일시정지, Esc 취소/나가기 확인
- 월드 스페이스 말풍선, 타이프라이터 대사, 선택지 키보드 조작과 입력 잠금
- `StoryState`의 관찰·선택·퍼즐·체크포인트 저장과 스키마 마이그레이션
- 1장 세 흔적과 조우, 2장 성전 조사, 3장 낮/밤 전환과 등불 경로 퍼즐
- 4~6장 조사·퍼즐·세 선택 경로와 에필로그 회상/크레딧
- 성경 사건 순서를 따르는 컷신 인터루드와 J 수첩의 본문 근거/창작 범위 표시
- 요나·미리암·막달라 마리아의 인물 연속성 및 NPC 역할 데이터
- 정수 픽셀 카메라 추적, 월드 경계, 조사 대상 우선순위, 충돌/이동 경로
- 오디오 버스·거리 감쇠·조사 효과음·대사 덕킹의 실행 연결
- Story, Cutscene, Biblical revision, Polish, Pause, Traversal, Presentation, Chapter 2/3/후반부 회귀 테스트

### PARTIAL — 기능은 있으나 계획의 품질 조건이 남은 것

- 월드 배경: 현재 `chapter02/`, `chapter03/`, `late_chapters/`의 일부 PNG는 UI와 NPC가 합성된 실행 캡처 기반 fallback이다. 깨끗한 2048x720 원본 배경으로 교체해야 한다.
- 픽셀 아트: Nearest와 기본 팔레트는 적용됐지만 48–64색 엄격 양자화, 모든 화면의 수작업 픽셀 검수, 알파 가장자리 검수는 완료되지 않았다.
- 애니메이션: 플레이어 방향별 시트는 연결됐지만 전체 NPC의 새 보행 애니메이션과 기존 2프레임에서 4프레임으로의 전 장 확장은 남아 있다.
- 오디오: 버스와 효과음 연결은 완료됐지만 헤드폰/스피커 최종 청취와 믹스 조정은 남아 있다.
- 후반부 연출: 군중 퇴장은 구현됐지만 현재는 단순 페이드이며, 더 풍부한 군중 동작은 후속 작업이다.
- 플레이 길이: 문서의 35–40분 목표는 사람을 대상으로 측정되지 않았으며 현재 빌드가 그 시간을 보장한다고 가정하지 않는다.

### TODO — 아직 계획상 검증되지 않은 것

- 실제 사람 플레이테스트로 무힌트 해결률, 길을 잃는 비율, 난이도, 독서 속도, 전체 플레이 시간을 측정한다.
- 헤드폰과 스피커에서 음량·대사 덕킹·환경음·발소리를 직접 청취하고 믹스를 조정한다.
- 새 배경을 생성/제작할 때 각 장면의 좌·중·우 카메라 캡처와 16:10 창을 사람이 시각 검수한다.
- 주요 NPC 전체에 일관된 4프레임 보행/정지 애니메이션을 추가한다.
- 원본 캡처형 fallback 배경을 최종 배경으로 오인하지 않도록 모두 교체하고, 각 생성 원본과 프롬프트를 `GENERATION.md`에 남긴다.
- `res://assets/art/biblical_cast/atlas_alpha.png`, `cutscene_cast_atlas.png`, `player_walk/atlas.png`, `late_chapters/source/`는 처리 도구용 입력 경로다. 새 에셋 파이프라인을 만들 때만 복원하고 런타임 필수 파일로 취급하지 않는다.

## 작업 순서

1. 현재 브랜치와 기준 커밋을 확인하고, 작업 전 별도 복구 브랜치를 만든다.
2. `PROJECT_PLAN_ARCHIVE.md`와 기준 문서를 읽고 원래 계획·현재 구현·미검증 항목을 표로 만든다.
3. 기준 커밋의 1장 플레이 루프와 메뉴를 먼저 실행해 baseline을 기록한다.
4. 스토리 데이터와 `StoryState`의 저장/마이그레이션을 먼저 통합한다.
5. 조사·퍼즐 시스템을 챕터별로 연결한다. 챕터 간 전역 상태와 체크포인트를 깨뜨리지 않는다. 장마다 행동의 손맛은 다르게 하되 공통 계약은 시작·진행·힌트·취소·완료·저장으로 제한한다.
6. 캐릭터/NPC 리소스와 플레이어 방향별 스프라이트를 연결한다. 동일 인물은 continuity id를 유지한다.
7. 각 배경을 아트 디렉션에 맞는 깨끗한 월드 배경으로 교체한다. UI·NPC가 포함된 캡처는 사용하지 않는다.
8. 씬의 충돌선, 보행 영역, 카메라 경계를 1280x720에서 확인한다. 연출 이동도 실제 충돌·상호작용 중심을 우회하지 않게 한다.
9. 아래 검증 명령을 실행하고 실패 원인과 남은 fallback을 보고한다.
10. 위 상태표와 `PROJECT_PLAN_ARCHIVE.md`의 상태를 함께 갱신한다. 기능 테스트가 통과해도 `PARTIAL`/`TODO` 항목을 `PASS`로 승격하지 말고, 실제 근거가 생긴 경우에만 변경한다.

## 검증 기준

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --quit
sh tools/run_polish_regressions.sh
```

검증 결과에는 다음을 포함한다.

- 씬 로드 오류와 누락 `res://` 참조 수
- Story/Chapter/Polish 회귀 테스트 결과
- 원본이 아닌 임시 리소스 목록
- 새로 만든 파일과 수정한 파일 목록
- 다음 작업자가 이어서 할 수 있는 구체적인 TODO

## 우선순위

1. 게임이 시작되고 챕터 1을 완료할 수 있어야 한다.
2. 스토리 선택·퍼즐·저장이 재실행 후에도 유지되어야 한다.
3. 캐릭터와 조사물은 읽기 쉬워야 한다.
4. 배경은 아트 디렉션과 일치해야 한다.
5. 시각적 완성도보다 원본과 다른 리소스를 명확히 표시하는 것을 우선한다.

작업을 시작하기 전에 현재 상태를 요약하고, 원본 복구가 불가능한 부분과 새로 제작해야 하는 부분을 분리해서 제시하라.

## 다음 작업자의 필수 운영 기록

각 작업 종료 보고에는 다음 네 가지를 별도로 적어라.

1. 무엇이 바뀌었는가 — 파일·씬·상태 키·아트/오디오 자산
2. 어떤 상태에서 확인했는가 — 실행 명령, 테스트 범위, 화면·오디오 수동 확인 여부
3. 어디까지 전달됐는가 — 미커밋, 로컬 커밋, 원격 push, 릴리스 여부
4. 무엇이 남았는가 — fallback, 사람 플레이테스트, 팔레트 검수, 믹스, NPC 애니메이션, 플레이 시간

대표 수동 흐름은 `조사 → J 저널 확인 → P 일시정지/재개 → 저장/재시작 → 다음 장 진행`으로 기록하고, 처음 하는 사람이 막힌 지점을 별도 메모하라. 자동 테스트의 통과 수만으로 재미·난이도·전체 플레이 시간을 완료 처리하지 마라.
