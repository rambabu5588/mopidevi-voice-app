from pydub import AudioSegment

def normalize_loudness(audio: AudioSegment, target_dBFS: float = -14.0) -> AudioSegment:
    """
    Normalizes RMS audio volume level to target_dBFS (-14 dBFS standard for clear temple playback).
    """
    if audio.dBFS == float("-inf") or len(audio) == 0:
        return audio
        
    change_in_dBFS = target_dBFS - audio.dBFS
    normalized = audio.apply_gain(change_in_dBFS)
    return normalized
