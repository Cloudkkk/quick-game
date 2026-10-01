"""Make this game's complete 30-second forward WAV loop native to Web Audio.

Godot 4.5.1 SampleNode normally restarts from its JS ended callback. That can
leave a scheduling gap. Set BufferSource.loop for this one whole-clip BGM.
Interaction samples remain unchanged. Fail closed if the template changes.
Run after every Web export, before packaging, with the exported index.js path.
"""
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
marker = '/*estate-whole-wav-loop*/'
needle = 'this._source.buffer=this.getSample().getAudioBuffer();'
patch = marker + 'if(this.getSample().loopMode==="forward"&&Math.abs(this._source.buffer.duration-30)<0.001){this._source.loop=true;this._source.loopStart=0;this._source.loopEnd=this._source.buffer.duration;}'
if marker in source:
    assert source.count(marker) == 2, 'Unexpected partially patched template'
else:
    assert source.count(needle) == 2, 'Godot 4.5.1 SampleNode template changed'
    source = source.replace(needle, needle + patch)
    path.write_text(source)
print('WEB_NATIVE_WAV_LOOP_PATCH_OK', path)
