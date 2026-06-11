param([string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path)
Get-Process -Name "UrhoXRuntime" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process -FilePath "C:\Program Files\TapTap\UrhoXRuntime\UrhoXRuntime.exe" -ArgumentList @(
    "scripts/main3d_dragon.lua", "-project_dir=$ProjectRoot",
    "-debug_local=true", "-use_local_res=true", "-skip_login=true",
    "-width=1280", "-height=720"
) -WorkingDirectory $ProjectRoot
Write-Host "3D Dragon scene launched."
