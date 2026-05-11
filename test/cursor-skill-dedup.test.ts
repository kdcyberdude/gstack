import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { execSync } from 'child_process';

const ROOT = path.resolve(import.meta.dir, '..');

function mkTmpHome(): string {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'gstack-cursor-dedup-'));
}

function countSkillDirs(root: string, folderName: string): number {
  if (!fs.existsSync(root)) {
    return 0;
  }
  let count = 0;
  const stack = [root];
  while (stack.length > 0) {
    const dir = stack.pop()!;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      let isDir = entry.isDirectory();
      if (!isDir && entry.isSymbolicLink()) {
        try {
          isDir = fs.statSync(full).isDirectory();
        } catch {
          isDir = false;
        }
      }
      if (!isDir) {
        continue;
      }
      if (entry.name === folderName && fs.existsSync(path.join(full, 'SKILL.md'))) {
        count += 1;
      }
      stack.push(full);
    }
  }
  return count;
}

describe('cursor skill dedup setup', () => {
  let tmpHome: string;
  let repoDir: string;
  let setupScript: string;

  beforeEach(() => {
    tmpHome = mkTmpHome();
    fs.mkdirSync(path.join(tmpHome, '.cursor'), { recursive: true });
    repoDir = path.join(tmpHome, '.gstack', 'repos', 'gstack');
    fs.mkdirSync(repoDir, { recursive: true });
    execSync(
      `rsync -a --exclude node_modules --exclude .git "${ROOT}/" "${repoDir}/"`,
      { stdio: 'pipe' },
    );
    setupScript = path.join(repoDir, 'setup');
  });

  afterEach(() => {
    fs.rmSync(tmpHome, { recursive: true, force: true });
  });

  test(
    'setup --host cursor keeps one gstack-scrape entry under ~/.cursor/skills',
    () => {
      execSync(`bash "${setupScript}" --host cursor --quiet --no-prefix`, {
        env: { ...process.env, HOME: tmpHome, GSTACK_SETUP_RUNNING: '1' },
        stdio: 'pipe',
        timeout: 180000,
      });

      const cursorSkills = path.join(tmpHome, '.cursor', 'skills');
      expect(countSkillDirs(cursorSkills, 'gstack-scrape')).toBe(1);
      expect(fs.existsSync(path.join(cursorSkills, 'gstack', 'goal', 'SKILL.md'))).toBe(true);
      expect(fs.existsSync(path.join(cursorSkills, 'gstack-goal', 'SKILL.md'))).toBe(false);
      expect(countSkillDirs(path.join(tmpHome, '.codex', 'skills'), 'gstack-scrape')).toBe(0);
      expect(countSkillDirs(path.join(repoDir, '.cursor', 'skills'), 'gstack-scrape')).toBe(0);
      expect(countSkillDirs(path.join(repoDir, '.agents', 'skills'), 'gstack-scrape')).toBe(0);
    },
    180000,
  );
});
