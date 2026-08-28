import unittest
import os
import asyncio
from pydub import AudioSegment

from backend.text_processing.telugu_normalizer import normalize_telugu_text, segment_sentences
from backend.text_processing.pronunciation_dict import apply_pronunciation_rules
from backend.speech_director.director import SpeechDirector, STYLE_PRESETS
from backend.audio_validation.validator import AudioValidator
from backend.sound_effects.fx_mixer import TempleEffectsGenerator, TempleEffectsMixer
from backend.mastering.masterer import AudioMasterer

class TestMopideviPipeline(unittest.TestCase):

    def test_telugu_text_normalization(self):
        raw_text = "మోపిదేవి క్షేత్రంలో 100 మంది భక్తులకు హారతి."
        normalized = normalize_telugu_text(raw_text)
        self.assertIn("వంద", normalized)

    def test_sentence_segmentation(self):
        text = "స్వాగతం. దర్శనం ప్రారంభమైంది! దయచేసి వరుసలో రండి."
        sentences = segment_sentences(text)
        self.assertEqual(len(sentences), 3)
        self.assertIn("స్వాగతం.", sentences[0])

    def test_pronunciation_dictionary(self):
        sentence = "మోపిదేవి క్షేత్రంలో సుబ్రహ్మణ్యేశ్వర అర్చన"
        processed = apply_pronunciation_rules(sentence)
        self.assertIn("మోపిదేవి", processed)
        self.assertIn("సుబ్రహ్మణ్యేశ్వర", processed)

    def test_speech_director_presets(self):
        director = SpeechDirector("Devotional")
        prosody = director.get_prosody_for_sentence(0, 3)
        self.assertEqual(prosody["style_name"], "Devotional")
        self.assertLess(prosody["speed"], 1.0)
        self.assertTrue(prosody["pre_pause_ms"] > 0)

    def test_temple_fx_generation(self):
        bell = TempleEffectsGenerator.generate_temple_bell(duration_sec=1.0)
        self.assertIsInstance(bell, AudioSegment)
        self.assertGreater(len(bell), 500)

        conch = TempleEffectsGenerator.generate_conch_blast(duration_sec=1.0)
        self.assertIsInstance(conch, AudioSegment)
        self.assertGreater(len(conch), 500)

        ambience = TempleEffectsGenerator.generate_temple_ambience(duration_sec=2.0)
        self.assertIsInstance(ambience, AudioSegment)
        self.assertGreater(len(ambience), 1000)

    def test_audio_mastering(self):
        speech = AudioSegment.silent(duration=1000)
        bell = TempleEffectsGenerator.generate_temple_bell(duration_sec=1.0)
        mix = speech.overlay(bell, position=0)
        
        test_wav = os.path.join(os.path.dirname(__file__), "test_output.wav")
        test_mp3 = os.path.join(os.path.dirname(__file__), "test_output.mp3")
        
        success = AudioMasterer.master_audio(mix, test_wav, test_mp3)
        self.assertTrue(success)
        self.assertTrue(os.path.exists(test_wav))
        
        # Cleanup
        if os.path.exists(test_wav):
            os.remove(test_wav)
        if os.path.exists(test_mp3):
            os.remove(test_mp3)

if __name__ == '__main__':
    unittest.main()
