#!/usr/bin/env bun
// Claude Code Companion Species Simulator & Changer (시뮬레이터 & 체인저)
// Must be run with bun (Bun.hash required) (반드시 bun으로 실행)
//
// Usage (사용법):
//   bun companion-species.mjs              # Check current account's species (현재 계정의 species 확인)
//   bun companion-species.mjs list         # List all species (모든 species 리스트)
//   bun companion-species.mjs find dragon  # Find simulation seed for dragon (dragon 시뮬레이션 seed 찾기)
//   bun companion-species.mjs set dragon   # Disabled (비활성화됨) — prevents accountUuid corruption (UUID 손상 방지)
//   bun companion-species.mjs repair       # Recover accountUuid from backup UUID (백업 UUID로 복구)
//   bun companion-species.mjs restore      # Restore original UUID (원본 UUID 복원)

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { homedir } from 'os';

const SUFFIX = "friend-2026-401";
const SPECIES = [
  "duck","goose","blob","cat","dragon","octopus","owl","penguin",
  "turtle","snail","ghost","axolotl","capybara","cactus","robot",
  "rabbit","mushroom","chonk"
];
const EYES = ["·","✦","×","◉","@","°"];
const HATS = ["none","crown","tophat","propeller","halo","wizard","beanie","tinyduck"];
const RARITY_ORDER = ["common","uncommon","rare","epic","legendary"];
const RARITY_WEIGHTS = { common:60, uncommon:25, rare:10, epic:4, legendary:1 };
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function hash(str) {
  return Number(BigInt(Bun.hash(str)) & 0xffffffffn);
}

function makePRNG(seed) {
  let s = seed >>> 0;
  return function() {
    s |= 0;
    s = s + 1831565813 | 0;
    let t = Math.imul(s ^ s >>> 15, 1 | s);
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  };
}

function pick(rng, arr) {
  return arr[Math.floor(rng() * arr.length)];
}

function getRarity(rng) {
  const total = Object.values(RARITY_WEIGHTS).reduce((a, b) => a + b, 0);
  let r = rng() * total;
  for (const k of RARITY_ORDER) {
    r -= RARITY_WEIGHTS[k];
    if (r < 0) return k;
  }
  return "common";
}

function simulate(seed) {
  const h = hash(seed + SUFFIX);
  const rng = makePRNG(h);
  const rarity = getRarity(rng);
  const species = pick(rng, SPECIES);
  const eye = pick(rng, EYES);
  const hat = rarity === "common" ? "none" : pick(rng, HATS);
  const shiny = rng() < 0.01;
  return { rarity, species, eye, hat, shiny };
}

function getConfig() {
  return JSON.parse(readFileSync(`${homedir()}/.claude.json`, 'utf8'));
}

function getConfigPath() {
  return `${homedir()}/.claude.json`;
}

function getBackupPath() {
  return `${homedir()}/.claude-uuid-backup`;
}

function isUuid(value) {
  return typeof value === 'string' && UUID_RE.test(value);
}

function readBackupUuid() {
  const backupPath = getBackupPath();
  if (!existsSync(backupPath)) return null;
  const uuid = readFileSync(backupPath, 'utf8').trim();
  return uuid || null;
}

function getAccountUuid() {
  const config = getConfig();
  return config.oauthAccount?.accountUuid || config.userID || "anon";
}

function findSeedForSpecies(targetSpecies, targetRarity) {
  const results = [];
  for (let i = 0; i < 500000; i++) {
    const seed = `fake-${i.toString(36)}`;
    const result = simulate(seed);
    if (result.species === targetSpecies) {
      if (!targetRarity || result.rarity === targetRarity) {
        results.push({ seed, ...result });
        if (results.length >= 5) break;
      }
    }
  }
  return results;
}

function applySpeciesChange(targetSpecies, targetRarity) {
  const config = getConfig();
  const currentUuid = config.oauthAccount?.accountUuid;
  const backupUuid = readBackupUuid();

  console.error("❌ The `set` command is disabled (비활성화됨).");
  console.error("The previous version wrote fake-* values to oauthAccount.accountUuid,");
  console.error("which could cause Claude Code to crash on startup (시작 중 크래시할 수 있습니다).");
  console.error("Species is calculated from the account UUID, so there is no safe way to force-change it");
  console.error("(species는 계정 UUID에서 계산되므로 안전하게 강제 변경할 수 있는 방법이 없습니다).");

  if (currentUuid && !isUuid(currentUuid) && isUuid(backupUuid)) {
    console.error(`\nRecoverable (복구 가능): bun companion-species.mjs repair`);
    console.error(`Backup UUID (백업 UUID): ${backupUuid}`);
  }

  process.exit(1);
}

