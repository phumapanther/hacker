param([switch]$Test)
# listen.ps1 - offline wake-word listener for CARAO. Says "เฮ้คอส" -> fires WakeAction.
# Only en-US recognizer exists on this PC, so we match phonetic look-alikes of "เฮ้คอส".
# ponytail: en-US phonetic grammar, no Thai model. Upgrade path = install Vosk/Whisper th for real Thai ASR.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech

# --- what to do when the wake word is heard (edit this one line) ---
$WakeAction = {
    [console]::Beep(880, 150); [console]::Beep(1320, 200)
    Write-Host ("[{0}] CARAO woke up" -f (Get-Date -Format HH:mm:ss)) -ForegroundColor Cyan
    $morning = 'C:\Users\watch\morning\morning.ps1'
    if (Test-Path $morning) { & $morning }   # ponytail: reuse existing CARAO entry point
}

# phonetic variants an en-US engine can catch for "เฮ้คอส" (Hey CARAO)
$WakePhrases = 'hey carao','carao','hey karao','karao','hey car ao','carrao','hey kalao','kalao'
$MinConfidence = 0.55   # calibration knob: raise if it triggers on noise, lower if it misses you

$choices = New-Object System.Speech.Recognition.Choices
$WakePhrases | ForEach-Object { $choices.Add($_) }
$gb = New-Object System.Speech.Recognition.GrammarBuilder
$gb.Culture = (New-Object System.Globalization.CultureInfo 'en-US')
$gb.Append($choices)
$grammar = New-Object System.Speech.Recognition.Grammar $gb

$rec = New-Object System.Speech.Recognition.SpeechRecognitionEngine ((New-Object System.Globalization.CultureInfo 'en-US'))
$rec.LoadGrammar($grammar)

if ($Test) {
    # mic-less self-check: feed a phrase through the grammar, assert the wake path fires
    $script:hit = $null
    $rec.add_SpeechRecognized({ param($s,$e) if ($e.Result.Confidence -ge $MinConfidence) { $script:hit = $e.Result.Text } })
    [void]$rec.EmulateRecognize('hey carao')
    if ($script:hit) { "TEST OK - matched '$script:hit'"; exit 0 } else { "TEST FAIL - grammar did not match"; exit 1 }
}

$rec.add_SpeechRecognized({
    param($s, $e)
    if ($e.Result.Confidence -ge $MinConfidence) {
        Write-Host ("heard: '{0}' ({1:P0})" -f $e.Result.Text, $e.Result.Confidence) -ForegroundColor DarkGray
        & $WakeAction
    }
})

try { $rec.SetInputToDefaultAudioDevice() }
catch { Write-Host "No microphone found. Plug one in and rerun." -ForegroundColor Red; exit 1 }

Write-Host "CARAO is listening for 'เฮ้คอส' ... (Ctrl+C to stop)" -ForegroundColor Green
$rec.RecognizeAsync([System.Speech.Recognition.RecognizeMode]::Multiple)
while ($true) { Start-Sleep -Seconds 1 }
