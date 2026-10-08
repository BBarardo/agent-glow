# agent-glow

Your PC's RGB lighting shows what Claude Code is doing. It glows orange while a session is open, pulses while Claude works, and returns to your usual SignalRGB effect when you exit or leave it idle.

Built with [Claude Code hooks](https://docs.claude.com/en/docs/claude-code/hooks) and [SignalRGB](https://signalrgb.com). It works on SignalRGB's free tier, with no Pro API needed.

## What it does

| Claude Code                     | Lights                                    |
|---------------------------------|-------------------------------------------|
| Session starts                  | Solid orange (`Claude Idle`)              |
| You send a prompt, Claude works | Pulsing orange (`Claude Working`)         |
| Claude finishes, waiting on you | Solid orange                              |
| Idle for 20 minutes             | Back to your own effect                   |
| `/exit`                         | Back to your own effect                   |

When a session starts, the script saves whatever effect you had active. That is the effect it brings back later, so you don't have to configure your "normal" theme anywhere.

## Requirements

- Windows with Windows PowerShell 5.1+ (built in)
- [SignalRGB](https://signalrgb.com) (the free tier is enough)
- [Claude Code](https://docs.claude.com/en/docs/claude-code)

## Install

agent-glow is a Claude Code plugin. Inside Claude Code, run:

```
/plugin marketplace add BBarardo/agent-glow
/plugin install agent-glow@agent-glow
```

Then:

1. Open a new Claude Code session. On its first start, the plugin copies its effects to `Documents\WhirlwindFX\Effects`.
2. Restart SignalRGB once so it picks up the new effects.

To turn it off, disable or uninstall it from `/plugin`.

## How it works

- **Switching effects:** SignalRGB's REST API needs Pro, so the script uses the `signalrgb://effect/apply/<name>` URL scheme instead.
- **Remembering your effect:** the active effect is read from the registry (`HKCU:\Software\WhirlwindFX\SignalRgb\effects\selected`) when a session starts.
- **Idle timer:** there is only one timer process at a time. Each `Stop` kills the previous one and starts a fresh one. The process is detached, so it also fires if you close the terminal without `/exit`.
- **SessionEnd hook:** this hook only calls `explorer.exe`. Claude Code exits before a PowerShell process would finish starting.

## Customize

- **Color:** change `COLOR` in `effects/*.html`, then start a new session and restart SignalRGB.
- **Idle timeout:** change `$IdleMinutes` in `rgb.ps1`.
- **Effects:** each one is a plain 320×200 canvas page. See [SignalRGB's effect docs](https://docs.signalrgb.com).

## Known limitations

- **Esc:** interrupting Claude with Esc doesn't fire the `Stop` hook. The lights keep pulsing until your next prompt.
- **Several sessions:** if you run more than one session at a time, the lights follow whichever session changed state last.
- **Switching effects mid-session:** if you change your SignalRGB effect while a session is open, the effect saved at session start is the one that comes back.

## License

MIT
