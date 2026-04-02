#!/bin/bash
# Claude Code Companion Customizer (커스터마이저)
# Usage (사용법): ./claude-companion.sh [command]
#
# Commands (명령어):
#   show     - View current settings (현재 설정 보기)
#   name     - Change name (이름 변경)
#   species  - Change species/appearance (동물/외형 변경)
#   mute     - Hide companion (숨기기)
#   unmute   - Show companion again (다시 보이기)
#   reset    - Reset to defaults (기본값으로 초기화) — auto-generated on restart (재시작 시 자동 생성)
#   info     - Customization guide (커스터마이징 가능 범위 안내)

CONFIG="$HOME/.claude.json"

show() {
  python3 -c "
import json
d = json.load(open('$CONFIG'))
comp = d.get('companion', {})
muted = d.get('companionMuted', False)
print('=== Claude Companion Current Settings (현재 설정) ===')
print(f\"Name (이름): {comp.get('name', '(none)')}\")
print(f\"Personality (성격): {comp.get('personality', '(none)')}\")
print(f\"Muted (숨김): {'Yes' if muted else 'No'}\")
print(f\"Hatched at (생성일): {comp.get('hatchedAt', '(none)')}\")
# Non-standard fields (비표준 필드)
for k in comp:
  if k not in ('name','personality','hatchedAt'):
    print(f\"{k}: {comp[k]}\")
"
}

name() {
  read -p "New name (새 이름): " new_name
  read -p "New personality description (새 성격 설명) (Enter to skip): " new_personality
  python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
if 'companion' not in d:
    d['companion'] = {}
d['companion']['name'] = '''$new_name'''
personality = '''$new_personality'''
if personality:
    d['companion']['personality'] = personality
with open('$CONFIG', 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
print('Change complete (변경 완료). Restart Claude Code required (재시작 필요).')
"
}

mute() {
  python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
d['companionMuted'] = True
with open('$CONFIG', 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
print('Companion hidden (숨김 처리 완료). Restart required (재시작 필요).')
"
}

unmute() {
  python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
d['companionMuted'] = False
with open('$CONFIG', 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
print('Companion visible again (다시 표시). Restart required (재시작 필요).')
"
}

reset() {
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
print('Companion removed (삭제 완료). A new one will be randomly generated on restart (재시작하면 새로 랜덤 생성됨).')
"
}

species() {
  echo "=== Claude Companion Species Change (외형 변경) ==="
  echo ""
  echo "Available species (사용 가능한 동물) (18 types):"
  echo "  axolotl, blob, cactus, capybara, cat, chonk,"
  echo "  dragon, duck, ghost, goose, mushroom, octopus,"
  echo "  owl, penguin, rabbit, robot, snail, turtle"
  echo ""

  # Check if patched (패치 여부 확인)
  local binary
  binary=$(readlink "$HOME/.local/bin/claude" 2>/dev/null || echo "")
  local patched=0
  if [[ -n "$binary" ]]; then
    patched=$(grep -c '{\.\.\._,\.\.\.H}' <(strings "$binary") 2>/dev/null || echo 0)
  fi

  if [[ "$patched" -gt 0 ]]; then
    echo "✅ Binary patch applied (바이너리 패치 적용됨) — can modify directly in claude.json"
    echo ""
    read -p "New species (새 species): " new_species
    local valid="axolotl blob cactus capybara cat chonk dragon duck ghost goose mushroom octopus owl penguin rabbit robot snail turtle"
    if ! echo "$valid" | grep -qw "$new_species"; then
      echo "❌ Invalid species (유효하지 않은 species): $new_species"
      return 1
    fi
    python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
if 'companion' not in d:
    d['companion'] = {}
d['companion']['species'] = '''$new_species'''
with open('$CONFIG', 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
print(f'✅ species → $new_species changed (변경 완료). Restart Claude Code required (재시작 필요).')
"
  else
    echo "⚠ Binary not patched (미패치 상태) — apply the patch first (먼저 패치를 적용하세요):"
    echo "  ./patch-companion.sh"
    echo ""
    echo "After patching, you can freely change species with this command (패치 후 species를 자유롭게 변경할 수 있습니다)."
  fi
}

info() {
  cat <<'EOF'
=== Claude Companion Customization Guide (커스터마이징 가이드) ===

■ Modifiable via claude.json (변경 가능)
  - name: Name (이름) — free text, max 14 chars (자유 텍스트, 최대 14자)
  - personality: Personality description (성격 설명) — reflected in system prompt (시스템 프롬프트에 반영)
  - companionMuted: true/false — hide companion (숨기기)

■ Modifiable after patching (패치 후 변경 가능) — requires patch-companion.sh
  - species (appearance/icon, 외형/아이콘): determined by UUID hash before patch, claude.json takes priority after (패치 전엔 UUID 해시로 결정, 패치 후 claude.json 우선)
  - eye: Eye shape (눈 모양) — ·, ✦, ×, ◉, @, °
  - hat: Hat (모자) — none, crown, tophat, propeller, halo, wizard, beanie, tinyduck
  - rarity: common, uncommon, rare, epic, legendary
  - shiny: true/false

■ Species List (18 types, built into binary, 바이너리 내장)
  axolotl, blob, cactus, capybara, cat, chonk,
  dragon, duck, ghost, goose, mushroom, octopus,
  owl, penguin, rabbit, robot, snail, turtle

■ Hash Determination Structure (해시 결정 구조) — original behavior (원본)
  seed = accountUuid + "friend-2026-401"
  hash = RE4(DE4(ME4(seed)))
  species = voq[floor(hash() * 18)]
  → Same account = always the same companion (같은 계정 = 항상 같은 companion)

■ Binary Patch (바이너리 패치) — patch-companion.sh
  In zC(): {...config,...bones} → {...bones,...config}
  → Values in claude.json take priority over hash-calculated values (claude.json에 쓴 값이 해시 계산값보다 우선)
  → Requires re-signing with codesign --force --sign - after patch (패치 후 재서명 필요)
  → Re-patching required after Claude Code updates (업데이트 시 재패치 필요)

■ Config File Location (설정 파일 위치)
  ~/.claude.json → companion object (companion 객체)

■ Restart Claude Code after all changes (모든 변경 후 재시작 필요)
EOF
}

case "${1:-show}" in
  show)    show ;;
  name)    name ;;
  species) species ;;
  mute)    mute ;;
  unmute)  unmute ;;
  reset)   reset ;;
  info)    info ;;
  *)
    echo "Usage (사용법): $0 {show|name|species|mute|unmute|reset|info}"
    exit 1
    ;;
esac
