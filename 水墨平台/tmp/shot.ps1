Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PW {
    [DllImport("user32.dll")] public static extern IntPtr FindWindow(string c, string t);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
    public struct RECT { public int L, T, R, B; }
}
"@
Add-Type -AssemblyName System.Drawing
$h = [PW]::FindWindow($null, "UrhoX")
if ($h -eq [IntPtr]::Zero) { $procs = Get-Process UrhoXRuntime -ErrorAction SilentlyContinue; if ($procs) { $h = $procs[0].MainWindowHandle } }
if ($h -eq [IntPtr]::Zero) { Write-Host "NO WINDOW"; exit 1 }
$r = New-Object PW+RECT
[PW]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.R - $r.L; $ht = $r.B - $r.T
Write-Host "rect: $($r.L),$($r.T) ${w}x${ht}"
if ($w -lt 200) { Write-Host "MINIMIZED"; exit 2 }
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$dc = $g.GetHdc()
[PW]::PrintWindow($h, $dc, 2) | Out-Null
$g.ReleaseHdc($dc); $g.Dispose()
$bmp.Save($args[0]); $bmp.Dispose()
Write-Host "saved $($args[0])"
