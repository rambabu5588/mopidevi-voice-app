import os
import io
import numpy as np
import scipy.io.wavfile as wavfile
from typing import Dict, Any, List
from pydub import AudioSegment

class TempleEffectsGenerator:
    """Generates authentic temple audio effects dynamically (bell chime, shankam conch blast, temple ambience)."""
    
    @staticmethod
    def generate_temple_bell(duration_sec: float = 3.0, sample_rate: int = 44100) -> AudioSegment:
        """Synthesizes realistic metallic brass temple bell with rich resonant overtones and exponential decay."""
        t = np.linspace(0, duration_sec, int(sample_rate * duration_sec), False)
        freqs = [520.0, 1040.0, 1560.0, 2180.0, 3120.0]
        weights = [1.0, 0.6, 0.4, 0.25, 0.15]
        decays = [1.8, 2.5, 3.5, 5.0, 7.0]
        
        signal = np.zeros_like(t)
        for f, w, d in zip(freqs, weights, decays):
            env = np.exp(-d * t)
            signal += w * np.sin(2 * np.pi * f * t) * env
            
        signal = signal / np.max(np.abs(signal)) * 0.8
        audio_int16 = (signal * 32767).astype(np.int16)
        
        buf = io.BytesIO()
        wavfile.write(buf, sample_rate, audio_int16)
        buf.seek(0)
        seg = AudioSegment.from_file(buf, format="wav")
        buf.close()
        return seg

    @staticmethod
    def generate_conch_blast(duration_sec: float = 3.5, sample_rate: int = 44100) -> AudioSegment:
        """Synthesizes sacred Shankham (Conch shell) resonant blast with characteristic frequency sweep."""
        t = np.linspace(0, duration_sec, int(sample_rate * duration_sec), False)
        pitch_env = 280.0 + 80.0 * np.sin(np.pi * (t / duration_sec) ** 0.5)
        phase = 2 * np.pi * np.cumsum(pitch_env) / sample_rate
        
        signal = (
            0.6 * np.sin(phase) + 
            0.35 * np.sin(2 * phase) + 
            0.2 * np.sin(3 * phase) + 
            0.1 * np.sin(4 * phase)
        )
        amp_env = np.minimum(t / 0.4, 1.0) * np.maximum(0, (duration_sec - t) / 0.8)
        signal = signal * amp_env
        signal = signal / (np.max(np.abs(signal)) + 1e-6) * 0.85
        
        audio_int16 = (signal * 32767).astype(np.int16)
        buf = io.BytesIO()
        wavfile.write(buf, sample_rate, audio_int16)
        buf.seek(0)
        seg = AudioSegment.from_file(buf, format="wav")
        buf.close()
        return seg

    @staticmethod
    def generate_temple_ambience(duration_sec: float, sample_rate: int = 44100) -> AudioSegment:
        """Synthesizes soothing continuous temple drone ambience (Tanpura hum + soft echo)."""
        t = np.linspace(0, duration_sec, int(sample_rate * duration_sec), False)
        drone1 = np.sin(2 * np.pi * 138.59 * t) * (0.8 + 0.2 * np.sin(2 * np.pi * 0.2 * t))
        drone2 = np.sin(2 * np.pi * 207.65 * t) * (0.6 + 0.2 * np.cos(2 * np.pi * 0.15 * t))
        drone3 = np.sin(2 * np.pi * 277.18 * t) * 0.3
        
        signal = 0.4 * drone1 + 0.3 * drone2 + 0.15 * drone3
        signal = signal / (np.max(np.abs(signal)) + 1e-6) * 0.3
        
        audio_int16 = (signal * 32767).astype(np.int16)
        buf = io.BytesIO()
        wavfile.write(buf, sample_rate, audio_int16)
        buf.seek(0)
        seg = AudioSegment.from_file(buf, format="wav")
        buf.close()
        return seg

class TempleEffectsMixer:
    """Intelligently mixes temple sound effects into the speech timeline."""
    
    @staticmethod
    def mix_effects(
        speech_segments: List[AudioSegment], 
        effect_settings: Dict[str, Any]
    ) -> AudioSegment:
        """
        Builds a timeline and layers bell, conch, and background ambience according to user choices and intensity.
        """
        intensity = float(effect_settings.get("intensity", 0.3))
        bg_ambience = effect_settings.get("bg_ambience", True)
        bell_enabled = effect_settings.get("bell", True)
        conch_enabled = effect_settings.get("conch", False)
        festival_ambience = effect_settings.get("festival", False)
        
        combined_speech = AudioSegment.silent(duration=500)
        for seg in speech_segments:
            combined_speech += seg + AudioSegment.silent(duration=400)
        combined_speech += AudioSegment.silent(duration=1000)
        
        total_duration_ms = len(combined_speech)
        total_duration_sec = total_duration_ms / 1000.0
        
        timeline = AudioSegment.silent(duration=total_duration_ms)
        
        if bg_ambience or festival_ambience:
            ambience_seg = TempleEffectsGenerator.generate_temple_ambience(total_duration_sec)
            gain_db = -30.0 + (intensity * 20.0)
            ambience_seg = ambience_seg.apply_gain(gain_db)
            timeline = timeline.overlay(ambience_seg, position=0)
            
        intro_offset_ms = 500
        if conch_enabled:
            conch_seg = TempleEffectsGenerator.generate_conch_blast()
            gain_db = -12.0 + (intensity * 10.0)
            timeline = timeline.overlay(conch_seg.apply_gain(gain_db), position=200)
            intro_offset_ms = len(conch_seg) - 500
            
        if bell_enabled:
            bell_seg = TempleEffectsGenerator.generate_temple_bell()
            gain_db = -10.0 + (intensity * 10.0)
            bell_gained = bell_seg.apply_gain(gain_db)
            
            timeline = timeline.overlay(bell_gained, position=max(200, intro_offset_ms - 1000))
            end_pos = max(0, total_duration_ms - len(bell_seg) - 200)
            timeline = timeline.overlay(bell_gained, position=end_pos)
            
        final_mix = timeline.overlay(combined_speech, position=intro_offset_ms)
        return final_mix
