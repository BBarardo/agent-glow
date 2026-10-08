# agent-glow

Claude Code plugin: SignalRGB lighting driven by hooks. User-facing docs: README.md.

- `hooks/hooks.json` wires the session events to `rgb.ps1 start|work|idle`. `SessionEnd` is a bare `explorer.exe` call, because Claude exits before PowerShell would start. Hooks run in **bash** (Git Bash), not cmd.
- `rgb.ps1` holds all the logic. Runtime state lives in `$CLAUDE_PLUGIN_DATA` (fallback `~/.claude/agent-glow`): `normal.txt`, `normal.url`, `mode.txt`, `timer.pid`.
- `effects/*.html` is the source of truth. `start` copies the effects into SignalRGB on every session; a brand-new effect only shows up after a SignalRGB restart.
- Validate with `claude plugin validate .`. Test from PowerShell: `.\rgb.ps1 work`, `.\rgb.ps1 idle`, then check `HKCU:\Software\WhirlwindFX\SignalRgb\effects\selected`.
