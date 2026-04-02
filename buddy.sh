#!/bin/bash
# Claude Code Companion Manager
# Unified binary patch + settings customization (바이너리 패치 + 설정 변경을 하나로 통합)
#
# Usage (사용법):
#   ./buddy.sh              # Interactive menu (인터랙티브 메뉴)
#   ./buddy.sh show         # Show current settings (현재 설정 보기)
#   ./buddy.sh set          # Change name/personality/species (이름/성격/동물 변경)
#   ./buddy.sh patch        # Apply binary patch (바이너리 패치)
#   ./buddy.sh patch check  # Check patch status (패치 상태 확인)
#   ./buddy.sh patch restore # Restore original (원본 복원)
#   ./buddy.sh mute         # Hide companion (숨기기)
#   ./buddy.sh unmute       # Show companion (다시 보이기)
#   ./buddy.sh reset        # Reset to defaults (초기화)

CONFIG="$HOME/.claude.json"
BINARY=$(readlink "$HOME/.local/bin/claude" 2>/dev/null || echo "")
BACKUP="${BINARY}.bak"

SPECIES_LIST="axolotl blob cactus capybara cat chonk dragon duck ghost goose mushroom octopus owl penguin rabbit robot snail turtle"
EYE_LIST="· ✦ × ◉ @ °"
HAT_LIST="none crown tophat propeller halo wizard beanie tinyduck"

# --- Utilities (유틸) ---

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

# --- Display (표시) ---

