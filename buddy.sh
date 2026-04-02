#!/bin/bash
# Claude Code Companion Manager
# 바이너리 패치 + 설정 변경을 하나로 통합
#
# 사용법:
#   ./buddy.sh              # 인터랙티브 메뉴
#   ./buddy.sh show         # 현재 설정 보기
#   ./buddy.sh set          # 이름/성격/동물 변경
#   ./buddy.sh patch        # 바이너리 패치
#   ./buddy.sh patch check  # 패치 상태 확인
#   ./buddy.sh patch restore # 원본 복원
#   ./buddy.sh mute         # 숨기기
#   ./buddy.sh unmute       # 다시 보이기
#   ./buddy.sh reset        # 초기화

CONFIG="$HOME/.claude.json"
BINARY=$(readlink "$HOME/.local/bin/claude" 2>/dev/null || echo "")
BACKUP="${BINARY}.bak"

SPECIES_LIST="axolotl blob cactus capybara cat chonk dragon duck ghost goose mushroom octopus owl penguin rabbit robot snail turtle"
EYE_LIST="· ✦ × ◉ @ °"
HAT_LIST="none crown tophat propeller halo wizard beanie tinyduck"

# --- 유틸 ---

is_patched() {
  [[ -z "$BINARY" ]] && return 1
  local patched
  patched=$(grep -c '{\.\.\._,\.\.\.H}' <(strings "$BINARY") 2>/dev/null || echo 0)
  [[ "$patched" -gt 0 ]]
}

ensure_config() {
  if [[ ! -f "$CONFIG" ]]; then
    echo '{}' > "$CONFIG"
  fi
}

