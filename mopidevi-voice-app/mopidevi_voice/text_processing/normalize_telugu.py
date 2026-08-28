import re
from mopidevi_voice.text_processing.numbers import number_to_telugu

def convert_time_to_telugu(match_obj, full_text: str) -> str:
    start, end = match_obj.span()
    time_str = match_obj.group(0)
    
    match = re.match(r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?', time_str)
    if not match:
        return time_str
    hrs = int(match.group(1))
    mins = int(match.group(2))
    
    preceding_text = full_text[:start].strip()
    has_period_before = any(p in preceding_text[-15:] for p in ["ఉదయం", "సాయంత్రం", "మధ్యాహ్నం", "రాత్రి"])
    
    following_text = full_text[end:].strip()
    has_hours_after = following_text.startswith("గంట")
    
    hrs_telugu = number_to_telugu(hrs)
    
    res = ""
    if not has_period_before:
        period = match.group(3).upper() if match.group(3) else ""
        if period == "AM" or (hrs < 12 and not period):
            res += "ఉదయం "
        elif period == "PM":
            res += "మధ్యాహ్నం " if 12 <= hrs < 16 else "సాయంత్రం "
            
    if mins == 0:
        res += f"{hrs_telugu}"
    elif mins == 30:
        res += f"{hrs_telugu}న్నర"
    else:
        mins_telugu = number_to_telugu(mins)
        res += f"{hrs_telugu} గంటల {mins_telugu} నిమిషాలకు"
        return res
        
    if not has_hours_after:
        res += " గంటలకు"
        
    return res

def normalize_telugu(text: str) -> str:
    if not text:
        return ""
    
    # 1. Expand Time expressions (e.g. 10:30 AM)
    text = re.sub(r'\b\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?\b', lambda m: convert_time_to_telugu(m, text), text)
    
    # 2. Expand standalone numbers
    def replace_num(m):
        val = int(m.group(0))
        return number_to_telugu(val)
    text = re.sub(r'\b\d+\b', replace_num, text)
    
    # 3. Clean duplicate words and standard whitespace
    text = re.sub(r'\b(\w+)\s+\1\b', r'\1', text)
    text = re.sub(r'[ \t]+', ' ', text)
    return text.strip()
