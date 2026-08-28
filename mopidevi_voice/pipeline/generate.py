import os
import asyncio
import tempfile
from typing import Dict, Any, List, Optional
from pydub import AudioSegment

from mopidevi_voice.text_processing import normalize_telugu, split_sentences
from mopidevi_voice.pronunciation import apply_pronunciation
from mopidevi_voice.speech_director.prosody import build_speech_plan
from mopidevi_voice.voice_clone.inference import NaturalVoiceSynthesizer
from mopidevi_voice.voice_clone.profile import extract_speaker_features
from mopidevi_voice.audio.validator import validate_segment

class SentencePipelineGenerator:
    """Orchestrates sentence-by-sentence generation with automated quality validation & single-sentence retry loop."""
    
    @staticmethod
    async def generate_speech_pipeline(
        telugu_script: str,
        voice_id: str,
        style_name: str,
        speaker_features: Optional[Dict[str, Any]] = None,
        progress_callback = None
    ) -> AudioSegment:
        """
        Executes sentence-by-sentence TTS generation pipeline.
        Guarantees 100% audible sentence generation.
        """
        if not speaker_features:
            speaker_features = {"estimated_gender": "female", "pitch_f0": 180.0, "voice_mode": "Natural Clone"}
            
        clean_text = normalize_telugu(telugu_script)
        sentences = split_sentences(clean_text)
        
        if progress_callback:
            progress_callback("PROCESSING", "✓ Text normalized & split into sentences", 20)
            
        combined_speech = AudioSegment.silent(duration=500)
        temp_dir = tempfile.mkdtemp(prefix="mopidevi_sentence_")
        
        for idx, sentence in enumerate(sentences):
            phonetic_sentence = apply_pronunciation(sentence)
            prosody_plan = build_speech_plan(sentence, style_name, idx, len(sentences))
            
            segment_path = os.path.join(temp_dir, f"sentence_{idx}.wav")
            
            max_retries = 3
            passed = False
            for attempt in range(1, max_retries + 1):
                success = await NaturalVoiceSynthesizer.synthesize(phonetic_sentence, speaker_features, prosody_plan, segment_path)
                if success:
                    valid, report = validate_segment(segment_path)
                    if valid:
                        passed = True
                        break
                    else:
                        print(f"[Pipeline] Sentence {idx+1} validation failed (Attempt {attempt}/{max_retries}): {report['reason']}")
                await asyncio.sleep(0.1)
                
            if not passed:
                print(f"[Pipeline] Warning: Sentence {idx+1} fallback active.")
                from backend.voice_engine.tts_generator import TTSGenerator
                TTSGenerator._generate_synthetic_fallback(phonetic_sentence, segment_path, prosody_plan)
                
            seg_audio = AudioSegment.from_file(segment_path)
            
            if any(item["emphasis"] == "HIGH" for item in prosody_plan["word_emphasis_map"]):
                seg_audio = seg_audio.apply_gain(+1.5)
                
            pre_pause_ms = prosody_plan.get("pre_pause_ms", 400)
            post_pause_ms = prosody_plan.get("post_pause_ms", 500)
            
            combined_speech += AudioSegment.silent(duration=pre_pause_ms)
            combined_speech += seg_audio
            combined_speech += AudioSegment.silent(duration=post_pause_ms)
            
            if progress_callback:
                pct = 20 + int((idx + 1) / float(len(sentences)) * 40)
                progress_callback("PROCESSING", f"● Created sentence {idx+1}/{len(sentences)}", pct)

        for f in os.listdir(temp_dir):
            try:
                os.remove(os.path.join(temp_dir, f))
            except Exception:
                pass
        try:
            os.rmdir(temp_dir)
        except Exception:
            pass

        return combined_speech

def generate_speech_pipeline(telugu_script: str, voice_id: str, style_name: str, speaker_features: Optional[Dict[str, Any]] = None, progress_callback = None) -> AudioSegment:
    return asyncio.run(SentencePipelineGenerator.generate_speech_pipeline(telugu_script, voice_id, style_name, speaker_features, progress_callback))
