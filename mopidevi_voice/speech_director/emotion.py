from typing import Dict, Any, List

EMOTION_STYLES: Dict[str, Dict[str, Any]] = {
    "Devotional": {
        "icon": "🙏",
        "title": "భక్తిపూర్వక (Devotional)",
        "use_case": "ఆలయ పరిచయం మరియు ప్రార్థనలు (Temple intro/prayer)",
        "speed": 0.88,
        "pitch": "-4Hz",
        "rate_str": "-12%",
        "opening_pause_ms": 700,
        "closing_pause_ms": 600,
        "volume_gain": "+0dB"
    },
    "Announcement": {
        "icon": "📢",
        "title": "ప్రకటన (Announcement)",
        "use_case": "దర్శనం, వేళలు, సదుపాయాలు (Darshan, timings, facilities)",
        "speed": 0.95,
        "pitch": "+0Hz",
        "rate_str": "-5%",
        "opening_pause_ms": 300,
        "closing_pause_ms": 400,
        "volume_gain": "+2dB"
    },
    "Warm": {
        "icon": "❤️",
        "title": "ఆప్యాయత (Warm)",
        "use_case": "స్వాగతం మరియు సమాచారం (Welcome/information)",
        "speed": 0.90,
        "pitch": "+1Hz",
        "rate_str": "-10%",
        "opening_pause_ms": 400,
        "closing_pause_ms": 450,
        "volume_gain": "+0dB"
    },
    "Important": {
        "icon": "⚠️",
        "title": "ముఖ్యమైన (Important)",
        "use_case": "నియమాలు, సూచనలు, హెచ్చరికలు (Rules, warnings)",
        "speed": 0.84,
        "pitch": "-2Hz",
        "rate_str": "-16%",
        "opening_pause_ms": 500,
        "closing_pause_ms": 500,
        "volume_gain": "+3dB"
    },
    "Festival": {
        "icon": "🎉",
        "title": "ఉత్సవ (Festival)",
        "use_case": "బ్రహ్మోత్సవాలు, విశేష వేడుకలు (Brahmotsavam/major events)",
        "speed": 1.00,
        "pitch": "+3Hz",
        "rate_str": "+0%",
        "opening_pause_ms": 250,
        "closing_pause_ms": 300,
        "volume_gain": "+3dB"
    },
    "Spiritual": {
        "icon": "🕉️",
        "title": "వేద ధ్వని (Spiritual)",
        "use_case": "స్వామివారి చరిత్ర మరియు నారాయణ స్తుతి (Deity history/devotional narration)",
        "speed": 0.80,
        "pitch": "-6Hz",
        "rate_str": "-20%",
        "opening_pause_ms": 800,
        "closing_pause_ms": 800,
        "volume_gain": "-1dB"
    }
}

def get_emotion_profile(style_name: str) -> Dict[str, Any]:
    return EMOTION_STYLES.get(style_name, EMOTION_STYLES["Devotional"])

def LIST_STYLES() -> List[Dict[str, Any]]:
    return [{"key": k, **v} for k, v in EMOTION_STYLES.items()]
