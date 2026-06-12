import os

file_path = r"c:/Users/Lap Tech/Pictures/Saber Academy/lib/screens/shared/mushaf_viewer_screen.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = """                                        if (_audioService.isPlaying &&
                                            _audioService.playingPage == pageNum &&
                                            _audioService.bundle != null &&
                                            _audioService.playingAyahIndex >= 0 &&
                                            _audioService.playingAyahIndex < _audioService.bundle!.arabic.length)
                                          _MushafPageHighlightOverlay(
                                            pageNum: pageNum,
                                            suraId: _audioService.bundle!.arabic[_audioService.playingAyahIndex].surahNumber,
                                            ayahId: _audioService.bundle!.arabic[_audioService.playingAyahIndex].numberInSurah,
                                            mushafType: _mushafType,
                                          ),
                                        _MushafPageGestureOverlay("""

replacement = """                                        if (_audioService.isPlaying &&
                                            _audioService.playingPage == pageNum &&
                                            _audioService.bundle != null &&
                                            _audioService.playingAyahIndex >= 0 &&
                                            _audioService.playingAyahIndex < _audioService.bundle!.arabic.length)
                                          _MushafPageHighlightOverlay(
                                            pageNum: pageNum,
                                            suraId: _audioService.bundle!.arabic[_audioService.playingAyahIndex].surahNumber,
                                            ayahId: _audioService.bundle!.arabic[_audioService.playingAyahIndex].numberInSurah,
                                            mushafType: _mushafType,
                                          ),
                                        if (_selectedSurahId != null && _selectedAyahId != null)
                                          _MushafPageHighlightOverlay(
                                            pageNum: pageNum,
                                            suraId: _selectedSurahId!,
                                            ayahId: _selectedAyahId!,
                                            mushafType: _mushafType,
                                          ),
                                        _MushafPageGestureOverlay("""

content_norm = content.replace('\r\n', '\n')
target_norm = target.replace('\r\n', '\n')
replacement_norm = replacement.replace('\r\n', '\n')

if target_norm in content_norm:
    new_content = content_norm.replace(target_norm, replacement_norm)
    if '\r\n' in content:
        new_content = new_content.replace('\n', '\r\n')
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Success: Mushaf viewer screen modified.")
else:
    print("Error: Target content not found in file.")
