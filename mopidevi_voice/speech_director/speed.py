from typing import Dict, Any
from mopidevi_voice.speech_director.emotion import get_emotion_profile

def get_speed_setting(style_name: str) -> float:
    profile = get_emotion_profile(style_name)
    return profile["speed"]