update_json() {
  # $1: python expression to modify dict 'd'
  ensure_config
  python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
if 'companion' not in d:
    d['companion'] = {}
$1
with open('$CONFIG', 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
"
}

# --- 표시 ---

show() {
  ensure_config
  python3 -c "
import json
d = json.load(open('$CONFIG'))
comp = d.get('companion', {})
muted = d.get('companionMuted', False)

print('=== Companion 현재 설정 ===')
print(f\"  이름:     {comp.get('name', '(기본값)')}\")
print(f\"  성격:     {comp.get('personality', '(기본값)')}\")
print(f\"  동물:     {comp.get('species', '(해시 결정)')}\")
print(f\"  눈:       {comp.get('eye', '(해시 결정)')}\")
print(f\"  모자:     {comp.get('hat', '(해시 결정)')}\")
print(f\"  레어리티: {comp.get('rarity', '(해시 결정)')}\")
print(f\"  반짝이:   {comp.get('shiny', '(해시 결정)')}\")
print(f\"  숨김:     {'예' if muted else '아니오'}\")
print(f\"  생성일:   {comp.get('hatchedAt', '(없음)')}\")
"
  echo ""
  if is_patched; then
    echo "  패치: ✅ 적용됨 — 모든 항목 변경 가능"
  else
    echo "  패치: ⚠ 미적용 — 이름/성격만 변경 가능"
    echo "         동물/눈/모자 변경하려면 'patch' 먼저 실행"
  fi
}

# --- 설정 변경 ---

pick_species() {
  echo ""
  echo "동물 선택 (18종):"
  echo ""
  local i=1
  for s in $SPECIES_LIST; do
    printf "  %2d) %s\n" "$i" "$s"
    i=$((i + 1))
  done
  echo ""
  read -p "번호 또는 이름 (Enter=건너뛰기): " choice
  [[ -z "$choice" ]] && return

  local selected=""
  # 숫자면 인덱스로
  if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le 18 ]]; then
    selected=$(echo "$SPECIES_LIST" | tr ' ' '\n' | sed -n "${choice}p")
  else
    # 이름 직접 입력
    if echo "$SPECIES_LIST" | grep -qw "$choice"; then
      selected="$choice"
    fi
  fi

  if [[ -z "$selected" ]]; then
    echo "❌ 유효하지 않은 선택: $choice"
    return 1
  fi

  update_json "d['companion']['species'] = '$selected'"
  echo "✅ 동물 → $selected"
}

pick_name() {
  read -p "새 이름 (Enter=건너뛰기): " new_name
  [[ -z "$new_name" ]] && return
  update_json "d['companion']['name'] = '''$new_name'''"
  echo "✅ 이름 → $new_name"
}

pick_personality() {
  echo "(예: 츤데레, 다정한 조언자, 냉소적 관찰자, 열혈 응원단)"
  read -p "새 성격 설명 (Enter=건너뛰기): " new_personality
  [[ -z "$new_personality" ]] && return
  update_json "d['companion']['personality'] = '''$new_personality'''"
  echo "✅ 성격 → $new_personality"
}

pick_eye() {
  echo ""
  echo "눈 모양 선택:"
  local i=1
  for e in $EYE_LIST; do
    printf "  %d) %s\n" "$i" "$e"
    i=$((i + 1))
  done
  echo ""
  read -p "번호 (Enter=건너뛰기): " choice
  [[ -z "$choice" ]] && return
  local selected
  selected=$(echo "$EYE_LIST" | tr ' ' '\n' | sed -n "${choice}p")
  if [[ -z "$selected" ]]; then
    echo "❌ 유효하지 않은 선택"
    return 1
  fi
  update_json "d['companion']['eye'] = '$selected'"
  echo "✅ 눈 → $selected"
}

pick_hat() {
  echo ""
  echo "모자 선택:"
  local i=1
  for h in $HAT_LIST; do
    printf "  %d) %s\n" "$i" "$h"
    i=$((i + 1))
  done
  echo ""
  read -p "번호 또는 이름 (Enter=건너뛰기): " choice
  [[ -z "$choice" ]] && return
  local selected=""
  if [[ "$choice" =~ ^[0-9]+$ ]]; then
    selected=$(echo "$HAT_LIST" | tr ' ' '\n' | sed -n "${choice}p")
  else
    if echo "$HAT_LIST" | grep -qw "$choice"; then
      selected="$choice"
    fi
  fi
  if [[ -z "$selected" ]]; then
    echo "❌ 유효하지 않은 선택"
    return 1
  fi
  update_json "d['companion']['hat'] = '$selected'"
  echo "✅ 모자 → $selected"
}

set_companion() {
  echo "=== Companion 설정 변경 ==="
  echo "(변경하지 않을 항목은 Enter로 건너뛰기)"
  echo ""

  pick_name
  pick_personality

  if is_patched; then
    pick_species
    pick_eye
    pick_hat
  else
    echo ""
    echo "⚠ 바이너리 미패치 — 동물/눈/모자 변경 불가"
    echo "  './buddy.sh patch' 실행 후 다시 시도하세요"
  fi

  echo ""
  echo "🔄 Claude Code 재시작하면 반영됩니다."
}

# --- 바이너리 패치 ---

patch_check() {
  if [[ -z "$BINARY" ]]; then
    echo "❌ Claude Code 바이너리를 찾을 수 없음"
    return 1
  fi
  local orig patched
  orig=$(grep -c '{\.\.\.H,\.\.\._}' <(strings "$BINARY") 2>/dev/null || echo 0)
  patched=$(grep -c '{\.\.\._,\.\.\.H}' <(strings "$BINARY") 2>/dev/null || echo 0)

  echo "=== 패치 상태 ==="
  echo "바이너리: $BINARY"
  echo "백업:     $([ -f "$BACKUP" ] && echo "$BACKUP" || echo "(없음)")"
  echo "원본 패턴: ${orig}개 / 패치 패턴: ${patched}개"

  if [[ "$orig" -eq 0 && "$patched" -gt 0 ]]; then
    echo "상태: ✅ 패치됨"
  elif [[ "$orig" -gt 0 && "$patched" -eq 0 ]]; then
    echo "상태: ⚠ 미패치 (원본)"
  else
    echo "상태: ❓ 알 수 없음"
  fi
}

patch_apply() {
  if [[ -z "$BINARY" ]]; then
    echo "❌ Claude Code 바이너리를 찾을 수 없음"
    return 1
  fi

  local count
  count=$(grep -c '{\.\.\.H,\.\.\._}' <(strings "$BINARY") 2>/dev/null || echo 0)
  if [[ "$count" -eq 0 ]]; then
    echo "✅ 이미 패치됨"
    return 0
  fi

  # 백업
  if [[ ! -f "$BACKUP" ]]; then
    cp "$BINARY" "$BACKUP"
    echo "백업 생성: $BACKUP"
  fi

  # 패치
  python3 -c "
data = bytearray(open('$BINARY', 'rb').read())
old = b'{...H,..._}'
new = b'{..._,...H}'
count = 0
idx = 0
while True:
    pos = data.find(old, idx)
    if pos == -1: break
    ctx = data[max(0,pos-80):pos+80]
    if b'bones' in ctx or b'zC' in ctx or b'companion' in ctx:
        data[pos:pos+len(old)] = new
        count += 1
    idx = pos + 1
with open('$BINARY', 'wb') as f:
    f.write(data)
print(f'✅ {count}곳 패치 완료')
"

  codesign --force --sign - "$BINARY" 2>/dev/null
  echo "✅ ad-hoc 재서명 완료"
}

patch_restore() {
  if [[ ! -f "$BACKUP" ]]; then
    echo "❌ 백업 파일 없음: $BACKUP"
    return 1
  fi
  cp "$BACKUP" "$BINARY"
  echo "✅ 원본 복원 완료"
}

# --- 뮤트 ---

mute() {
  ensure_config
  python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
d['companionMuted'] = True
with open('$CONFIG', 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
print('✅ Companion 숨김. 재시작 필요.')
"
}

unmute() {
  ensure_config
  python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
d['companionMuted'] = False
with open('$CONFIG', 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
print('✅ Companion 표시. 재시작 필요.')
"
}

reset() {
  ensure_config
  python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
if 'companion' in d:
    del d['companion']
if 'companionMuted' in d:
    del d['companionMuted']
with open('$CONFIG', 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
print('✅ Companion 삭제. 재시작하면 새로 랜덤 생성.')
"
}

# --- 인터랙티브 메뉴 ---

menu() {
  echo "=== Claude Companion Manager ==="
  echo ""
  echo "  1) 현재 설정 보기"
  echo "  2) 이름/성격/동물 변경"
  echo "  3) 바이너리 패치 적용"
  echo "  4) 패치 상태 확인"
  echo "  5) 패치 복원 (원본)"
  echo "  6) 숨기기"
  echo "  7) 다시 보이기"
  echo "  8) 초기화"
  echo "  q) 종료"
  echo ""
  read -p "선택: " choice
  case "$choice" in
    1) show ;;
    2) set_companion ;;
    3) patch_apply ;;
    4) patch_check ;;
    5) patch_restore ;;
    6) mute ;;
    7) unmute ;;
    8) reset ;;
    q|Q) exit 0 ;;
    *) echo "❌ 잘못된 선택" ;;
  esac
}

# --- 메인 ---

case "${1:-menu}" in
  menu)          menu ;;
  show)          show ;;
  set)           set_companion ;;
  patch)
    case "${2:-apply}" in
      apply)   patch_apply ;;
      check)   patch_check ;;
      restore) patch_restore ;;
      *) echo "사용법: $0 patch {apply|check|restore}" ;;
    esac
    ;;
  mute)    mute ;;
  unmute)  unmute ;;
  reset)   reset ;;
  *)
    echo "사용법: $0 {show|set|patch|mute|unmute|reset}"
    echo "        $0           # 인터랙티브 메뉴"
    exit 1
    ;;
esac
