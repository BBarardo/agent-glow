# claude-rgb

SignalRGB lighting driven by Claude Code hooks. User-facing docs: README.md.

- `rgb.ps1` is everything. `install` copies the effects and writes the hooks to `~/.claude/settings.json`; it is idempotent and keeps other hooks.
- `effects/*.html` is the source of truth. After editing, run `rgb.ps1 install` and restart SignalRGB.
- Runtime state (gitignored): `normal.txt`, `normal.url`, `mode.txt`, `timer.pid`.
- Hooks run in **bash** (Git Bash), not cmd. Keep the SessionEnd hook to a bare `explorer.exe` call, because Claude exits before PowerShell would start.
- Test from PowerShell: `.\rgb.ps1 work`, `.\rgb.ps1 idle`, then check `HKCU:\Software\WhirlwindFX\SignalRgb\effects\selected`.
