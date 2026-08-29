# voice.py - Thai voice assistant for CARAO/Claude.
#   say "เฮ้คลอด <command>"  ->  Whisper (Thai STT) -> claude -p -> Pattara TTS speaks the answer.
# Offline STT (faster-whisper), offline TTS (Windows th-TH Pattara). Ctrl+C to stop.
#   python voice.py            run the assistant
#   python voice.py --selftest test the parser (no mic/model needed)
#   python voice.py --calibrate live mic level, to tune THRESHOLD
import sys, subprocess, tempfile, os, time
os.environ.setdefault('KMP_DUPLICATE_LIB_OK', 'TRUE')  # avoid OpenMP double-init abort (ctranslate2 vs numpy)

WAKE_MARKERS = ('เฮ้คลอด', 'เฮคลอด', 'เฮ้ คลอด', 'คลอด', 'คลาวด', 'claude', 'hey claude')
MODEL   = 'base'      # 'base'=fast/ok Thai, 'small'=better+slower. first run downloads it.
SR      = 16000       # Whisper wants 16 kHz mono
THRESHOLD = 0.010     # ponytail: mic energy gate, hardware-specific. tune with --calibrate.
SILENCE_S = 0.9       # stop recording after this much trailing silence
MAX_S     = 15        # hard cap on one utterance

def parse_command(text):
    """(-> is_wake, command). command '' = wake word only, no command yet."""
    t = text.strip()
    low = t.lower()
    pos = min((low.find(m) for m in WAKE_MARKERS if m in low), default=-1)
    if pos < 0:
        return False, None
    m = next(m for m in WAKE_MARKERS if low.find(m) == pos)
    cmd = t[pos + len(m):]
    return True, cmd.lstrip(' ,.-!?ๆ')

def speak(text):
    """Speak Thai with Windows th-TH Pattara via PowerShell System.Speech."""
    f = tempfile.NamedTemporaryFile('w', suffix='.txt', delete=False, encoding='utf-8')
    f.write(text); f.close()
    ps = ("Add-Type -AssemblyName System.Speech;"
          "$s=New-Object System.Speech.Synthesis.SpeechSynthesizer;"
          "try{$s.SelectVoice('Microsoft Pattara')}catch{};"
          f"$s.Speak([IO.File]::ReadAllText('{f.name}',[Text.Encoding]::UTF8))")
    subprocess.run(['powershell', '-NoProfile', '-Command', ps])
    os.unlink(f.name)

def ask_claude(cmd):
    r = subprocess.run(['claude', '-p', cmd], capture_output=True, text=True, encoding='utf-8')
    return (r.stdout or r.stderr or '').strip()
    # ponytail: stateless per command. Upgrade path = persistent --session-id for multi-turn memory.

def record_utterance(sd, np):
    """Energy-gated recorder: wait for speech, capture until trailing silence / MAX_S."""
    block = int(SR * 0.1)
    buf, started, quiet, t0 = [], False, 0.0, time.time()
    with sd.InputStream(samplerate=SR, channels=1, dtype='float32', blocksize=block) as stream:
        while True:
            data, _ = stream.read(block)
            rms = float(np.sqrt(np.mean(data**2)))
            if rms >= THRESHOLD:
                started, quiet = True, 0.0
            elif started:
                quiet += 0.1
            if started:
                buf.append(data.copy())
            if started and quiet >= SILENCE_S:
                break
            if time.time() - t0 > MAX_S:
                break
    if not buf:
        return np.zeros(0, dtype='float32')
    return np.ascontiguousarray(np.concatenate(buf).flatten(), dtype='float32')  # contiguous = no ctranslate2 abort

def selftest():
    cases = [
        ('เฮ้คลอด เปิดเว็บให้หน่อย', (True, 'เปิดเว็บให้หน่อย')),
        ('hey claude what time is it', (True, 'what time is it')),
        ('เฮ้ คลอด', (True, '')),
        ('สวัสดีตอนเช้า', (False, None)),
    ]
    for text, want in cases:
        got = parse_command(text)
        assert got == want, f'{text!r} -> {got!r} != {want!r}'
    print('SELFTEST OK')

def main():
    from faster_whisper import WhisperModel
    import sounddevice as sd, numpy as np
    print('loading whisper model...', flush=True)
    model = WhisperModel(MODEL, device='cpu', compute_type='int8')
    print("CARAO listening. say 'เฮ้คลอด ...'  (Ctrl+C to stop)", flush=True)
    while True:
        audio = record_utterance(sd, np)
        if audio.size < SR // 2:      # < 0.5s, ignore blips
            continue
        segs, _ = model.transcribe(audio, language='th', vad_filter=True)
        text = ''.join(s.text for s in segs).strip()
        if not text:
            continue
        print('heard:', text, flush=True)
        is_wake, cmd = parse_command(text)
        if not is_wake:
            continue
        if not cmd:                    # wake word only -> capture the command next
            speak('ค่ะ')
            audio = record_utterance(sd, np)
            segs, _ = model.transcribe(audio, language='th', vad_filter=True)
            cmd = ''.join(s.text for s in segs).strip()
            if not cmd:
                continue
        print('command:', cmd, flush=True)
        answer = ask_claude(cmd)
        print('claude:', answer, flush=True)
        speak(answer)

if __name__ == '__main__':
    if '--selftest' in sys.argv:
        selftest()
    elif '--calibrate' in sys.argv:
        import sounddevice as sd, numpy as np
        print('speak normally; watch the number. set THRESHOLD a bit above your silence level. Ctrl+C to stop.')
        with sd.InputStream(samplerate=SR, channels=1, dtype='float32', blocksize=int(SR*0.1)) as st:
            while True:
                d, _ = st.read(int(SR*0.1))
                print(f'rms={float(np.sqrt(np.mean(d**2))):.4f}', end='\r', flush=True)
    else:
        main()
