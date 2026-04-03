#!/bin/bash
# Claude Code Companion Manager
# Unified binary patch + settings customization (바이너리 패치 + 설정 변경을 하나로 통합)
#
# Usage (사용법):
#   ./buddy.sh              # Interactive menu (인터랙티브 메뉴)
#   ./buddy.sh show         # Show current settings (현재 설정 보기)
#   ./buddy.sh set          # Change name/personality/species (이름/성격/동물 변경)
#   ./buddy.sh art          # Edit custom ASCII art (커스텀 아트 편집)
#   ./buddy.sh art clear    # Remove custom art (커스텀 아트 제거)
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
  # Check both patches: config override + custom art renderer
  python3 -c "
data = open('$BINARY', 'rb').read()
# Check 1: companion merge patched
pat1 = b'{..._,...H}'
found1 = False
idx = 0
while True:
    pos = data.find(pat1, idx)
    if pos == -1: break
    ctx = data[max(0,pos-200):pos]
    if b'bones' in ctx and b'companion' in ctx:
        found1 = True; break
    idx = pos + 1
# Check 2: renderer patched (H.F|| present)
found2 = b'H.F||sy7[H.species]' in data
exit(0 if found1 and found2 else 1)
" 2>/dev/null
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
F = comp.get('F')
if F:
    print(f\"  Custom Art (커스텀): ✅ {len(F)} frame(s)\")
    eye = comp.get('eye', '\xB7')
    for i, frame in enumerate(F):
        print(f\"    Frame {i+1}:\")
        for line in frame:
            print(f\"      |{line.replace('{E}', eye)}|\")
else:
    print(f\"  Custom Art (커스텀): (none — using built-in species art)\")
"
  echo ""
  if is_patched; then
    echo "  Patch (패치): ✅ Applied — all fields + custom art modifiable (적용됨 — 모든 항목 + 커스텀 아트 변경 가능)"
  else
    echo "  Patch (패치): ⚠ Not applied — only name/personality changeable (미적용 — 이름/성격만 변경 가능)"
    echo "         Run 'patch' first to change species/eye/hat/art (동물/눈/모자/아트 변경하려면 'patch' 먼저 실행)"
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

edit_art() {
  local tmpfile
  tmpfile=$(mktemp /tmp/companion-art.XXXXXX.json)

  # Generate template — load existing or create sample
  python3 -c "
import json, sys

config = json.load(open('$CONFIG')) if __import__('os').path.exists('$CONFIG') else {}
existing = config.get('companion', {}).get('F')

if existing:
    data = existing
else:
    data = [
        ['            ', '   /\\\_/\\\\    ', '  ( {E}   {E})  ', '  (  \u03c9  )   ', '  (\")_(\")   '],
        ['            ', '   /\\\_/\\\\    ', '  ( {E}   {E})  ', '  (  \u03c9  )~  ', '  (\")_(\")   '],
        ['            ', '   /\\\\-/\\\\    ', '  ( {E}   {E})  ', '  (  \u03c9  )   ', '  (\")_(\")   ']
    ]

out = {
    '_comment': [
        'Companion Custom Art (\ucee4\uc2a4\ud140 \uc544\ud2b8)',
        'Rules (\uaddc\uce59):',
        '  - frames: array of frames, each frame is array of 5 strings (\ud504\ub808\uc784 \ubc30\uc5f4, \uac01 \ud504\ub808\uc784\uc740 5\uac1c \ubb38\uc790\uc5f4)',
        '  - Each line should be 12 chars wide, pad with spaces (\uac01 \uc904 12\uc790, \ube48 \uacf3\uc740 \uc2a4\ud398\uc774\uc2a4)',
        '  - {E} = eye character, auto-replaced ({E} = \ub208 \ubb38\uc790, \uc790\ub3d9 \uce58\ud658)',
        '  - 1~5 frames for animation (\uc560\ub2c8\uba54\uc774\uc158\uc6a9 1~5\ud504\ub808\uc784)',
        '  - Line 1 = hat area (empty for hats to work) (\ubaa8\uc790 \uc790\ub9ac)',
        '',
        'Delete this _comment block before saving \u2014 or leave it, it will be stripped.',
        '(\uc774 _comment \ube14\ub85d\uc740 \uc800\uc7a5 \uc2dc \uc790\ub3d9 \uc81c\uac70\ub429\ub2c8\ub2e4)',
    ],
    'frames': data
}

with open('$tmpfile', 'w') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
"

  # Show format guide and preview before editing
  echo ""
  echo "=== Custom Art Editor (커스텀 아트 편집기) ==="
  echo ""
  echo "JSON format (JSON 형식):"
  echo '  {'
  echo '    "frames": ['
  echo '      ["            ", "   /\\_/\\    ", "  ( {E}   {E})  ", "  (  ω  )   ", "  (\")_(\")   "],'
  echo '      ["            ", "   /\\_/\\    ", "  ( {E}   {E})  ", "  (  ω  )~  ", "  (\")_(\")   "]'
  echo '    ]'
  echo '  }'
  echo ""
  echo "Rendered output (렌더링 결과):"
  echo "  Frame 1:         Frame 2:"
  echo "    |   /\\_/\\    |   |   /\\_/\\    |"
  echo "    |  ( ·   ·)  |   |  ( ·   ·)  |"
  echo "    |  (  ω  )   |   |  (  ω  )~  |"
  echo "    |  (\")_(\")   |   |  (\")_(\")   |"
  echo ""
  echo "Rules (규칙):"
  echo "  • Each frame = 5 strings, 12 chars wide (각 프레임 = 5줄, 12자 폭)"
  echo "  • {E} → eye char (눈 문자로 자동 치환)"
  echo "  • Line 1 = empty for hat space (1번째 줄 비우면 모자 표시)"
  echo ""

  local editor="${EDITOR:-vi}"
  echo "Opening $editor... (에디터 열기...)"
  "$editor" "$tmpfile"

  # Validate and save (검증 후 저장)
  python3 -c "
import json, sys

try:
    with open('$tmpfile') as f:
        raw = json.load(f)
except json.JSONDecodeError as e:
    print(f'\u274c Invalid JSON: {e}')
    sys.exit(1)

# Accept either {frames: [...]} or bare [...]
if isinstance(raw, list):
    frames = raw
elif isinstance(raw, dict) and 'frames' in raw:
    frames = raw['frames']
else:
    print('\u274c JSON must be {\"frames\": [...]} or a bare array')
    sys.exit(1)

if not 1 <= len(frames) <= 5:
    print(f'\u274c Need 1-5 frames, got {len(frames)}')
    sys.exit(1)

for i, frame in enumerate(frames):
    if not isinstance(frame, list) or len(frame) != 5:
        print(f'\u274c Frame {i+1}: must have exactly 5 lines, got {len(frame) if isinstance(frame, list) else type(frame).__name__}')
        sys.exit(1)

# Preview
eye = json.load(open('$CONFIG')).get('companion', {}).get('eye', '\xb7') if __import__('os').path.exists('$CONFIG') else '\xb7'
print()
print('Preview (\ubbf8\ub9ac\ubcf4\uae30):')
for i, frame in enumerate(frames):
    print(f'  Frame {i+1}:')
    for line in frame:
        rendered = line.replace('{E}', eye)
        print(f'    |{rendered}|')
print()

# Save to config
with open('$CONFIG') as f:
    d = json.load(f)
if 'companion' not in d:
    d['companion'] = {}
d['companion']['F'] = frames
with open('$CONFIG', 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
print('\u2705 Custom art saved (\ucee4\uc2a4\ud140 \uc544\ud2b8 \uc800\uc7a5 \uc644\ub8cc)')
print('\U0001f504 Restart Claude Code to apply (\uc7ac\uc2dc\uc791\ud558\uba74 \ubc18\uc601)')
"

  rm -f "$tmpfile"
}

clear_art() {
  ensure_config
  python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
comp = d.get('companion', {})
if 'F' in comp:
    del comp['F']
    d['companion'] = comp
    with open('$CONFIG', 'w') as f:
        json.dump(d, f, ensure_ascii=False, indent=2)
    print('\u2705 Custom art removed, using built-in species art (\ucee4\uc2a4\ud140 \uc544\ud2b8 \uc81c\uac70, \uae30\ubcf8 \uc885 \uc544\ud2b8 \uc0ac\uc6a9)')
else:
    print('No custom art to remove (\uc81c\uac70\ud560 \ucee4\uc2a4\ud140 \uc544\ud2b8 \uc5c6\uc74c)')
"
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
    echo ""
    read -p "Edit custom art? (커스텀 아트 편집?) [y/N]: " do_art
    if [[ "$do_art" == "y" || "$do_art" == "Y" ]]; then
      edit_art
    fi
  else
    echo ""
    echo "⚠ Binary not patched — cannot change species/eye/hat/art (바이너리 미패치 — 동물/눈/모자/아트 변경 불가)"
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

  echo "=== Patch Status (패치 상태) ==="
  echo "Binary (바이너리): $BINARY"
  echo "Backup (백업):     $([ -f "$BACKUP" ] && echo "$BACKUP" || echo "(none)")"

  # Check companion merge function specifically
  python3 -c "
data = open('$BINARY', 'rb').read()
orig_pat = b'{...H,..._}'
patched_pat = b'{..._,...H}'
orig = 0; patched = 0
for pat, label in [(orig_pat, 'orig'), (patched_pat, 'patched')]:
    idx = 0
    while True:
        pos = data.find(pat, idx)
        if pos == -1: break
        ctx = data[max(0,pos-200):pos]
        if b'bones' in ctx and b'companion' in ctx:
            if label == 'orig': orig += 1
            else: patched += 1
        idx = pos + 1
print(f'Config override: original={orig}, patched={patched}')
if patched > 0 and orig == 0:
    print('  \u2705 Config override patched (\uc124\uc815 \uc624\ubc84\ub77c\uc774\ub4dc \ud328\uce58\ub428)')
else:
    print('  \u26a0 Config override not patched (\uc124\uc815 \uc624\ubc84\ub77c\uc774\ub4dc \ubbf8\ud328\uce58)')
# Check renderer patch
has_renderer = b'H.F||sy7[H.species]' in data
r_status = '\u2705 Patched (\ud328\uce58\ub428)' if has_renderer else '\u26a0 Not patched (\ubbf8\ud328\uce58)'
print(f'Custom art renderer: {r_status}')
"
}

patch_apply() {
  if [[ -z "$BINARY" ]]; then
    echo "❌ Claude Code binary not found (바이너리를 찾을 수 없음)"
    return 1
  fi

  if is_patched; then
    echo "✅ Already patched (이미 패치됨)"
    return 0
  fi

  # Backup (백업)
  if [[ ! -f "$BACKUP" ]]; then
    cp "$BINARY" "$BACKUP"
    echo "Backup created (백업 생성): $BACKUP"
  fi

  # Patch (패치) — config override + custom art renderer
  python3 -c "
data = bytearray(open('$BINARY', 'rb').read())
patches = 0

# Patch 1: companion merge — user config overrides hash-determined bones
old1 = b'{...H,..._}'
new1 = b'{..._,...H}'
idx = 0
while True:
    pos = data.find(old1, idx)
    if pos == -1: break
    ctx = data[max(0,pos-200):pos]
    if b'bones' in ctx and b'companion' in ctx:
        data[pos:pos+len(old1)] = new1
        patches += 1
    idx = pos + 1

# Patch 2: renderer — read custom frames from config (H.F) before built-in art (sy7)
old2 = b'function Wr_(H,_=0){let q=sy7[H.species],O=[...q[_%q.length].map((\$)=>\$.replaceAll(\"{E}\",H.eye))];if(H.hat!==\"none\"&&!O[0].trim())O[0]=xw5[H.hat];if(!O[0].trim()&&q.every((\$)=>!\$[0].trim()))O.shift();return O}'
new2 = b'function Wr_(H,_=0){let q=H.F||sy7[H.species],O=[...q[_%q.length].map(\$=>\$.replaceAll(\"{E}\",H.eye))];if(H.hat!=\"none\"&&!O[0].trim())O[0]=xw5[H.hat];if(!O[0].trim()&&q.every(\$=>!\$[0].trim()))O.shift();return O}'
idx = 0
while True:
    pos = data.find(old2, idx)
    if pos == -1: break
    data[pos:pos+len(old2)] = new2
    patches += 1
    idx = pos + 1

with open('$BINARY', 'wb') as f:
    f.write(data)
print(f'\u2705 {patches} patch(es) applied (\ud328\uce58 \uc644\ub8cc)')
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
  echo "  3) Edit custom ASCII art (커스텀 아트 편집)"
  echo "  4) Apply binary patch (바이너리 패치 적용)"
  echo "  5) Check patch status (패치 상태 확인)"
  echo "  6) Restore patch — original (패치 복원, 원본)"
  echo "  7) Hide companion (숨기기)"
  echo "  8) Show companion (다시 보이기)"
  echo "  9) Clear custom art (커스텀 아트 제거)"
  echo "  0) Reset to defaults (초기화)"
  echo "  q) Quit (종료)"
  echo ""
  read -p "Select (선택): " choice
  case "$choice" in
    1) show ;;
    2) set_companion ;;
    3) edit_art ;;
    4) patch_apply ;;
    5) patch_check ;;
    6) patch_restore ;;
    7) mute ;;
    8) unmute ;;
    9) clear_art ;;
    0) reset ;;
    q|Q) exit 0 ;;
    *) echo "❌ Invalid selection (잘못된 선택)" ;;
  esac
}

# --- Main (메인) ---

case "${1:-menu}" in
  menu)          menu ;;
  show)          show ;;
  set)           set_companion ;;
  art)
    case "${2:-edit}" in
      edit)  edit_art ;;
      clear) clear_art ;;
      *) echo "Usage (사용법): $0 art {edit|clear}" ;;
    esac
    ;;
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
    echo "Usage (사용법): $0 {show|set|art|patch|mute|unmute|reset}"
    echo "        $0           # Interactive menu (인터랙티브 메뉴)"
    exit 1
    ;;
esac
