import wave
import math
import struct
import os

os.makedirs('assets/audio', exist_ok=True)

def generate_tone(filename, freq, duration, pulse=False, dual=False):
    sample_rate = 44100.0
    obj = wave.open(filename, 'w')
    obj.setnchannels(1) # mono
    obj.setsampwidth(2)
    obj.setframerate(sample_rate)

    for i in range(int(sample_rate * duration)):
        t = float(i) / sample_rate
        # Create tone
        if dual:
            value = int(32767.0 * 0.5 * (math.sin(2.0 * math.pi * freq * t) + math.sin(2.0 * math.pi * (freq * 1.25) * t)))
        else:
            value = int(32767.0 * math.sin(2.0 * math.pi * freq * t))
        
        # Apply pulsing envelope if required
        if pulse:
            envelope = (math.sin(2.0 * math.pi * 5 * t) > 0)
            value = int(value * envelope)
            
        data = struct.pack('<h', value)
        obj.writeframesraw(data)
    
    obj.close()

# 1. Classic (Dual tone pulsing)
generate_tone('assets/audio/classic.wav', 880.0, 3.0, pulse=True, dual=True)

# 2. Digital (High pitch fast pulse)
generate_tone('assets/audio/digital.wav', 1200.0, 3.0, pulse=True, dual=False)

# 3. Crystal (Soft single tone, non-pulsing)
generate_tone('assets/audio/crystal.wav', 600.0, 3.0, pulse=False, dual=False)

print("Generated classic.wav, digital.wav, and crystal.wav")
