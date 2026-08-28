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
