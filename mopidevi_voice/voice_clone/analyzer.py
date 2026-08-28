import os
import numpy as np
from typing import Dict, Any
from pydub import AudioSegment
from mopidevi_voice.voice_clone.profile import extract_speaker_features

class VoiceAnalyzer:
    """Performs acoustic voice quality analysis and verification before profile upload."""
    
    @staticmethod
    def analyze_voice_sample(audio_path: str) -> Dict[str, Any]:
        """
        Analyzes audio sample for RMS volume, background noise level, SNR, speech duration, pitch, and verification status.
        """
        if not audio_path or not os.path.exists(audio_path):
            return {
                "verification_status": "NEEDS_RERECORDING",
                "quality_badge": "🔴 Poor",
                "reason": "Audio file missing or empty"
            }
            
        try:
            audio = AudioSegment.from_file(audio_path)
            duration_sec = len(audio) / 1000.0
            
            features = extract_speaker_features(audio_path)
            rms = features.get("rms_energy", 0.0)
            
            # Estimate noise floor from quietest 10% frames
            samples = np.array(audio.get_array_of_samples(), dtype=np.float32)
            frame_size = int(audio.frame_rate * 0.05) # 50ms frames
            frame_energies = []
            for idx in range(0, len(samples) - frame_size, frame_size):
                frame = samples[idx:idx+frame_size]
                e = float(np.sqrt(np.mean(frame ** 2))) / 32768.0
                frame_energies.append(e)
                
            if frame_energies:
                frame_energies.sort()
                noise_floor = max(0.0001, np.mean(frame_energies[:max(1, len(frame_energies)//10)]))
            else:
                noise_floor = 0.005
                
            snr_db = round(10.0 * np.log10((rms ** 2) / (noise_floor ** 2)), 1)
            
            # Verification Logic
            if duration_sec < 1.5:
                quality_badge = "🔴 Poor"
                status = "NEEDS_RERECORDING"
                reason = f"త్రక్కువ నిడివి ({duration_sec:.1f}s < 1.5s). దయచేసి మరింత మాట్లాడండి."
            elif rms < 0.008:
                quality_badge = "🔴 Poor"
                status = "NEEDS_RERECORDING"
                reason = "అతి తక్కువ శబ్దం. మైక్రోఫోన్‌కు దగ్గరగా మాట్లాడండి."
            elif snr_db < 10.0:
                quality_badge = "🟡 Acceptable"
                status = "VERIFIED"
                reason = "నేపథ్య శబ్దం ఎక్కువ (High background noise). ప్రశాంత వాతావరణం సిఫార్సు చేయబడింది."
            else:
                quality_badge = "🟢 Good"
                status = "VERIFIED"
                reason = "ఉత్తమ రికార్డింగ్ నాణ్యత (Excellent audio quality)."
                
            return {
                "verification_status": status,
                "quality_badge": quality_badge,
                "reason": reason,
                "duration_sec": round(duration_sec, 2),
                "rms_energy": round(rms, 4),
                "snr_db": snr_db,
                "pitch_f0": features.get("pitch_f0", 160.0),
                "estimated_gender": features.get("estimated_gender", "female")
            }
            
        except Exception as e:
            return {
                "verification_status": "NEEDS_RERECORDING",
                "quality_badge": "🔴 Poor",
                "reason": f"విశ్లేషణ లోపం: {str(e)}"
            }

def analyze_voice_sample(audio_path: str) -> Dict[str, Any]:
    return VoiceAnalyzer.analyze_voice_sample(audio_path)
