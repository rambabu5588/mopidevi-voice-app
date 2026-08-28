import os
import json
import uuid
import time
from typing import List, Dict, Any
from mopidevi_voice.voice_clone.profile import extract_speaker_features
import backend.database as db

KNOWN_DIFFICULT_TERMS = [
    "సహస్రనామార్చన", "తీర్థప్రసాదాలు", "కళ్యాణోత్సవం", "బ్రహ్మోత్సవాలు",
    "సర్పదోష", "నివారణ", "మహాత్మ్యం", "వల్లీ", "దేవసేన", "అభిషేకం"
]

class AdaptiveVoiceTrainer:
    """Detects difficult Telugu words and trains/refines custom voice model profiles from user audio snippets."""

    @staticmethod
    def detect_difficult_words(sentence: str) -> List[str]:
        words = sentence.split()
        difficult_found = []
        for word in words:
            clean = word.strip(".,!?|")
            if clean in KNOWN_DIFFICULT_TERMS or len(clean) > 12:
                if clean not in difficult_found:
                    difficult_found.append(clean)
        return difficult_found

    @staticmethod
    def train_word_sample(req_id: str, voice_id: str, word_text: str, audio_sample_path: str) -> Dict[str, Any]:
        sample_id = f"SMPL-{uuid.uuid4().hex[:6].upper()}"
        features = extract_speaker_features(audio_sample_path)
        
        db.save_word_training_sample(
            sample_id=sample_id,
            req_id=req_id,
            voice_id=voice_id,
            word_text=word_text,
            audio_path=audio_sample_path,
            acoustic_features=features
        )
        
        dict_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "pronunciation", "difficult_words.json")
        if os.path.exists(dict_path):
            try:
                with open(dict_path, "r", encoding="utf-8") as f:
                    dict_data = json.load(f)
                dict_data[word_text] = word_text
                with open(dict_path, "w", encoding="utf-8") as f:
                    json.dump(dict_data, f, ensure_ascii=False, indent=2)
            except Exception as e:
                print(f"[Trainer] Dictionary update notice: {e}")
                
        return {
            "sample_id": sample_id,
            "voice_id": voice_id,
            "word_text": word_text,
            "status": "TRAINED",
            "extracted_features": features
        }

    @staticmethod
    def generate_tasks_from_database_script(script_id: str, user_id: str, voice_id: str) -> List[Dict[str, Any]]:
        """
        Reads training script from database table `training_script_database`, identifies target words,
        and generates training requests in database.
        """
        script = db.get_training_script_by_id(script_id)
        if not script:
            return []
            
        script_text = script["script_text"]
        target_words = AdaptiveVoiceTrainer.detect_difficult_words(script_text)
        
        # If no explicit difficult word matched, use first multi-word phrase
        if not target_words:
            words = [w.strip(".,!?|") for w in script_text.split() if len(w.strip(".,!?|")) > 3]
            target_words = words[:2] if words else [script_text[:15]]
            
        created_requests = []
        for word in target_words:
            req_id = f"TR-{uuid.uuid4().hex[:6].upper()}"
            req = db.create_training_request(
                req_id=req_id,
                job_id=script_id,
                user_id=user_id,
                voice_id=voice_id,
                word_text=word,
                sentence_text=script_text
            )
            created_requests.append(req)
            
        return created_requests

def detect_difficult_words(sentence: str) -> List[str]:
    return AdaptiveVoiceTrainer.detect_difficult_words(sentence)

def train_word_sample(req_id: str, voice_id: str, word_text: str, audio_sample_path: str) -> Dict[str, Any]:
    return AdaptiveVoiceTrainer.train_word_sample(req_id, voice_id, word_text, audio_sample_path)

def generate_tasks_from_database_script(script_id: str, user_id: str, voice_id: str) -> List[Dict[str, Any]]:
    return AdaptiveVoiceTrainer.generate_tasks_from_database_script(script_id, user_id, voice_id)
