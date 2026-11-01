param(
    [ValidateNotNullOrEmpty()][string]$Theme = "neutral-gradient",
    [ValidateRange(1024, 65535)][int]$Port = 9342,
    [switch]$Restart
)
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\common.ps1")
. (Join-Path $PSScriptRoot "lib\workbuddy-session.ps1")
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$app = Resolve-WorkBuddyApp
$runtime = Get-NodeRuntime -App $app
$env:HEIGE_WORKBUDDY_APP = [string]$app.ExecutablePath
$env:HEIGE_WINDOWS_APP_IDENTITY = ConvertTo-HeiGeCodexAppIdentityToken -App $app

if (-not (Test-CdpEndpoint -Port $Port)) {
    $running = @(Get-RunningCodex -AppInfo $app)
    if ($running.Count -gt 0 -and -not $Restart) {
        throw "WorkBuddy is running without CDP. Save current work, then rerun with -Restart."
    }
    if ($running.Count -gt 0) {
        Write-Host "Closing WorkBuddy normally and relaunching it on CDP port 9342..."
        Stop-CodexNormally -AppInfo $app | Out-Null
    }
    $previousPort = $env:WORKBUDDY_REMOTE_DEBUGGING_PORT
    try {
        $env:WORKBUDDY_REMOTE_DEBUGGING_PORT = [string]$Port
        Start-HeiGeWorkBuddySession -AppInfo $app -Port $Port | Out-Null
    } finally {
        $env:WORKBUDDY_REMOTE_DEBUGGING_PORT = $previousPort
    }
    $ready = $false
    for ($attempt = 0; $attempt -lt 180; $attempt++) {
        if (Test-CdpEndpoint -Port $Port) { $ready = $true; break }
        Start-Sleep -Milliseconds 250
    }
    if (-not $ready) { throw "WorkBuddy started, but CDP port 9342 did not open." }
}

$arguments = @(
    (Join-Path $root "src\cli.mjs"),
    "apply", "--app", "workbuddy", "--theme", $Theme, "--port", [string]$Port
)
$json = Invoke-SkinCli -Node ([string]$runtime.Path) -CliArgs $arguments
$result = $json | ConvertFrom-Json
if ([string]$result.mode -cne "active") {
    throw "WorkBuddy skin did not enter active mode: $json"
}
Write-Host "WorkBuddy skin applied: $Theme (persistence setting unchanged; use the in-app toggle)."
$result
