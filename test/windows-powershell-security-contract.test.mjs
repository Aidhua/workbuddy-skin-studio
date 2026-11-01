import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const repositoryRoot = dirname(dirname(fileURLToPath(import.meta.url)));

async function source(relativePath) {
  return readFile(join(repositoryRoot, relativePath), "utf8");
}

test("Windows PowerShell carries one immutable app identity through task and Node", async () => {
  const [scheduledTask, controller] = await Promise.all([
    source("scripts/windows/lib/scheduled-task.ps1"),
    source("scripts/windows/controller.ps1"),
  ]);
  assert.match(scheduledTask, /-AppIdentityToken/);
  assert.match(controller, /Resolve-HeiGeBoundCodexApp/);
  assert.match(controller, /AppIdentityToken/);
  assert.match(controller, /HEIGE_WINDOWS_APP_IDENTITY/);
  assert.match(scheduledTask, /ConvertFrom-HeiGeCodexAppIdentityToken/);
});

test("Windows icacls fallback sets owner with a starred SID in a separate invocation", async () => {
  const [common, secureFs] = await Promise.all([
    source("scripts/windows/lib/common.ps1"),
    source("src/windows-secure-fs.mjs"),
  ]);
  assert.match(common, /\/inheritance:r \/grant:r \$grant/);
  assert.match(common, /\/setowner "\*\$\{UserSid\}"/);
  assert.equal(common.includes("/inheritance:r /setowner"), false);
  assert.match(secureFs, /\/inheritance:r \/grant:r \$grant/);
  assert.match(secureFs, /\/setowner \('\*\{0\}' -f \$sidText\)/);
  assert.equal(secureFs.includes("/inheritance:r /setowner"), false);
});

test("Windows bound resolver is token-directed and the runtime rejects foreign app processes", async () => {
  const [common, runtime] = await Promise.all([
    source("scripts/windows/lib/common.ps1"),
    source("src/windows-runtime.mjs"),
  ]);
  assert.match(common, /PackageFullName/);
  assert.match(common, /InstallLocation/);
  assert.match(common, /Aumid/);
  assert.match(common, /OverridePath\s+\(\[string\]\$expected\.ExecutablePath\)/i);
  assert.match(runtime, /foreign Windows Codex process/i);
});

test("Windows WorkBuddy session launch is identity-bound and its task fallback is on-demand only", async () => {
  const [session, host, apply, restore] = await Promise.all([
    source("scripts/windows/lib/workbuddy-session.ps1"),
    source("scripts/windows/workbuddy-session-host.ps1"),
    source("scripts/windows/workbuddy-apply.ps1"),
    source("scripts/windows/workbuddy-restore.ps1"),
  ]);
  assert.match(session, /CreateNoWindow\s*=\s*0x08000000/);
  assert.match(session, /CreateNoWindow\s*\|\s*CreateNewProcessGroup/);
  assert.match(session, /CreateBreakawayFromJob/);
  assert.match(session, /New-ScheduledTaskPrincipal[\s\S]*-LogonType Interactive[\s\S]*-RunLevel Limited/);
  assert.match(session, /WorkBuddy Skin Studio Session/);
  assert.equal(session.includes("New-ScheduledTaskTrigger"), false);
  assert.match(host, /Resolve-WorkBuddyApp/);
  assert.match(host, /\$requested -cne \$expected/);
  assert.match(host, /Wait-Process/);
  assert.match(apply, /WORKBUDDY_REMOTE_DEBUGGING_PORT/);
  assert.match(apply, /Start-HeiGeWorkBuddySession/);
  assert.match(restore, /Remove-HeiGeWorkBuddySessionTask/);
});

test("successful WorkBuddy apply exits its batch console without waiting for input", async () => {
  const applyBatch = await source("scripts/windows/workbuddy-apply.bat");
  const pauses = applyBatch.match(/\bpause\b/g) ?? [];
  assert.equal(pauses.length, 1);
  assert.match(applyBatch, /if not "%HEIGE_EXIT%"=="0"[\s\S]*pause/);
});
