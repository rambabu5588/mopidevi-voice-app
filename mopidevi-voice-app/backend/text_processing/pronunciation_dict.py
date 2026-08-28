from typing import Dict

# Mopidevi Temple Phonetic & Pronunciation Dictionary
MOPIDEVI_PRONUNCIATION_MAP: Dict[str, str] = {
    "మోపిదేవి": "మోపిదేవి",
    "సుబ్రహ్మణ్య": "సుబ్రహ్మణ్య",
    "సుబ్రహ్మణ్యేశ్వర": "సుబ్రహ్మణ్యేశ్వర",
    "క్షేత్రం": "క్షేత్రం",
    "క్షేత్రానికి": "క్షేత్రానికి",
    "అభిషేకం": "అభిషేకం",
    "అర్చన": "అర్చన",
    "ప్రసాదం": "ప్రసాదం",
    "సర్పదోష": "సర్పదోష",
    "నాగేంద్రస్వామి": "నాగేంద్రస్వామి",
    "దర్శనం": "దర్శనం",
    "భక్తులందరికీ": "భక్తులందరికీ",
    "హారతి": "హారతి",
    "కళ్యాణం": "కళ్యాణం",
    "తీర్థప్రసాదాలు": "తీర్థ ప్రసాదాలు"
}

def apply_pronunciation_rules(sentence: str) -> str:
    """Replaces words in sentence with standardized phonetic variations if specified."""
    words = sentence.split()
    processed_words = []
    for w in words:
        # Strip trailing punctuation for dictionary match
        clean_word = w.strip(".,!?|")
        punct = w[len(clean_word):]
        if clean_word in MOPIDEVI_PRONUNCIATION_MAP:
            processed_words.append(MOPIDEVI_PRONUNCIATION_MAP[clean_word] + punct)
        else:
            processed_words.append(w)
    return " ".join(processed_words)