show() {
  ensure_config
  python3 -c "
import json
d = json.load(open('$CONFIG'))
comp = d.get('companion', {})
muted = d.get('companionMuted', False)

print('=== Companion Current Settings (현재 설정) ===')
print(f\"  Name (이름):        {comp.get('name', '(default)')}\")
print(f\"  Personality (성격): {comp.get('personality', '(default)')}\")
print(f\"  Species (동물):     {comp.get('species', '(hash-determined)')}\")
print(f\"  Eye (눈):           {comp.get('eye', '(hash-determined)')}\")
print(f\"  Hat (모자):         {comp.get('hat', '(hash-determined)')}\")
print(f\"  Rarity (레어리티):  {comp.get('rarity', '(hash-determined)')}\")
print(f\"  Shiny (반짝이):     {comp.get('shiny', '(hash-determined)')}\")
print(f\"  Muted (숨김):       {'Yes' if muted else 'No'}\")
print(f\"  Hatched at (생성일): {comp.get('hatchedAt', '(none)')}\")
"
  echo ""
  if is_patched; then
    echo "  Patch (패치): ✅ Applied — all fields modifiable (적용됨 — 모든 항목 변경 가능)"
  else
    echo "  Patch (패치): ⚠ Not applied — only name/personality changeable (미적용 — 이름/성격만 변경 가능)"
    echo "         Run 'patch' first to change species/eye/hat (동물/눈/모자 변경하려면 'patch' 먼저 실행)"
  fi
}

# --- Settings Change (설정 변경) ---

pick_species() {
  echo ""
  echo "Select species (동물 선택) (18 types):"
  echo ""
  local i=1
  for s in $SPECIES_LIST; do
    printf "  %2d) %s\n" "$i" "$s"
    i=$((i + 1))
  done
  echo ""
  read -p "Number or name (번호 또는 이름) (Enter=skip): " choice
  [[ -z "$choice" ]] && return

  local selected=""
  # If number, use as index (숫자면 인덱스로)
  if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le 18 ]]; then
    selected=$(echo "$SPECIES_LIST" | tr ' ' '\n' | sed -n "${choice}p")
  else
    # Direct name input (이름 직접 입력)
    if echo "$SPECIES_LIST" | grep -qw "$choice"; then
      selected="$choice"
    fi
  fi

  if [[ -z "$selected" ]]; then
    echo "❌ Invalid selection (유효하지 않은 선택): $choice"
    return 1
  fi

  update_json "d['companion']['species'] = '$selected'"
  echo "✅ Species (동물) → $selected"
}

pick_name() {
  read -p "New name (새 이름) (Enter=skip): " new_name
  [[ -z "$new_name" ]] && return
  update_json "d['companion']['name'] = '''$new_name'''"
  echo "✅ Name (이름) → $new_name"
}

pick_personality() {
  echo "(e.g. tsundere, gentle advisor, sarcastic observer, enthusiastic cheerleader)"
  echo "(예: 츤데레, 다정한 조언자, 냉소적 관찰자, 열혈 응원단)"
  read -p "New personality description (새 성격 설명) (Enter=skip): " new_personality
  [[ -z "$new_personality" ]] && return
  update_json "d['companion']['personality'] = '''$new_personality'''"
  echo "✅ Personality (성격) → $new_personality"
}

pick_eye() {
  echo ""
  echo "Select eye shape (눈 모양 선택):"
  local i=1
  for e in $EYE_LIST; do
    printf "  %d) %s\n" "$i" "$e"
    i=$((i + 1))
  done
  echo ""
  read -p "Number (번호) (Enter=skip): " choice
  [[ -z "$choice" ]] && return
  local selected
  selected=$(echo "$EYE_LIST" | tr ' ' '\n' | sed -n "${choice}p")
  if [[ -z "$selected" ]]; then
    echo "❌ Invalid selection (유효하지 않은 선택)"
    return 1
  fi
  update_json "d['companion']['eye'] = '$selected'"
  echo "✅ Eye (눈) → $selected"
}

pick_hat() {
  echo ""
  echo "Select hat (모자 선택):"
  local i=1
  for h in $HAT_LIST; do
    printf "  %d) %s\n" "$i" "$h"
    i=$((i + 1))
  done
  echo ""
  read -p "Number or name (번호 또는 이름) (Enter=skip): " choice
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
    echo "❌ Invalid selection (유효하지 않은 선택)"
    return 1
  fi
  update_json "d['companion']['hat'] = '$selected'"
  echo "✅ Hat (모자) → $selected"
}

set_companion() {
  echo "=== Companion Settings Change (설정 변경) ==="
  echo "(Press Enter to skip any field) (변경하지 않을 항목은 Enter로 건너뛰기)"
  echo ""

  pick_name
  pick_personality

  if is_patched; then
    pick_species
    pick_eye
    pick_hat
  else
    echo ""
    echo "⚠ Binary not patched — cannot change species/eye/hat (바이너리 미패치 — 동물/눈/모자 변경 불가)"
    echo "  Run './buddy.sh patch' first, then try again ('./buddy.sh patch' 실행 후 다시 시도하세요)"
  fi

  echo ""
  echo "🔄 Changes take effect after restarting Claude Code (재시작하면 반영됩니다)."
}

# --- Binary Patch (바이너리 패치) ---

patch_check() {
  if [[ -z "$BINARY" ]]; then
    echo "❌ Claude Code binary not found (바이너리를 찾을 수 없음)"
    return 1
  fi
  local orig patched
  orig=$(grep -c '{\.\.\.H,\.\.\._}' <(strings "$BINARY") 2>/dev/null || echo 0)
  patched=$(grep -c '{\.\.\._,\.\.\.H}' <(strings "$BINARY") 2>/dev/null || echo 0)

  echo "=== Patch Status (패치 상태) ==="
  echo "Binary (바이너리): $BINARY"
  echo "Backup (백업):     $([ -f "$BACKUP" ] && echo "$BACKUP" || echo "(none)")"
  echo "Original pattern (원본 패턴): ${orig} / Patched pattern (패치 패턴): ${patched}"

  if [[ "$orig" -eq 0 && "$patched" -gt 0 ]]; then
    echo "Status (상태): ✅ Patched (패치됨)"
  elif [[ "$orig" -gt 0 && "$patched" -eq 0 ]]; then
    echo "Status (상태): ⚠ Not patched — original (미패치, 원본)"
  else
    echo "Status (상태): ❓ Unknown (알 수 없음)"
  fi
}

patch_apply() {
  if [[ -z "$BINARY" ]]; then
    echo "❌ Claude Code binary not found (바이너리를 찾을 수 없음)"
    return 1
  fi

  local count
  count=$(grep -c '{\.\.\.H,\.\.\._}' <(strings "$BINARY") 2>/dev/null || echo 0)
  if [[ "$count" -eq 0 ]]; then
    echo "✅ Already patched (이미 패치됨)"
    return 0
  fi

  # Backup (백업)
  if [[ ! -f "$BACKUP" ]]; then
    cp "$BINARY" "$BACKUP"
    echo "Backup created (백업 생성): $BACKUP"
  fi

  # Patch (패치)
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
print(f'✅ {count} location(s) patched (곳 패치 완료)')
"

  codesign --force --sign - "$BINARY" 2>/dev/null
  echo "✅ Ad-hoc re-signing complete (재서명 완료)"
}

patch_restore() {
  if [[ ! -f "$BACKUP" ]]; then
    echo "❌ No backup file found (백업 파일 없음): $BACKUP"
    return 1
  fi
  cp "$BACKUP" "$BINARY"
  echo "✅ Original restored (원본 복원 완료)"
}

# --- Mute (숨기기) ---

mute() {
  ensure_config
  python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
d['companionMuted'] = True
with open('$CONFIG', 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
print('✅ Companion hidden (숨김). Restart required (재시작 필요).')
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
print('✅ Companion visible (표시). Restart required (재시작 필요).')
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
print('✅ Companion removed (삭제). Will be randomly regenerated on restart (재시작하면 새로 랜덤 생성).')
"
}

# --- Interactive Menu (인터랙티브 메뉴) ---

menu() {
  echo "=== Claude Companion Manager ==="
  echo ""
  echo "  1) Show current settings (현재 설정 보기)"
  echo "  2) Change name/personality/species (이름/성격/동물 변경)"
  echo "  3) Apply binary patch (바이너리 패치 적용)"
  echo "  4) Check patch status (패치 상태 확인)"
  echo "  5) Restore patch — original (패치 복원, 원본)"
  echo "  6) Hide companion (숨기기)"
  echo "  7) Show companion (다시 보이기)"
  echo "  8) Reset to defaults (초기화)"
  echo "  q) Quit (종료)"
  echo ""
  read -p "Select (선택): " choice
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
    *) echo "❌ Invalid selection (잘못된 선택)" ;;
  esac
}

# --- Main (메인) ---

case "${1:-menu}" in
  menu)          menu ;;
  show)          show ;;
  set)           set_companion ;;
  patch)
    case "${2:-apply}" in
      apply)   patch_apply ;;
      check)   patch_check ;;
      restore) patch_restore ;;
      *) echo "Usage (사용법): $0 patch {apply|check|restore}" ;;
    esac
    ;;
  mute)    mute ;;
  unmute)  unmute ;;
  reset)   reset ;;
  *)
    echo "Usage (사용법): $0 {show|set|patch|mute|unmute|reset}"
    echo "        $0           # Interactive menu (인터랙티브 메뉴)"
    exit 1
    ;;
esac
