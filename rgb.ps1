# claude-rgb: SignalRGB lighting that follows Claude Code's state.
# usage: rgb.ps1 install | uninstall | start | work | idle   (timer is internal)
$d = $PSScriptRoot
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
  $p = Start-Process powershell -WindowStyle Hidden -PassThru -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, 'timer'
  Set-Content $pidf $p.Id
}

function Hooks($add) {
  $f = "$env:USERPROFILE\.claude\settings.json"
  $j = if (Test-Path $f) { Get-Content $f -Raw | ConvertFrom-Json } else { [pscustomobject]@{} }
  if (-not $j.hooks) { $j | Add-Member hooks ([pscustomobject]@{}) -Force }
  $ps = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  # SessionEnd: Claude exits before PowerShell would start, so use a bare explorer.exe call (hooks run in bash)
  $cmds = @{ SessionStart = "$ps start"; UserPromptSubmit = "$ps work"; Stop = "$ps idle"
             SessionEnd = "explorer.exe `"`$(cat '$($d -replace '\\','/')/normal.url')`"" }
  foreach ($e in $cmds.Keys) {
    $keep = @($j.hooks.$e | Where-Object { $_ -and -not ($_.hooks.command -match 'claude-rgb|rgb\.ps1|normal\.url') })
    if ($add) { $keep += @{ hooks = @(@{ type = 'command'; command = $cmds[$e] }) } }
    $j.hooks | Add-Member $e $keep -Force
  }
  $j | ConvertTo-Json -Depth 20 | Set-Content $f
}

switch ($args[0]) {
  'install'   { Copy-Item "$d\effects\*.html" "$env:USERPROFILE\Documents\WhirlwindFX\Effects\" -Force; Hooks $true
                'Installed. Restart SignalRGB and start a new Claude Code session.' }
  'uninstall' { Hooks $false; 'Hooks removed.' }
  'start' {
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
