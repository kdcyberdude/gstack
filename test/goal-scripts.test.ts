import { afterEach, describe, expect, test } from 'bun:test';
import { mkdtempSync, readFileSync, rmSync } from 'fs';
import { tmpdir } from 'os';
import path from 'path';
import { spawnSync } from 'child_process';

const ROOT = path.join(import.meta.dirname, '..');
const GOAL_SCRIPTS = path.join(ROOT, 'goal', 'scripts');

function runScript(
  script: string,
  args: string[] = [],
  env: Record<string, string> = {},
  cwd?: string,
) {
  return spawnSync('bash', [path.join(GOAL_SCRIPTS, script), ...args], {
    cwd,
    env: { ...process.env, ...env },
    encoding: 'utf-8',
  });
}

describe('goal scripts', () => {
  let workdir = '';

  afterEach(() => {
    if (workdir) {
      rmSync(workdir, { recursive: true, force: true });
      workdir = '';
    }
  });

  test('stores goal state under the project root, not GSTACK_STATE_ROOT', () => {
    workdir = mkdtempSync(path.join(tmpdir(), 'gstack-goal-'));
    spawnSync('git', ['init'], { cwd: workdir, stdio: 'pipe' });

    const set = runScript(
      'set.sh',
      ['Ship the goal command parity work'],
      { GOAL_PROJECT_ROOT: workdir, GSTACK_STATE_ROOT: path.join(workdir, 'wrong-root') },
      workdir,
    );
    expect(set.status).toBe(0);

    const statePath = path.join(workdir, '.goal', 'state.json');
    expect(statePath).toBeTruthy();
    const state = JSON.parse(readFileSync(statePath, 'utf-8'));
    expect(state.objective).toBe('Ship the goal command parity work');
    expect(state.status).toBe('active');
  });

  test('session_start_hook emits Cursor additional_context', () => {
    workdir = mkdtempSync(path.join(tmpdir(), 'gstack-goal-'));
    spawnSync('git', ['init'], { cwd: workdir, stdio: 'pipe' });
    runScript('set.sh', ['Keep the inbox triaged'], { GOAL_PROJECT_ROOT: workdir }, workdir);

    const hook = spawnSync(
      'bash',
      [path.join(GOAL_SCRIPTS, 'session_start_hook.sh')],
      {
        cwd: workdir,
        env: { ...process.env, GOAL_PROJECT_ROOT: workdir },
        input: JSON.stringify({ composer_mode: 'agent', is_background_agent: false }),
        encoding: 'utf-8',
      },
    );
    expect(hook.status).toBe(0);

    const payload = JSON.parse(hook.stdout.trim());
    expect(payload.additional_context).toContain('[Project goal]');
    expect(payload.additional_context).toContain('Keep the inbox triaged');
  });

  test('dispatch routes pause, resume, and clear without treating them as objectives', () => {
    workdir = mkdtempSync(path.join(tmpdir(), 'gstack-goal-'));
    spawnSync('git', ['init'], { cwd: workdir, stdio: 'pipe' });
    runScript('set.sh', ['Keep working on hooks'], { GOAL_PROJECT_ROOT: workdir }, workdir);

    const pause = runScript('dispatch.sh', ['pause'], { GOAL_PROJECT_ROOT: workdir }, workdir);
    expect(pause.status).toBe(0);
    expect(pause.stdout).toContain('Status:    paused');

    const resume = runScript('dispatch.sh', ['resume'], { GOAL_PROJECT_ROOT: workdir }, workdir);
    expect(resume.status).toBe(0);
    expect(resume.stdout).toContain('Status:    active');

    const stop = runScript('dispatch.sh', ['stop'], { GOAL_PROJECT_ROOT: workdir }, workdir);
    expect(stop.status).toBe(0);
    expect(stop.stdout).toContain('Status:    paused');

    const clear = runScript('dispatch.sh', ['clear'], { GOAL_PROJECT_ROOT: workdir }, workdir);
    expect(clear.status).toBe(0);
    expect(clear.stdout).toContain('No goal set');
  });

  test('stop_hook emits followup_message for active goals with unchecked plan items', () => {
    workdir = mkdtempSync(path.join(tmpdir(), 'gstack-goal-'));
    spawnSync('git', ['init'], { cwd: workdir, stdio: 'pipe' });
    runScript('set.sh', ['Finish the goal hook wiring'], { GOAL_PROJECT_ROOT: workdir }, workdir);
    Bun.write(
      path.join(workdir, '.goal', 'plan.md'),
      '# Active Plan\n- [ ] Wire Cursor stop hook\n',
    );

    const hook = spawnSync(
      'bash',
      [path.join(GOAL_SCRIPTS, 'stop_hook.sh')],
      {
        cwd: workdir,
        env: { ...process.env, GOAL_PROJECT_ROOT: workdir },
        input: JSON.stringify({ status: 'completed', loop_count: 0 }),
        encoding: 'utf-8',
      },
    );
    expect(hook.status).toBe(0);

    const payload = JSON.parse(hook.stdout.trim());
    expect(payload.followup_message).toContain('Wire Cursor stop hook');
    expect(payload.followup_message).toContain('Finish the goal hook wiring');
  });

  test('session_start_hook emits Claude/Codex hookSpecificOutput', () => {
    workdir = mkdtempSync(path.join(tmpdir(), 'gstack-goal-'));
    spawnSync('git', ['init'], { cwd: workdir, stdio: 'pipe' });
    runScript('set.sh', ['Wire hooks across hosts'], { GOAL_PROJECT_ROOT: workdir }, workdir);

    const hook = spawnSync(
      'bash',
      [path.join(GOAL_SCRIPTS, 'session_start_hook.sh')],
      {
        cwd: workdir,
        env: { ...process.env, GOAL_PROJECT_ROOT: workdir },
        input: JSON.stringify({ hook_event_name: 'SessionStart', cwd: workdir }),
        encoding: 'utf-8',
      },
    );
    expect(hook.status).toBe(0);

    const payload = JSON.parse(hook.stdout.trim());
    expect(payload.hookSpecificOutput.hookEventName).toBe('SessionStart');
    expect(payload.hookSpecificOutput.additionalContext).toContain('Wire hooks across hosts');
  });
});
