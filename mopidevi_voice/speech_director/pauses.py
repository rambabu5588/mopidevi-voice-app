import re
from typing import List, Dict, Any

PAUSE_RULES = {
    "...": 700,    # Ellipsis -> 700ms solemn devotional breath pause
    ",": 400,      # Clause comma -> 400ms pause
    ";": 500,      # Semicolon -> 500ms pause
    ".": 600,      # Sentence period -> 600ms pause
    "!": 500,      # Exclamation -> 500ms pause
    "?": 600,      # Question -> 600ms pause
    "\n": 800      # Newline -> 800ms full pause
}

class PauseParser:
    """Parses Telugu text and injects explicit breathing pause timings in milliseconds."""

    @staticmethod
    def parse_pauses(text: str) -> List[Dict[str, Any]]:
        """
        Breaks text into segments with explicit pause duration annotations.
        Example:
        'మోపిదేవి క్షేత్రానికి విచ్చేసిన భక్తులందరికీ... శ్రీ సుబ్రహ్మణ్య స్వామి వారి'
        Output:
        [
          {'type': 'text', 'content': 'మోపిదేవి క్షేత్రానికి విచ్చేసిన భక్తులందరికీ'},
          {'type': 'pause', 'duration_ms': 700},
          {'type': 'text', 'content': 'శ్రీ సుబ్రహ్మణ్య స్వామి వారి'}
        ]
        """
        segments = []
        pattern = r'(\.\.\.|[,\.\!\?\;\n])'
        parts = re.split(pattern, text)
        
        i = 0
        while i < len(parts):
            token = parts[i].strip()
            if not token:
                i += 1
                continue
                
            if token in PAUSE_RULES:
                duration = PAUSE_RULES[token]
                segments.append({"type": "pause", "duration_ms": duration, "symbol": token})
            else:
                segments.append({"type": "text", "content": token})
            i += 1
            
        return segments

def parse_text_pauses(text: str) -> List[Dict[str, Any]]:
    return PauseParser.parse_pauses(text)
