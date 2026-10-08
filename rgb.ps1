# agent-glow: SignalRGB lighting that follows Claude Code's state.
# usage (called by hooks/hooks.json): rgb.ps1 start | work | idle   (timer is internal)
$d = if ($env:CLAUDE_PLUGIN_DATA) { $env:CLAUDE_PLUGIN_DATA } else { "$env:USERPROFILE\.claude\agent-glow" }
New-Item -ItemType Directory -Force $d | Out-Null
$state = "$d\normal.txt"; $pidf = "$d\timer.pid"
$IdleMinutes = 20

function Apply($n) { Start-Process "signalrgb://effect/apply/$([uri]::EscapeDataString($n))?-silentlaunch-" }
function Mark($m) { Set-Content "$d\mode.txt" $m }

function Timer {
  # single timer: kill the previous one and start fresh (counter reset)
  if (Test-Path $pidf) {
    $o = Get-CimInstance Win32_Process -Filter "ProcessId=$(Get-Content $pidf)"
    if ($o.CommandLine -match 'rgb\.ps1.*timer') { Stop-Process -Id $o.ProcessId -Force }  # PID may have been reused
  }
  $p = Start-Process powershell -WindowStyle Hidden -PassThru -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", 'timer'
  Set-Content $pidf $p.Id
}

switch ($args[0]) {
  'start' {
    # keep SignalRGB's copy of the effects in sync with the plugin (new effects need a SignalRGB restart)
    Copy-Item "$PSScriptRoot\effects\*.html" "$env:USERPROFILE\Documents\WhirlwindFX\Effects\" -Force -EA 0
    $cur = (Get-ItemProperty HKCU:\Software\WhirlwindFX\SignalRgb\effects\selected -EA 0).name
    if ($cur -and $cur -notlike 'Claude *') {
      Set-Content $state $cur
      Set-Content "$d\normal.url" "signalrgb://effect/apply/$([uri]::EscapeDataString($cur))?-silentlaunch-"
    }
    Mark idle; Apply 'Claude Idle'; Timer
  }
  'work'  { Mark work; Apply 'Claude Working' }
  'idle'  { Mark idle; Apply 'Claude Idle'; Timer }
  # detached process, survives closing the terminal; idle too long -> back to the user's effect
  'timer' {
    Start-Sleep ($IdleMinutes * 60)
    if ((Get-Content "$d\mode.txt") -eq 'idle' -and (Test-Path $state)) { Mark normal; Apply (Get-Content $state) }
    Remove-Item $pidf -EA 0
  }
}
