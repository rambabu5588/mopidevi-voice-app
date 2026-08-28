from typing import List, Dict, Any

DEITY_EMPHASIS_TERMS = [
    "సుబ్రహ్మణ్య", "సుబ్రహ్మణ్యేశ్వర", "నాగేంద్రస్వామి", "వల్లీ", "దేవసేన",
    "మోపిదేవి", "క్షేత్రం", "అభిషేకం", "సర్పదోష", "రాహుకేతు", "కళ్యాణం"
]

def detect_word_emphasis(sentence: str) -> List[Dict[str, Any]]:
    """
    Identifies sacred deity names and temple terms requiring emphasis in speech delivery.
    """
    words = sentence.split()
    annotated = []
    for word in words:
        clean = word.strip(".,!?|")
        is_emphasized = any(term in clean for term in DEITY_EMPHASIS_TERMS)
        annotated.append({
            "word": word,
            "emphasis": "HIGH" if is_emphasized else "NORMAL",
            "volume_boost_dB": 1.5 if is_emphasized else 0.0
        })
    return annotated
