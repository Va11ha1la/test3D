param([string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path)
& (Join-Path $PSScriptRoot "build_main.ps1")
Get-Process -Name "UrhoXRuntime" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process -FilePath "C:\Program Files\TapTap\UrhoXRuntime\UrhoXRuntime.exe" -ArgumentList @(
    "scripts/main.generated.lua", "-project_dir=$ProjectRoot",
    "-debug_local=true", "-use_local_res=true", "-skip_login=true",
    "-width=1280", "-height=720"
) -WorkingDirectory $ProjectRoot
Write-Host "Ink 2D game (17 levels) launched."
