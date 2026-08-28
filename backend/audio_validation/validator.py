import os
import numpy as np
from typing import Dict, Any, Tuple
from pydub import AudioSegment

class AudioValidator:
    """Validates generated audio segments to eliminate silent audio or corrupted output."""
    
    @staticmethod
    def validate_segment(file_path: str, min_duration_sec: float = 0.5) -> Tuple[bool, Dict[str, Any]]:
        """
        Performs rigorous automated quality validation on audio file.
        Returns (is_valid, validation_report).
        """
        report = {
            "file_exists": False,
            "duration_sec": 0.0,
            "rms_energy": 0.0,
            "peak_level": 0.0,
            "is_silent": True,
            "clipping": False,
            "status": "FAILED",
            "reason": ""
        }
        
        # 1. File exists check
        if not os.path.exists(file_path) or os.path.getsize(file_path) == 0:
            report["reason"] = "File missing or zero bytes"
            return False, report
        report["file_exists"] = True
        
        try:
            audio = AudioSegment.from_file(file_path)
            duration = len(audio) / 1000.0
            report["duration_sec"] = duration
            
            # 2. Duration check
            if duration < min_duration_sec:
                report["reason"] = f"Duration too short ({duration:.2f}s < {min_duration_sec}s)"
                return False, report
            
            # 3. RMS Energy & Silence check
            rms = audio.rms
            max_possible_rms = audio.max_possible_amplitude or 32768
            norm_rms = rms / float(max_possible_rms)
            report["rms_energy"] = norm_rms
            
            max_dBFS = audio.max_dBFS
            report["peak_level"] = max_dBFS
            
            if norm_rms < 0.002 or max_dBFS < -50.0:
                report["is_silent"] = True
                report["reason"] = f"Silent or near-zero energy detected (rms={norm_rms:.4f})"
                return False, report
            
            report["is_silent"] = False
            
            # 4. Clipping check
            if max_dBFS > -0.1:
                report["clipping"] = True
                print("[AudioValidator] Warning: Potential audio clipping detected.")
            
            report["status"] = "PASSED"
            return True, report
            
        except Exception as e:
            report["reason"] = f"Audio parsing error: {str(e)}"
            return False, report
