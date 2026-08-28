import os
import json
from typing import Dict

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

class TemplePronunciationEngine:
    """Mopidevi Temple Pronunciation Engine loading JSON dictionaries."""
    
    def __init__(self):
        self.dictionary: Dict[str, str] = {}
        self.load_dictionaries()
        
    def load_dictionaries(self):
        json_files = [
            "temple_words.json",
            "deity_names.json",
            "place_names.json",
            "difficult_words.json",
            "numbers.json",
            "dates.json"
        ]
        for f_name in json_files:
            file_path = os.path.join(BASE_DIR, f_name)
            if os.path.exists(file_path):
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        data = json.load(f)
                        self.dictionary.update(data)
                except Exception as e:
                    print(f"[PronunciationEngine] Failed to load {f_name}: {e}")

    def apply_pronunciation(self, text: str) -> str:
        """Applies temple phonetic substitutions to sentence text."""
        if not text:
            return ""
            
        result = text
        # 1. Multi-word phrase replacements first
        for key, val in sorted(self.dictionary.items(), key=lambda x: len(x[0]), reverse=True):
            if " " in key and key in result:
                result = result.replace(key, val)
                
        # 2. Single-word replacements
        words = result.split()
        processed_words = []
        for word in words:
            clean_w = word.strip(".,!?|")
            punct = word[len(clean_w):]
            if clean_w in self.dictionary:
                processed_words.append(self.dictionary[clean_w] + punct)
            else:
                processed_words.append(word)
                
        return " ".join(processed_words)

# Singleton instance
pronunciation_engine = TemplePronunciationEngine()

def apply_pronunciation(text: str) -> str:
    return pronunciation_engine.apply_pronunciation(text)
