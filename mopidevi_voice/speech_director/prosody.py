from typing import Dict, Any, List
from mopidevi_voice.speech_director.emotion import get_emotion_profile
from mopidevi_voice.speech_director.emphasis import detect_word_emphasis
from mopidevi_voice.speech_director.pauses import parse_text_pauses

def build_speech_plan(sentence: str, style_name: str, sentence_index: int, total_sentences: int) -> Dict[str, Any]:
    """
    Builds comprehensive prosody instructions for a sentence including emotion profile, deity word emphasis, and pause timings.
    """
    emotion = get_emotion_profile(style_name)
    words_emphasis = detect_word_emphasis(sentence)
    pauses_plan = parse_text_pauses(sentence)
    
    # Adjust pause timings for opening/closing sentences
    pre_pause = emotion["opening_pause_ms"]
    post_pause = emotion["closing_pause_ms"]
    if sentence_index == 0:
        pre_pause += 200
    if sentence_index == total_sentences - 1:
        post_pause += 300
        
    return {
        "sentence": sentence,
        "style_name": style_name,
        "speed": emotion["speed"],
        "pitch": emotion["pitch"],
        "rate_str": emotion["rate_str"],
        "volume_gain": emotion["volume_gain"],
        "pre_pause_ms": pre_pause,
        "post_pause_ms": post_pause,
        "word_emphasis_map": words_emphasis,
        "pauses_structure": pauses_plan
    }
