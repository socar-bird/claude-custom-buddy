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
./buddy.sh art          # Edit custom ASCII art (opens $EDITOR)
./buddy.sh art clear    # Remove custom art, revert to built-in
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

  1) Show current settings (현재 설정 보기)
  2) Change name/personality/species (이름/성격/동물 변경)
  3) Edit custom ASCII art (커스텀 아트 편집)
  4) Apply binary patch (바이너리 패치 적용)
  5) Check patch status (패치 상태 확인)
  6) Restore patch — original (패치 복원, 원본)
  7) Hide companion (숨기기)
  8) Show companion (다시 보이기)
  9) Clear custom art (커스텀 아트 제거)
  0) Reset to defaults (초기화)
  q) Quit (종료)

Select (선택):
```

### Show Current Settings

```
$ ./buddy.sh show

=== Companion Current Settings (현재 설정) ===
  Name (이름):        버드 부하
  Personality (성격): a]loyal but sassy dragon sidekick
  Species (동물):     dragon
  Eye (눈):           (hash-determined)
  Hat (모자):         (hash-determined)
  Rarity (레어리티):  (hash-determined)
  Shiny (반짝이):     (hash-determined)
  Muted (숨김):       No
  Hatched at (생성일): 2025-06-26T...

  Patch (패치): ✅ Applied — all fields modifiable (적용됨 — 모든 항목 변경 가능)
```

### Change Name, Personality & Species

```
$ ./buddy.sh set

=== Companion Settings Change (설정 변경) ===
(Press Enter to skip any field) (변경하지 않을 항목은 Enter로 건너뛰기)

New name (새 이름) (Enter=skip): Dragon
✅ Name (이름) → Dragon

(e.g. tsundere, gentle advisor, sarcastic observer, enthusiastic cheerleader)
(예: 츤데레, 다정한 조언자, 냉소적 관찰자, 열혈 응원단)
New personality description (새 성격 설명) (Enter=skip): tsundere dragon
✅ Personality (성격) → tsundere dragon

Select species (동물 선택) (18 types):

   1) axolotl       7) dragon      13) owl
   2) blob          8) duck        14) penguin
   3) cactus        9) ghost       15) rabbit
   4) capybara     10) goose       16) robot
   5) cat          11) mushroom    17) snail
   6) chonk        12) octopus     18) turtle

Number or name (번호 또는 이름) (Enter=skip): 7
✅ Species (동물) → dragon

🔄 Changes take effect after restarting Claude Code (재시작하면 반영됩니다).
```

### Patch Binary

```
$ ./buddy.sh patch

Backup created (백업 생성): /Users/.../.local/bin/claude.bak
✅ 1 location(s) patched (곳 패치 완료)
✅ Ad-hoc re-signing complete (재서명 완료)
```

### Check Patch Status

```
$ ./buddy.sh patch check

=== Patch Status (패치 상태) ===
Binary (바이너리): /Users/.../.local/bin/claude
Backup (백업):     /Users/.../.local/bin/claude.bak
Original pattern (원본 패턴): 0 / Patched pattern (패치 패턴): 1
Status (상태): ✅ Patched (패치됨)
```

## Available Species (18)

| | | | |
|---|---|---|---|
| axolotl | blob | cactus | capybara |
| cat | chonk | dragon | duck |
| ghost | goose | mushroom | octopus |
| owl | penguin | rabbit | robot |
| snail | turtle | | |

## Custom ASCII Art

After patching, you can draw your own companion instead of using the built-in 18 species.

Run `./buddy.sh art` to open your `$EDITOR` with a JSON template:

```json
{
  "frames": [
    ["            ", " |\\    /|  ", " | \\__/ |  ", " ( {E} ω {E} )  ", "  (\")\\_(\")  "],
    ["            ", " |\\    /|  ", " | \\__/ |  ", " ( {E} ω {E} )  ", "  (\")\\_(\")~ "],
    ["            ", " |\\    /|  ", " | \\--/ |  ", " ( {E} ω {E} )  ", "  (\")\\_(\")  "]
  ]
}
```

This renders as a **Pikachu** (피카츄):

```
  Frame 1:         Frame 2:         Frame 3:
  |\    /|         |\    /|         |\    /|
  | \__/ |         | \__/ |         | \--/ |
  ( · ω · )        ( · ω · )        ( · ω · )
   (")_(")          (")_(")~         (")_(")
```

### Art format rules

- `frames`: array of 1–5 frames (animation)
- Each frame: exactly **5 strings**, each **12 chars** wide (pad with spaces)
- `{E}` is replaced with the eye character at render time
- Line 1: leave empty (`"            "`) to allow hat rendering

### Pikachu `~/.claude.json` example

```json
{
  "companion": {
    "name": "피카츄",
    "personality": "전기 뿜는 귀여운 포켓몬",
    "species": "ghost",
    "eye": "·",
    "hat": "none",
    "F": [
      ["            ", " |\\    /|  ", " | \\__/ |  ", " ( {E} ω {E} )  ", "  (\")\\_(\")  "],
      ["            ", " |\\    /|  ", " | \\__/ |  ", " ( {E} ω {E} )  ", "  (\")\\_(\")~ "],
      ["            ", " |\\    /|  ", " | \\--/ |  ", " ( {E} ω {E} )  ", "  (\")\\_(\")  "]
    ]
  }
}
```

> `species` is still required (any valid name) for internal compatibility, but the rendered art comes entirely from `F`.

## How It Works

Claude Code determines companion traits using a hash:

```
seed = accountUuid + "friend-2026-401"
hash = RE4(DE4(ME4(seed)))
species = speciesList[floor(hash() * 18)]
```

The binary merges config and hash with `{...config, ...bones}` — bones (hash values) always win. Two patches are applied:

1. **Config override**: Flips `{...config, ...bones}` to `{...bones, ...config}`, so `~/.claude.json` settings take priority
2. **Custom art renderer**: Changes `sy7[H.species]` to `H.F||sy7[H.species]` in the `Wr_` function, so custom frames from config are used before the built-in species art table

Both patches are exactly the same byte length as the original code (no binary size change).

## Notes

- **Restart required**: All changes take effect after restarting Claude Code
- **Re-patch after updates**: Claude Code updates replace the binary, so re-run `./buddy.sh patch`
- **macOS only**: The patch uses `codesign` for ad-hoc re-signing
- **Safe**: A backup is created before patching; restore anytime with `./buddy.sh patch restore`
- **Config location**: `~/.claude.json` → `companion` object

## License

MIT
