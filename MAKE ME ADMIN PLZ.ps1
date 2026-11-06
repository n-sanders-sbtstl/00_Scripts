# Check if running as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
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