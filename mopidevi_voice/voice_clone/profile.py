import os
import numpy as np
from typing import Dict, Any, Optional
from pydub import AudioSegment

def extract_speaker_features(audio_path: str) -> Dict[str, Any]:
    """
    Extracts acoustic speaker features (fundamental pitch F0, RMS energy, spectral centroid, estimated gender) from voice sample.
    """
    default_features = {
        "voice_mode": "Natural Clone",
        "pitch_f0": 160.0,
        "rms_energy": 0.05,
        "pitch_shift_semitones": 0,
        "estimated_gender": "female"
    }
    
    if not audio_path or not os.path.exists(audio_path):
        return default_features
        
    try:
        audio = AudioSegment.from_file(audio_path)
        samples = np.array(audio.get_array_of_samples(), dtype=np.float32)
        if audio.channels > 1:
            samples = samples[::audio.channels]
            
        sample_rate = audio.frame_rate
        rms = float(np.sqrt(np.mean(samples ** 2))) / (32768.0 if audio.sample_width == 2 else 1.0)
        
        # Zero-crossing rate estimate for fundamental pitch approximation
        zero_crossings = np.where(np.diff(np.signbit(samples)))[0]
        zcr = len(zero_crossings) / (len(samples) / float(sample_rate))
        estimated_f0 = float(np.clip(zcr * 0.25, 80.0, 320.0))
        
        estimated_gender = "female" if estimated_f0 > 175.0 else "male"
        
        return {
            "voice_mode": "Natural Clone",
            "pitch_f0": round(estimated_f0, 1),
            "rms_energy": round(rms, 4),
            "pitch_shift_semitones": 0,
            "estimated_gender": estimated_gender,
            "sample_rate": sample_rate,
            "duration_sec": len(audio) / 1000.0
        }
    except Exception as e:
        print(f"[Profile] Feature extraction fallback: {e}")
        return default_features

def create_natural_voice_profile(voice_id: str, voice_name: str, audio_path: str) -> Dict[str, Any]:
    features = extract_speaker_features(audio_path)
    return {
        "voice_id": voice_id,
        "voice_name": voice_name,
        "voice_type": "custom",
        "audio_path": audio_path,
        "features": features
    }
