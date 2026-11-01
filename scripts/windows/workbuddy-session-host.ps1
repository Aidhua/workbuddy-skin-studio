param(
    [Parameter(Mandatory = $true)][string]$ExecutablePath,
    [ValidateRange(0, 65535)][int]$Port = 0
)
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\common.ps1")

$app = Resolve-WorkBuddyApp
$expected = [System.IO.Path]::GetFullPath([string]$app.ExecutablePath)
$requested = [System.IO.Path]::GetFullPath($ExecutablePath)
if (
    [string]$app.Kind -cne "Win32" -or
    [string]$app.ProductName -cne "WorkBuddy" -or
    $requested -cne $expected
) {
    throw "WorkBuddy session host executable does not match the verified app identity."
}

if ($Port -gt 0) {
    $env:WORKBUDDY_REMOTE_DEBUGGING_PORT = [string]$Port
} else {
    Remove-Item Env:WORKBUDDY_REMOTE_DEBUGGING_PORT -ErrorAction SilentlyContinue
}
$process = Start-Process -FilePath $expected -PassThru
Wait-Process -Id $process.Id
