# Upstream Fork Rebase Kit

This kit lets you maintain your custom OpenCode/OAC changes as an **overlay** on top of upstream `OpenAgentsControl`.

## What It Solves

- Keep your custom behavior in a separate fork.
- Rebase/sync from upstream safely.
- Re-apply your local customization set quickly.

## Files

- `overlay-manifest.txt`: list of files to copy into fork's `.opencode/` (`source` or `source => target` format)
- `apply-overlay.ps1`: copy overlay files into target fork repo
- `verify-overlay.ps1`: hash-based verification that fork matches overlay
- `install-opencode-config.ps1`: install overlay files directly into local OpenCode config path (default: `~/.config/opencode`)

## One-Time Fork Setup

1. Fork upstream repo on GitHub.
2. Clone your fork locally.
3. Add upstream remote.

```powershell
git clone <your-fork-url> C:\work\OpenAgentsControl-fork
cd C:\work\OpenAgentsControl-fork
git remote add upstream https://github.com/darrenhinde/OpenAgentsControl.git
git fetch upstream
```

## Sync Upstream -> Fork Main

```powershell
cd C:\work\OpenAgentsControl-fork
git checkout main
git fetch upstream
git rebase upstream/main
git push origin main
```

## Apply Custom Overlay

Run from any location:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\bug95\.config\opencode\tools\fork-rebase\apply-overlay.ps1" -TargetRepo "C:\work\OpenAgentsControl-fork"
```

Optional checks:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\bug95\.config\opencode\tools\fork-rebase\verify-overlay.ps1" -TargetRepo "C:\work\OpenAgentsControl-fork"
```

## Install Directly To Local `.config/opencode`

If you want immediately usable local settings (without touching fork `.opencode`), run:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\work\OpenAgentsControl-fork\tools\fork-rebase\install-opencode-config.ps1"
```

Optional explicit target path:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\work\OpenAgentsControl-fork\tools\fork-rebase\install-opencode-config.ps1" -TargetPath "C:\Users\<you>\.config\opencode"
```

Manifest examples:

```text
commands/context.md => command/context.md
context/core/workflows/compact-protocol.md
```

## Commit on Custom Branch

```powershell
cd C:\work\OpenAgentsControl-fork
git checkout -b custom/protocol-overlay
git add .opencode
git commit -m "chore: apply local protocol/interaction overlay"
git push -u origin custom/protocol-overlay
```

## Update Loop (Recommended)

When upstream changes:

1. Sync `main` with `upstream/main`
2. Rebase your custom branch on updated `main`
3. Re-run `apply-overlay.ps1`
4. Resolve any conflicts and commit

This keeps your custom behavior reproducible and reviewable.

## Branch Hygiene (Automation)

The automation workflows now use fixed bot branches instead of timestamped names:

- `bot/upstream-sync-main`
- `bot/desktop-overlay-refresh`

And `Cleanup Generated Branches` removes stale generated branches (while preserving any branch that is the head of an open PR).

## If You Previously Created Wrong Paths

If an older overlay run created `.opencode/agents` or `.opencode/commands`, remove them once:

```powershell
cd C:\work\OpenAgentsControl-fork
Remove-Item -Recurse -Force ".opencode\agents" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".opencode\commands" -ErrorAction SilentlyContinue
```

Current manifest mappings target upstream layout (`.opencode/agent`, `.opencode/command`).
