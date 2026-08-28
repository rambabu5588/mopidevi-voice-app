import os
import json
from typing import Dict, Any, Optional
from mopidevi_voice.voice_clone.profile import create_natural_voice_profile

class VoiceModelManager:
    """Manages Natural Voice Clone profiles and persistence."""
    
    @staticmethod
    def register_natural_voice(voice_id: str, voice_name: str, audio_sample_path: str) -> Dict[str, Any]:
        profile = create_natural_voice_profile(voice_id, voice_name, audio_sample_path)
        return profile
