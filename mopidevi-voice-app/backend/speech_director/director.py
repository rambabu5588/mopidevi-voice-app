from typing import Dict, Any

STYLE_PRESETS: Dict[str, Dict[str, Any]] = {
    "Devotional": {
        "speed": 0.88,
        "pitch_shift": "-3Hz",
        "pre_pause_ms": 400,
        "post_pause_ms": 450,
        "volume_gain": "+0dB",
        "rate_str": "-12%",
        "pitch_str": "-4Hz",
        "description": "భక్తిపూర్వక మరియు ప్రశాంతమైన ధ్వని (Solemn & Sacred)"
    },
    "Announcement": {
        "speed": 0.95,
        "pitch_shift": "+0Hz",
        "pre_pause_ms": 250,
        "post_pause_ms": 300,
        "volume_gain": "+2dB",
        "rate_str": "-5%",
        "pitch_str": "+0Hz",
        "description": "స్పష్టమైన మరియు బిగ్గరగా ఉండే ప్రకటనా ధ్వని (Clear & Loud)"
    },
    "Warm": {
        "speed": 0.90,
        "pitch_shift": "+1Hz",
        "pre_pause_ms": 300,
        "post_pause_ms": 350,
        "volume_gain": "+0dB",
        "rate_str": "-10%",
        "pitch_str": "+1Hz",
        "description": "ఆప్యాయత కలిగిన దయగల ధ్వని (Warm & Welcoming)"
    },
    "Festival": {
        "speed": 1.00,
        "pitch_shift": "+2Hz",
        "pre_pause_ms": 200,
        "post_pause_ms": 250,
        "volume_gain": "+3dB",
        "rate_str": "+0%",
        "pitch_str": "+3Hz",
        "description": "ఉత్సవ వాతావరణం మరియు ఉత్సాహభరిత ధ్వని (Festive & Vibrant)"
    },
    "Important": {
        "speed": 0.84,
        "pitch_shift": "-2Hz",
        "pre_pause_ms": 500,
        "post_pause_ms": 500,
        "volume_gain": "+3dB",
        "rate_str": "-16%",
        "pitch_str": "-2Hz",
        "description": "ముఖ్యమైన మరియు దృష్టిని ఆకర్షించే ధ్వని (Urgent & Clear)"
    },
    "Spiritual": {
        "speed": 0.80,
        "pitch_shift": "-5Hz",
        "pre_pause_ms": 600,
        "post_pause_ms": 650,
        "volume_gain": "-1dB",
        "rate_str": "-20%",
        "pitch_str": "-6Hz",
        "description": "వేద పఠనం వంటి గంభీరమైన ధ్వని (Deep & Resonant)"
    }
}

class SpeechDirector:
    def __init__(self, style_name: str = "Devotional"):
        self.style_name = style_name if style_name in STYLE_PRESETS else "Devotional"
        self.params = STYLE_PRESETS[self.style_name]
        
    def get_prosody_for_sentence(self, index: int, total: int) -> Dict[str, Any]:
        """Returns prosody and timing controls for sentence index."""
        prosody = dict(self.params)
        prosody["style_name"] = self.style_name
        if index == 0:
            prosody["pre_pause_ms"] += 200
        if index == total - 1:
            prosody["post_pause_ms"] += 300
        return prosody

def get_available_styles() -> Dict[str, Dict[str, Any]]:
    return STYLE_PRESETS
