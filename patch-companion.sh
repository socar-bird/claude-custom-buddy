#!/bin/bash
# Claude Code Companion Binary Patch (바이너리 패치)
# Enables direct override of species/hat etc. from claude.json
# (species/hat 등을 claude.json에서 직접 오버라이드 가능하게 함)
#
# How it works (원리): Patches zC() function's {...H,..._} → {..._,...H}
#   H = claude.json companion object, _ = UUID hash-calculated values (bones)
#   Original: bones overwrites config (bones가 config를 덮어씀)
#   → Patched: config overwrites bones (config가 bones를 덮어씀)
#
# Usage (사용법):
#   ./patch-companion.sh          # Patch current version (현재 버전 패치)
#   ./patch-companion.sh check    # Check patch status (패치 상태 확인)
#   ./patch-companion.sh restore  # Restore original (원본 복원)

CLAUDE_DIR="$HOME/.local/share/claude/versions"
CURRENT=$(readlink "$HOME/.local/bin/claude" 2>/dev/null || echo "")

if [[ -z "$CURRENT" ]]; then
  echo "❌ Claude Code binary not found (바이너리를 찾을 수 없음)"
  exit 1
fi

BINARY="$CURRENT"
BACKUP="${BINARY}.bak"
OLD_HEX=$(echo -n '{...H,..._}' | xxd -p)
NEW_HEX=$(echo -n '{..._,...H}' | xxd -p)

check() {
  local count
  count=$(grep -c '{\.\.\.H,\.\.\._}' <(strings "$BINARY") 2>/dev/null || echo 0)
  local patched
  patched=$(grep -c '{\.\.\._,\.\.\.H}' <(strings "$BINARY") 2>/dev/null || echo 0)

  echo "=== Companion Patch Status (패치 상태) ==="
  echo "Binary (바이너리): $BINARY"
  echo "Backup (백업):     $([ -f "$BACKUP" ] && echo "$BACKUP" || echo "(none)")"
  echo "Original pattern ({...H,..._}) (원본 패턴): ${count} found"
  echo "Patched pattern ({..._,...H}) (패치 패턴): ${patched} found"

  if [[ "$count" -eq 0 && "$patched" -gt 0 ]]; then
    echo "Status (상태): ✅ Patched (패치됨)"
  elif [[ "$count" -gt 0 && "$patched" -eq 0 ]]; then
    echo "Status (상태): ⚠ Not patched — original (미패치, 원본)"
  else
    echo "Status (상태): ❓ Unknown (알 수 없음)"
  fi
}

patch() {
  # Check if already patched (이미 패치됐는지 확인)
  local count
  count=$(grep -c '{\.\.\.H,\.\.\._}' <(strings "$BINARY") 2>/dev/null || echo 0)
  if [[ "$count" -eq 0 ]]; then
    echo "✅ Already patched, skipping (이미 패치됨, 스킵)"
    exit 0
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
    # Check if companion context (companion 컨텍스트인지 확인)
    ctx = data[max(0,pos-80):pos+80]
    if b'bones' in ctx or b'zC' in ctx or b'companion' in ctx:
        data[pos:pos+len(old)] = new
        count += 1
    idx = pos + 1
with open('$BINARY', 'wb') as f:
    f.write(data)
print(f'✅ {count} location(s) patched (곳 패치 완료)')
"

  # Code signing — allows modified binary to run on macOS
  # (macOS에서 변조된 바이너리 실행 허용)
  codesign --force --sign - "$BINARY" 2>/dev/null
  echo "✅ Ad-hoc re-signing complete (재서명 완료)"
}

restore() {
  if [[ ! -f "$BACKUP" ]]; then
    echo "❌ No backup file found (백업 파일 없음): $BACKUP"
    exit 1
  fi
  cp "$BACKUP" "$BINARY"
  echo "✅ Original restored (원본 복원 완료)"
}

case "${1:-patch}" in
  patch)   patch ;;
  check)   check ;;
  restore) restore ;;
  *)
    echo "Usage (사용법): $0 {patch|check|restore}"
    exit 1
    ;;
esac
