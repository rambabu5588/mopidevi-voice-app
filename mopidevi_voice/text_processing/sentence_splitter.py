import re
from typing import List
from mopidevi_voice.text_processing.normalize_telugu import normalize_telugu

def split_sentences(text: str) -> List[str]:
    cleaned = normalize_telugu(text)
    if not cleaned:
        return []
    
    # Split by periods, exclamations, question marks, newlines, or Telugu pipe marks while retaining punctuation clues
    raw_sentences = re.split(r'(?<=[.!?|\n])\s+', cleaned)
    sentences = []
    for s in raw_sentences:
        s = s.strip()
        if s:
            sentences.append(s)
    return sentences if sentences else [cleaned]
