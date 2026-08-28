import os
import asyncio
from typing import Dict, Any, Optional
import edge_tts
from pydub import AudioSegment

class NaturalVoiceSynthesizer:
    """Synthesizes Natural Voice Clone by matching base speech to user extracted speaker profile."""
    
    @staticmethod
    async def synthesize(
        sentence: str,
        speaker_features: Dict[str, Any],
        prosody_plan: Dict[str, Any],
        output_path: str
    ) -> bool:
        """
        Synthesizes sentence audio tuned to natural voice profile pitch and speed parameters.
        """
        try:
            gender = speaker_features.get("estimated_gender", "female")
            base_voice = "te-IN-ShrutiNeural" if gender == "female" else "te-IN-MohanNeural"
            
            # Check for Deep Neural Speaker Embedding (512-dim)
            from mopidevi_voice.voice_clone.deep_clone import get_neural_speaker_embedding
            voice_id = speaker_features.get("voice_id", "")
            neural_emb = get_neural_speaker_embedding(voice_id) if voice_id else None

            if neural_emb:
                # Apply deep neural pitch shift tuning
                p_shift = neural_emb.get("pitch_shift_semitones", 0)
                if p_shift != 0:
                    pitch_str = f"{p_shift:+d}Hz"

            communicate = edge_tts.Communicate(sentence, base_voice, rate=rate_str, pitch=pitch_str)
            await communicate.save(output_path)
            
            if os.path.exists(output_path) and os.path.getsize(output_path) > 500:
                pitch_f0 = speaker_features.get("pitch_f0", 160.0)
                sound = AudioSegment.from_file(output_path)
                if neural_emb and "spectral_centroid_hz" in neural_emb:
                    # Adjust gain based on neural spectral centroid
                    vol_boost = +2.0 if neural_emb["spectral_centroid_hz"] > 700 else +1.0
                    sound = sound.apply_gain(vol_boost)
                elif pitch_f0 < 130.0 and gender == "male":
                    sound = sound.apply_gain(+1.5)
                sound.export(output_path, format="wav")
                return True
                
        except Exception as e:
            print(f"[NaturalVoiceSynthesizer] Synthesis error: {e}")
            
        return False

def synthesize_natural_voice(sentence: str, speaker_features: Dict[str, Any], prosody_plan: Dict[str, Any], output_path: str) -> bool:
    try:
        loop = asyncio.get_running_loop()
        if loop.is_running():
            return loop.run_until_complete(NaturalVoiceSynthesizer.synthesize(sentence, speaker_features, prosody_plan, output_path))
    except RuntimeError:
        pass
    return asyncio.run(NaturalVoiceSynthesizer.synthesize(sentence, speaker_features, prosody_plan, output_path))
