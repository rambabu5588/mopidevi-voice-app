import os
from pydub import AudioSegment
from mopidevi_voice.audio.normalize import normalize_loudness

class SpeechMasterer:
    """Performs final mastering for speech audio: loudness normalization (-14 dBFS), peak limiting, WAV and MP3 export."""
    
    @staticmethod
    def master_speech(
        speech_audio: AudioSegment,
        output_wav_path: str,
        output_mp3_path: str,
        target_dBFS: float = -14.0
    ) -> bool:
        """
        Mastering pipeline: loudness normalization -> peak limiter (-0.5 dBFS) -> clean WAV and MP3 export.
        """
        try:
            # 1. Loudness Normalization
            mastered = normalize_loudness(speech_audio, target_dBFS)
            
            # 2. Peak Limiter (-0.5 dBFS ceiling)
            if mastered.max_dBFS > -0.5:
                reduction = mastered.max_dBFS + 0.5
                mastered = mastered.apply_gain(-reduction)
                
            # 3. Export WAV and MP3
            abs_wav = os.path.abspath(output_wav_path)
            abs_mp3 = os.path.abspath(output_mp3_path)
            
            os.makedirs(os.path.dirname(abs_wav), exist_ok=True)
            os.makedirs(os.path.dirname(abs_mp3), exist_ok=True)
            
            mastered.export(abs_wav, format="wav")
            
            try:
                mastered.export(abs_mp3, format="mp3", bitrate="192k")
            except Exception as e:
                print(f"[SpeechMasterer] MP3 export fallback: {e}")
                mastered.export(abs_mp3, format="wav")
                
            return os.path.exists(abs_wav) and os.path.getsize(abs_wav) > 0
            
        except Exception as e:
            print(f"[SpeechMasterer] Mastering error: {e}")
            return False

def master_speech_audio(speech_audio: AudioSegment, output_wav_path: str, output_mp3_path: str, target_dBFS: float = -14.0) -> bool:
    return SpeechMasterer.master_speech(speech_audio, output_wav_path, output_mp3_path, target_dBFS)
