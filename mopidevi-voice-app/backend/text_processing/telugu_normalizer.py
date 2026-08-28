import re
from typing import List

TELUGU_NUMBERS = {
    0: "సున్నా", 1: "ఒకటి", 2: "రెండు", 3: "మూడు", 4: "నాలుగు", 5: "ఐదు",
    6: "ఆరు", 7: "ఏడు", 8: "ఎనిమిది", 9: "తొమ్మిది", 10: "పది",
    11: "పదకొండు", 12: "పన్నెండు", 13: "పదమూడు", 14: "పదునాలుగు", 15: "పదిహేను",
    16: "పదహారు", 17: "పదిహేడు", 18: "పద్దెనిమిది", 19: "పంతొమ్మిది", 20: "ఇరవై",
    30: "ముప్పై", 40: "నలభై", 50: "యాభై", 60: "అరవై", 70: "దెబ్బై",
    80: "ఎనభై", 90: "తొమ్మిభై", 100: "వంద", 500: "ఐదు వందలు", 1000: "వేయి"
}

def number_to_telugu(n: int) -> str:
    if n in TELUGU_NUMBERS:
        return TELUGU_NUMBERS[n]
    if n < 100:
        tens = (n // 10) * 10
        rem = n % 10
        if rem == 0:
            return TELUGU_NUMBERS.get(tens, str(n))
        return f"{TELUGU_NUMBERS.get(tens, '')} {TELUGU_NUMBERS.get(rem, '')}".strip()
    if n < 1000:
        hundreds = n // 100
        rem = n % 100
        h_str = "వంద" if hundreds == 1 else f"{TELUGU_NUMBERS.get(hundreds, '')} వందల"
        if rem == 0:
            return h_str
        return f"{h_str} {number_to_telugu(rem)}".strip()
    if n < 100000:
        thousands = n // 1000
        rem = n % 1000
        t_str = "వేయి" if thousands == 1 else f"{number_to_telugu(thousands)} వేల"
        if rem == 0:
            return t_str
        return f"{t_str} {number_to_telugu(rem)}".strip()
    return str(n)

def convert_time_to_telugu(match_obj, full_text: str) -> str:
    start, end = match_obj.span()
    time_str = match_obj.group(0)
    
    match = re.match(r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?', time_str)
    if not match:
        return time_str
    hrs = int(match.group(1))
    mins = int(match.group(2))
    
    # Check if preceding word is already 'ఉదయం' / 'సాయంత్రం' / 'మధ్యాహ్నం'
    preceding_text = full_text[:start].strip()
    has_period_before = any(p in preceding_text[-15:] for p in ["ఉదయం", "సాయంత్రం", "మధ్యాహ్నం", "రాత్రి"])
    
    # Check if following text has 'గంటలు' or 'గంటలకు'
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

def normalize_telugu_text(text: str) -> str:
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
    text = text.strip()
    return text

def segment_sentences(text: str) -> List[str]:
    cleaned = normalize_telugu_text(text)
    if not cleaned:
        return []
    
    raw_sentences = re.split(r'(?<=[.!?|\n])\s+', cleaned)
    sentences = []
    for s in raw_sentences:
        s = s.strip()
        if s:
            sentences.append(s)
    return sentences if sentences else [cleaned]
