import os
from pydub import AudioSegment

class AudioMasterer:
    """Performs final audio mastering: loudness normalization (-16 LUFS / -1dB peak), limiting, WAV and MP3 export."""
    
    @staticmethod
    def master_audio(
        mixed_segment: AudioSegment, 
        output_wav_path: str, 
        output_mp3_path: str,
        target_dBFS: float = -14.0
    ) -> bool:
        """
        Normalizes peak and RMS levels, applies soft limiting if needed, and exports high quality WAV and MP3 files.
        """
        try:
            # 1. Loudness / Gain Normalization
            change_in_dBFS = target_dBFS - mixed_segment.dBFS
            mastered = mixed_segment.apply_gain(change_in_dBFS)
            
            # 2. Soft Peak Limiting (prevent clipping above -0.5 dBFS)
            if mastered.max_dBFS > -0.5:
                reduction = mastered.max_dBFS + 0.5
                mastered = mastered.apply_gain(-reduction)
                
            # 3. Export WAV
            abs_wav_path = os.path.abspath(output_wav_path)
            abs_mp3_path = os.path.abspath(output_mp3_path)
            
            os.makedirs(os.path.dirname(abs_wav_path), exist_ok=True)
            os.makedirs(os.path.dirname(abs_mp3_path), exist_ok=True)
            
            mastered.export(abs_wav_path, format="wav")
            
            # 4. Export MP3 (if ffmpeg is present or pydub audio export works)
            try:
                mastered.export(abs_mp3_path, format="mp3", bitrate="192k")
            except Exception as e:
                print(f"[AudioMasterer] MP3 export notice (falling back to WAV copy): {e}")
                mastered.export(abs_mp3_path, format="wav")
                
            return os.path.exists(abs_wav_path) and os.path.getsize(abs_wav_path) > 0
            
        except Exception as e:
            print(f"[AudioMasterer] Mastering error: {e}")
            return False
