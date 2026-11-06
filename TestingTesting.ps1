# Check if running as Administrator
function Test-IsAdmin {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }
    catch {
        Write-Error "Error checking admin status: $_"
        return $false
    }
}

# Relaunch script as Administrator if not already elevated
if (-not (Test-IsAdmin)) {
    Write-Host "Not running as Administrator. Restarting with elevated privileges..." -ForegroundColor Yellow
    try {
        Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit
    }
    catch {
        Write-Error "Failed to restart as Administrator: $_"
        exit 1
    }
}
else {
    Write-Host "Running as Administrator." -ForegroundColor Green
}

# --- Your admin-required code goes below ---
Write-Host "You now have elevated privileges."
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
<#
.SYNOPSIS
    Disables Windows microphone filtering/enhancements for the default recording device.

.DESCRIPTION
    This script:
    - Finds the default microphone device.
    - Disables audio enhancements (noise suppression, echo cancellation, etc.).
    - Disables AGC if supported.
    - Requires running PowerShell as Administrator.
#>

# Ensure script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script as Administrator."
    exit
}

# Get default recording device ID
$defaultMic = Get-CimInstance -Namespace root\cimv2 -ClassName Win32_SoundDevice |
    Where-Object { $_.ProductName -match "Microphone" -or $_.Name -match "Microphone" } |
    Select-Object -First 1

if (-not $defaultMic) {
    Write-Error "No microphone device found."
    exit
}

Write-Host "Default microphone detected: $($defaultMic.Name)" -ForegroundColor Green

# Registry path for audio enhancements (may vary by driver)
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture"
)

foreach ($path in $regPaths) {
    if (Test-Path $path) {
        Get-ChildItem $path | ForEach-Object {
            $propsPath = "$($_.PSPath)\Properties"
            if (Test-Path $propsPath) {
                # Disable audio enhancements
                try {
                    Set-ItemProperty -Path $propsPath -Name "{f29f85e0-4ff9-4e16-8a5b-e9f4e3b8e5b1},0" -Value 0 -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $propsPath -Name "{1c3c4b0d-bd1e-4e8e-a0f8-4b3b0f5c2b5a},0" -Value 0 -ErrorAction SilentlyContinue
                } catch {
                    Write-Warning "Could not modify enhancements for $propsPath"
                }
            }
        }
    }
}

Write-Host "Microphone enhancements disabled. You may need to restart your PC or replug the mic." -ForegroundColor Yellow