function restoreUuid(uuid) {
  const configPath = getConfigPath();
  const config = getConfig();

  if (!config.oauthAccount) config.oauthAccount = {};

  if (!uuid) {
    uuid = readBackupUuid();
    if (!uuid) { console.error("No backup UUID found (백업 UUID 없음)"); process.exit(1); }
  }

  if (!isUuid(uuid)) {
    console.error(`Not a valid UUID (유효한 UUID 아님): ${uuid}`);
    process.exit(1);
  }

  config.oauthAccount.accountUuid = uuid;
  writeFileSync(configPath, JSON.stringify(config, null, 2));
  console.log(`✅ UUID restored (복원): ${uuid}`);
  console.log(`⚠  Restart Claude Code required (재시작 필요)`);
}

function repairAccountUuid() {
  const config = getConfig();
  const currentUuid = config.oauthAccount?.accountUuid;

  if (isUuid(currentUuid)) {
    console.log(`Already using a valid UUID (이미 유효한 UUID 사용 중): ${currentUuid}`);
    return;
  }

  const backupUuid = readBackupUuid();
  if (!backupUuid) {
    console.error("Recovery failed: no backup UUID (복구 실패: 백업 UUID 없음)");
    process.exit(1);
  }
  if (!isUuid(backupUuid)) {
    console.error(`Recovery failed: invalid backup UUID format (복구 실패: 백업 UUID 형식이 잘못됨) (${backupUuid})`);
    process.exit(1);
  }

  restoreUuid(backupUuid);
}

// CLI
const args = process.argv.slice(2);
const cmd = args[0] || 'show';

switch (cmd) {
  case 'show': {
    const uuid = getAccountUuid();
    const backupUuid = readBackupUuid();
    const c = simulate(uuid);
    console.log("=== Current Companion (현재 Companion) ===");
    console.log(`UUID:    ${uuid}`);
    if (!isUuid(uuid)) {
      console.log("Warning (경고): Current oauthAccount.accountUuid is not a valid UUID.");
      if (isUuid(backupUuid)) {
        console.log(`Recover (복구):  bun companion-species.mjs repair`);
        console.log(`Backup (백업):   ${backupUuid}`);
      }
    }
    console.log(`Species: ${c.species}`);
    console.log(`Rarity:  ${c.rarity}`);
    console.log(`Eye:     ${c.eye}`);
    console.log(`Hat:     ${c.hat}`);
    console.log(`Shiny:   ${c.shiny}`);
    break;
  }
  case 'list': {
    console.log("=== Species List (리스트) — 18 types ===");
    SPECIES.forEach((s, i) => console.log(`  ${(i+1).toString().padStart(2)}. ${s}`));
    break;
  }
  case 'find': {
    const target = args[1];
    const rarity = args[2];
    if (!target) { console.error("Usage (사용법): bun companion-species.mjs find <species> [rarity]"); process.exit(1); }
    if (!SPECIES.includes(target)) { console.error(`❌ Valid options (유효): ${SPECIES.join(', ')}`); process.exit(1); }
    console.log(`Searching for simulation seeds that produce '${target}' species...`);
    console.log(`(시뮬레이션 seed 검색 중...)`);
    console.log("⚠ Seeds below are preview-only — writing to accountUuid may break Claude Code");
    console.log("(아래 seed는 미리보기 전용이며 accountUuid에 쓰면 Claude Code가 망가질 수 있습니다)");
    const results = findSeedForSpecies(target, rarity);
    results.forEach(r => {
      console.log(`  seed: ${r.seed.padEnd(15)} rarity: ${r.rarity.padEnd(10)} eye: ${r.eye} hat: ${r.hat} shiny: ${r.shiny}`);
    });
    break;
  }
  case 'set': {
    const target = args[1];
    const rarity = args[2];
    if (!target) { console.error("Usage (사용법): bun companion-species.mjs set <species> [rarity]"); process.exit(1); }
    if (!SPECIES.includes(target)) { console.error(`❌ Valid options (유효): ${SPECIES.join(', ')}`); process.exit(1); }
    applySpeciesChange(target, rarity);
    break;
  }
  case 'restore': {
    restoreUuid(args[1]);
    break;
  }
  case 'repair': {
    repairAccountUuid();
    break;
  }
  default:
    console.log("Usage (사용법): bun companion-species.mjs {show|list|find|set|restore|repair}");
    console.log("  show              Check current companion species (현재 companion species 확인)");
    console.log("  list              List all species (전체 species 리스트)");
    console.log("  find <species>    Find simulation seeds for a species (시뮬레이션 seed 검색)");
    console.log("  set <species>     Disabled — prevents UUID corruption (비활성화됨, UUID 손상 방지)");
    console.log("  restore [uuid]    Restore original UUID (원본 UUID 복원)");
    console.log("  repair            Recover accountUuid from backup (백업 UUID로 accountUuid 복구)");
}
