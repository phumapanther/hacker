# ai.ps1 - fake "AI is thinking/computing" terminal feed. Ctrl+C to stop.
# ponytail: eye-candy twin of hack.ps1, AI-flavored. No real inference.
$ErrorActionPreference = 'SilentlyContinue'
$Host.UI.RawUI.WindowTitle = 'neural-core :: inference'
try { $Host.UI.RawUI.BackgroundColor = 'Black'; Clear-Host } catch {}

function F { '{0:N4}' -f (Get-Random -Min 0.0 -Max 1.0) }
function Vec([int]$n) { '[' + (( 1..$n | ForEach-Object { '{0:+0.00;-0.00}' -f (Get-Random -Min -3.0 -Max 3.0) }) -join ' ') + ']' }
function Dim { $s='128','256','512','768','1024','2048','4096'; "{0}x{1}" -f (Get-Random $s),(Get-Random $s) }

$think = 'evaluating hypothesis','pruning search tree','back-propagating gradient','sampling next token',
         'aligning attention heads','contrasting embeddings','minimizing loss surface','expanding reasoning chain',
         'cross-checking constraints','weighing trade-offs','collapsing probability mass','resolving ambiguity'
$layers= 'attention','feed-forward','layernorm','embedding','softmax','residual','gelu','rotary-pos'
$topics= 'query vector','key/value cache','context window','logit bias','beam candidate','token graph','policy head','value head'
$done  = 'CONVERGED','OPTIMAL','coherent','high-confidence','accepted','committed'

Write-Host "neural-core v5 :: loading weights ..." -ForegroundColor DarkCyan
Write-Host "[ok] 175B params mapped | ctx=128k | dtype=bf16" -ForegroundColor DarkGray
Start-Sleep -Milliseconds 500

$loss = Get-Random -Min 3.0 -Max 5.0
$step = Get-Random -Min 1000 -Max 90000

while ($true) {
    $step++
    $roll = Get-Random -Max 100
    if ($roll -lt 30) {
        $line = "  [think] {0} ... {1}" -f (Get-Random $think), (Get-Random $done)
        $c = 'Cyan'
    } elseif ($roll -lt 50) {
        $line = "  matmul {0} x {1} -> {2}   {3:N2} GFLOP" -f (Dim), (Dim), (Dim), (Get-Random -Min 1.0 -Max 90.0)
        $c = 'DarkCyan'
    } elseif ($roll -lt 68) {
        $loss = [math]::Max(0.012, $loss - (Get-Random -Min 0.0 -Max 0.02))
        $line = "  step {0}  loss={1:N4}  lr={2:e2}  |grad|={3}" -f $step, $loss, (Get-Random -Min 0.0001 -Max 0.01), (F)
        $c = 'Green'
    } elseif ($roll -lt 80) {
        $line = "  layer[{0}/48] {1,-11} act={2}" -f (Get-Random -Max 48), (Get-Random $layers), (Vec 6)
        $c = 'DarkGray'
    } elseif ($roll -lt 92) {
        $line = "  attend {0} -> conf {1:P0}  temp={2:N2}" -f (Get-Random $topics), (Get-Random -Min 0.6 -Max 1.0), (Get-Random -Min 0.1 -Max 1.2)
        $c = 'Magenta'
    } else {
        $line = "  >> emit token #{0}  '{1}'" -f (Get-Random -Max 50000), (Get-Random $topics)
        $c = 'White'
    }
    Write-Host $line -ForegroundColor $c
    Start-Sleep -Milliseconds (Get-Random -Min 20 -Max 140)
}
