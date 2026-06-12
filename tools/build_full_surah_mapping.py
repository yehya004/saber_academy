# Complete 114 Surah PDF start page mapping for Diyanet Quran (616 pages total)
# Based on exact detected headers in C:\Users\Yehya\Pictures\Saber Academy\tools\detected_surahs.txt
# and detailed page inspections (pages 594-606).
# PDF page = printed page + 2 (usually), but starts of Surahs are mapped here to their exact PDF page (1-indexed).

surah_map = {
    1: 2,    # Al-Fatihah
    2: 3,    # Al-Baqarah
    3: 50,   # Aal-Imran
    4: 77,   # Al-Nisa
    5: 107,  # Al-Ma'idah
    6: 129,  # Al-An'am (header is on 129, but body text starts there)
    7: 152,  # Al-A'raf
    8: 178,  # Al-Anfal
    9: 188,  # Al-Tawbah
    10: 208, # Yunus
    11: 222, # Hud
    12: 236, # Yusuf
    13: 250, # Al-Ra'd
    14: 256, # Ibrahim
    15: 263, # Al-Hijr
    16: 268, # Al-Nahl
    17: 283, # Al-Isra
    18: 294, # Al-Kahf
    19: 306, # Maryam
    20: 313, # Taha
    21: 323, # Al-Anbiya
    22: 332, # Al-Hajj
    23: 342, # Al-Mu'minun
    24: 350, # Al-Nur
    25: 360, # Al-Furqan
    26: 367, # Al-Shu'ara
    27: 377, # Al-Naml
    28: 386, # Al-Qasas
    29: 397, # Al-Ankabut
    30: 405, # Al-Rum
    31: 412, # Luqman
    32: 415, # Al-Sajdah
    33: 418, # Al-Ahzab
    34: 429, # Saba
    35: 435, # Fatir
    36: 441, # Yasin
    37: 446, # Al-Saffat
    38: 453, # Sad
    39: 459, # Al-Zumar
    40: 468, # Ghafir
    41: 478, # Fussilat
    42: 484, # Al-Shura
    43: 490, # Al-Zukhruf
    44: 497, # Al-Dukhan
    45: 499, # Al-Jathiyah
    46: 503, # Al-Ahqaf
    47: 507, # Muhammad
    48: 512, # Al-Fath
    49: 516, # Al-Hujurat
    50: 519, # Qaf
    51: 521, # Al-Dhariyat
    52: 524, # Al-Tur
    53: 526, # Al-Najm
    54: 529, # Al-Qamar
    55: 532, # Al-Rahman
    56: 535, # Al-Waqi'ah
    57: 538, # Al-Hadid
    58: 543, # Al-Mujadilah
    59: 546, # Al-Hashr
    60: 549, # Al-Mumtahanah
    61: 552, # Al-Saff
    62: 554, # Al-Jumu'ah
    63: 555, # Al-Munafiqun
    64: 556, # Al-Taghabun
    65: 558, # Al-Talaq
    66: 561, # Al-Tahrim
    67: 563, # Al-Mulk
    68: 565, # Al-Qalam
    69: 567, # Al-Haqqah
    70: 569, # Al-Ma'arij
    71: 571, # Nuh
    72: 573, # Al-Jinn
    73: 575, # Al-Muzzammil
    74: 576, # Al-Muddaththir
    75: 578, # Al-Qiyamah
    76: 579, # Al-Insan
    77: 581, # Al-Mursalat
    78: 583, # Al-Naba
    79: 584, # Al-Nazi'at
    80: 586, # Abasa
    81: 587, # Al-Takwir
    82: 588, # Al-Infitar
    83: 589, # Al-Mutaffifin
    84: 590, # Al-Inshiqaq
    85: 591, # Al-Buruj
    86: 592, # Al-Tariq
    87: 593, # Al-A'la
    88: 593, # Al-Ghashiyah
    89: 594, # Al-Fajr
    90: 596, # Al-Balad
    91: 596, # Al-Shams
    92: 597, # Al-Layl
    93: 597, # Al-Duha
    94: 598, # Al-Sharh
    95: 598, # At-Tin
    96: 599, # Al-Alaq
    97: 600, # Al-Qadr
    98: 600, # Al-Bayyinah
    99: 601, # Az-Zalzalah
    100: 601, # Al-Adiyat
    101: 602, # Al-Qari'ah
    102: 602, # At-Takathur
    103: 603, # Al-Asr
    104: 603, # Al-Humazah
    105: 603, # Al-Fil
    106: 604, # Quraysh
    107: 604, # Al-Ma'un
    108: 604, # Al-Kawthar
    109: 605, # Al-Kafirun
    110: 605, # Al-Nasr
    111: 605, # Al-Masad
    112: 606, # Al-Ikhlas
    113: 606, # Al-Falaq
    114: 606  # Al-Nas
}

# Print as a formatted list of ints for Dart
formatted_list = []
for i in range(1, 115):
    formatted_list.append(surah_map[i])

print("static const List<int> _diyanetSurahPages = [")
for i, page in enumerate(formatted_list):
    print(f"  {page}, // {i+1}")
print("];")
