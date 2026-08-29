# hack.ps1 - fake "pro hacker" terminal feed. Ctrl+C to bail.
# ponytail: pure eye-candy, no real work done. Random lines forever.
$ErrorActionPreference = 'SilentlyContinue'
$Host.UI.RawUI.WindowTitle = 'root@tcf:~# breach'
try { $Host.UI.RawUI.BackgroundColor = 'Black'; Clear-Host } catch {}

function Hex([int]$n) { -join (1..$n | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) }) }
function IP { "{0}.{1}.{2}.{3}" -f (Get-Random -Max 256),(Get-Random -Max 256),(Get-Random -Max 256),(Get-Random -Max 256) }

$hosts  = 'tcfserver','nas-01','fw-edge','db-prod','mail-gw','ad-dc01','vpn-core','10.0.0.7'
$verbs  = 'scanning','injecting','bypassing','decrypting','spoofing','tunneling','pivoting','exfiltrating','bruteforce','fuzzing'
$targets= '/etc/shadow','port 22','kernel ring0','TLS handshake','RSA-2048 key','session token','root hash','firewall ACL','payload.bin'
$ok     = 'OK','DONE','PWNED','200 OK','ACCESS GRANTED','ROOT','BYPASSED'

# ascii banner
$banner = @'
   ___  ___  ____  ___    ___  ____  ____
  / _ )/ _ \/ __/ / _ |  / _ \/ __/ / __/
 / _  / , _/ _/  / __ | / , _/ _/  / _/
/____/_/|_/___/ /_/ |_|/_/|_/___/ /___/   v3.14
'@
Write-Host $banner -ForegroundColor Green
Write-Host "[*] initializing exploit framework..." -ForegroundColor DarkGreen
Start-Sleep -Milliseconds 600

while ($true) {
    $roll = Get-Random -Max 100
    if ($roll -lt 55) {
        $line = "[{0}] {1} {2} -> {3} :: {4}" -f (IP), (Get-Random $verbs), (Get-Random $targets), (Get-Random $hosts), (Hex (Get-Random -Min 2 -Max 8))
        $c = 'Green'
    } elseif ($roll -lt 75) {
        $line = "0x{0}  {1}" -f (Hex 8), (Hex (Get-Random -Min 8 -Max 24))
        $c = 'DarkGreen'
    } elseif ($roll -lt 88) {
        $pct = Get-Random -Max 101
        $bar = ('#' * [int]($pct/4)).PadRight(25,'.')
        $line = "  [{0}] {1}% {2}" -f $bar, $pct, (Get-Random $targets)
        $c = 'Cyan'
    } else {
        $line = "  >>> {0}  ({1})" -f (Get-Random $ok), (Get-Random $hosts)
        $c = 'White'
    }
    Write-Host $line -ForegroundColor $c
    Start-Sleep -Milliseconds (Get-Random -Min 25 -Max 160)
}
