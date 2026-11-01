$script:HeiGeWorkBuddySessionTaskName = "WorkBuddy Skin Studio Session"

function Remove-HeiGeWorkBuddySessionTask {
    $task = Get-ScheduledTask -TaskName $script:HeiGeWorkBuddySessionTaskName `
        -ErrorAction SilentlyContinue
    if ($null -eq $task) { return }
    if ([string]$task.State -ceq "Running") {
        Stop-ScheduledTask -TaskName $script:HeiGeWorkBuddySessionTaskName `
            -ErrorAction SilentlyContinue
    }
    Unregister-ScheduledTask -TaskName $script:HeiGeWorkBuddySessionTaskName `
        -Confirm:$false -ErrorAction SilentlyContinue
}

function Start-HeiGeWorkBuddyScheduledSession {
    param(
        [Parameter(Mandatory = $true)][string]$ExecutablePath,
        [ValidateRange(0, 65535)][int]$Port = 0
    )
    Remove-HeiGeWorkBuddySessionTask
    $hostScript = Join-Path (Split-Path $PSScriptRoot -Parent) "workbuddy-session-host.ps1"
    if (-not (Test-Path -LiteralPath $hostScript -PathType Leaf)) {
        throw "WorkBuddy session host script is missing: $hostScript"
    }
    foreach ($item in @($ExecutablePath, $hostScript)) {
        if ([string]$item -match '[\r\n"]') {
            throw "WorkBuddy session task path contains unsupported characters."
        }
    }
    $powershell = Join-Path $PSHOME "powershell.exe"
    $arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass ' +
        '-File "' + $hostScript + '" -ExecutablePath "' + $ExecutablePath +
        '" -Port ' + [string]$Port
    $action = New-ScheduledTaskAction -Execute $powershell -Argument $arguments
    $userName = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $principal = New-ScheduledTaskPrincipal -UserId $userName -LogonType Interactive `
        -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
    Register-ScheduledTask -TaskName $script:HeiGeWorkBuddySessionTaskName `
        -Action $action -Principal $principal -Settings $settings -Force | Out-Null
    Start-ScheduledTask -TaskName $script:HeiGeWorkBuddySessionTaskName
    return [pscustomobject][ordered]@{
        Pid = 0
        Method = "scheduled-session"
        TaskName = $script:HeiGeWorkBuddySessionTaskName
    }
}

function Start-HeiGeWorkBuddySession {
    param(
        [Parameter(Mandatory = $true)]$AppInfo,
        [ValidateRange(0, 65535)][int]$Port = 0
    )

    if (
        [string]$AppInfo.Kind -cne "Win32" -or
        [string]$AppInfo.ProductName -cne "WorkBuddy"
    ) {
        throw "WorkBuddy session launcher requires the verified Win32 WorkBuddy identity."
    }
    $resolved = [System.IO.Path]::GetFullPath([string]$AppInfo.ExecutablePath)
    if (
        [System.IO.Path]::GetFileName($resolved) -cne "WorkBuddy.exe" -or
        -not (Test-Path -LiteralPath $resolved -PathType Leaf)
    ) {
        throw "Verified WorkBuddy executable is unavailable: $resolved"
    }
    if ($resolved -match '[\r\n"]') {
        throw "WorkBuddy executable path contains unsupported characters."
    }

    if (-not ("HeiGe.WorkBuddySessionProcess" -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

namespace HeiGe {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct WorkBuddyStartupInfo {
        public int cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;
        public int dwX;
        public int dwY;
        public int dwXSize;
        public int dwYSize;
        public int dwXCountChars;
        public int dwYCountChars;
        public int dwFillAttribute;
        public int dwFlags;
        public short wShowWindow;
        public short cbReserved2;
        public IntPtr lpReserved2;
        public IntPtr hStdInput;
        public IntPtr hStdOutput;
        public IntPtr hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct WorkBuddyProcessInfo {
        public IntPtr hProcess;
        public IntPtr hThread;
        public int dwProcessId;
        public int dwThreadId;
    }

    public static class WorkBuddySessionProcess {
        const uint CreateNoWindow = 0x08000000;
        const uint CreateNewProcessGroup = 0x00000200;
        const uint CreateBreakawayFromJob = 0x01000000;

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool CreateProcess(
            string lpApplicationName,
            StringBuilder lpCommandLine,
            IntPtr lpProcessAttributes,
            IntPtr lpThreadAttributes,
            bool bInheritHandles,
            uint dwCreationFlags,
            IntPtr lpEnvironment,
            string lpCurrentDirectory,
            ref WorkBuddyStartupInfo lpStartupInfo,
            out WorkBuddyProcessInfo lpProcessInformation);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool CloseHandle(IntPtr hObject);

        public static bool Launch(string applicationName, bool breakaway, out int pid, out int win32Error) {
            var si = new WorkBuddyStartupInfo();
            si.cb = Marshal.SizeOf(typeof(WorkBuddyStartupInfo));
            WorkBuddyProcessInfo pi;
            // WorkBuddy is launched from a double-clicked batch file.  Without
            // CREATE_NO_WINDOW it stays attached to that batch file's console,
            // so closing the console also terminates WorkBuddy and the skin.
            uint flags = CreateNoWindow | CreateNewProcessGroup;
            if (breakaway) flags |= CreateBreakawayFromJob;
            var commandLine = new StringBuilder("\"" + applicationName + "\"");
            var workingDirectory = System.IO.Path.GetDirectoryName(applicationName);
            if (!CreateProcess(applicationName, commandLine, IntPtr.Zero, IntPtr.Zero, false,
                flags, IntPtr.Zero, workingDirectory, ref si, out pi)) {
                pid = 0;
                win32Error = Marshal.GetLastWin32Error();
                return false;
            }
            pid = pi.dwProcessId;
            win32Error = 0;
            if (pi.hThread != IntPtr.Zero) CloseHandle(pi.hThread);
            if (pi.hProcess != IntPtr.Zero) CloseHandle(pi.hProcess);
            return pid > 0;
        }
    }
}
"@
    }

    [int]$pidValue = 0
    [int]$win32Error = 0
    $method = "breakaway"
    $ok = [HeiGe.WorkBuddySessionProcess]::Launch(
        $resolved, $true, [ref]$pidValue, [ref]$win32Error
    )
    if (-not $ok) {
        return Start-HeiGeWorkBuddyScheduledSession -ExecutablePath $resolved -Port $Port
    }
    return [pscustomobject][ordered]@{
        Pid = [int]$pidValue
        Method = $method
    }
}
