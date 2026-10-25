# Relaunch the PROGRES tunnel (Algerian egress for Worker verification).
# Keep this running while the app is in use. If the URL changes,
# update PROGRES_TUNNEL in wrangler.toml and run: npx wrangler deploy
$exe = 'C:\Users\bense\AppData\Local\Temp\opencode\cloudflared.exe'
$log = 'C:\Users\bense\AppData\Local\Temp\opencode\tunnel.log'
Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-Item $log -ErrorAction SilentlyContinue
Start-Process -FilePath $exe -ArgumentList 'tunnel --no-autoupdate --url https://progres.mesrs.dz' -RedirectStandardError $log
Write-Output 'Tunnel starting... check the URL with:'
Write-Output "Select-String -Path '$log' -Pattern 'trycloudflare.com'"
