# claude-custom-buddy

Customize your Claude Code companion — change species, name, personality, and more with a single script.

## What is this?

Claude Code has a companion creature that sits beside your input box. By default, its species, eyes, and hat are determined by a hash of your account UUID — you can't change them through settings.

This tool patches the Claude Code binary so that `~/.claude.json` values take priority over the hash, letting you fully customize your companion.

## Quick Start

```bash
git clone https://github.com/socar-bird/claude-custom-buddy.git
cd claude-custom-buddy
chmod +x buddy.sh

# 1. Patch the binary (required once per Claude Code update)
./buddy.sh patch

# 2. Customize your companion
./buddy.sh set
```

## Usage

```
./buddy.sh              # Interactive menu
./buddy.sh show         # Show current settings
./buddy.sh set          # Change name/personality/species/eye/hat
./buddy.sh patch        # Apply binary patch
./buddy.sh patch check  # Check patch status
./buddy.sh patch restore # Restore original binary
./buddy.sh mute         # Hide companion
./buddy.sh unmute       # Show companion
./buddy.sh reset        # Reset to defaults
```

## Examples

### Interactive Menu

```
$ ./buddy.sh

=== Claude Companion Manager ===

  1) 현재 설정 보기
  2) 이름/성격/동물 변경
  3) 바이너리 패치 적용
  4) 패치 상태 확인
  5) 패치 복원 (원본)
  6) 숨기기
  7) 다시 보이기
  8) 초기화
  q) 종료

선택:
```

### Show Current Settings

```
$ ./buddy.sh show

=== Companion 현재 설정 ===
  이름:     버드 부하
  성격:     a]loyal but sassy dragon sidekick
  동물:     dragon
  눈:       (해시 결정)
  모자:     (해시 결정)
  레어리티: (해시 결정)
  반짝이:   (해시 결정)
  숨김:     아니오
  생성일:   2025-06-26T...

  패치: ✅ 적용됨 — 모든 항목 변경 가능
```

### Change Name, Personality & Species

```
$ ./buddy.sh set

=== Companion 설정 변경 ===
(변경하지 않을 항목은 Enter로 건너뛰기)

새 이름 (Enter=건너뛰기): 드래곤
✅ 이름 → 드래곤

(예: 츤데레, 다정한 조언자, 냉소적 관찰자, 열혈 응원단)
새 성격 설명 (Enter=건너뛰기): 츤데레 드래곤
✅ 성격 → 츤데레 드래곤

동물 선택 (18종):

   1) axolotl       7) dragon      13) owl
   2) blob          8) duck        14) penguin
   3) cactus        9) ghost       15) rabbit
   4) capybara     10) goose       16) robot
   5) cat          11) mushroom    17) snail
   6) chonk        12) octopus     18) turtle

번호 또는 이름 (Enter=건너뛰기): 7
✅ 동물 → dragon

🔄 Claude Code 재시작하면 반영됩니다.
```

### Patch Binary

```
$ ./buddy.sh patch

백업 생성: /Users/.../.local/bin/claude.bak
✅ 1곳 패치 완료
✅ ad-hoc 재서명 완료
```

### Check Patch Status

```
$ ./buddy.sh patch check

=== 패치 상태 ===
바이너리: /Users/.../.local/bin/claude
백업:     /Users/.../.local/bin/claude.bak
원본 패턴: 0개 / 패치 패턴: 1개
상태: ✅ 패치됨
```

## Available Species (18)

| | | | |
|---|---|---|---|
| axolotl | blob | cactus | capybara |
| cat | chonk | dragon | duck |
| ghost | goose | mushroom | octopus |
| owl | penguin | rabbit | robot |
| snail | turtle | | |

## How It Works

Claude Code determines companion traits using a hash:

```
seed = accountUuid + "friend-2026-401"
hash = RE4(DE4(ME4(seed)))
species = speciesList[floor(hash() * 18)]
```

The binary merges config and hash with `{...config, ...bones}` — bones (hash values) always win. The patch flips this to `{...bones, ...config}`, so your `~/.claude.json` settings take priority.

## Notes

- **Restart required**: All changes take effect after restarting Claude Code
- **Re-patch after updates**: Claude Code updates replace the binary, so re-run `./buddy.sh patch`
- **macOS only**: The patch uses `codesign` for ad-hoc re-signing
- **Safe**: A backup is created before patching; restore anytime with `./buddy.sh patch restore`
- **Config location**: `~/.claude.json` → `companion` object

## License

MIT
