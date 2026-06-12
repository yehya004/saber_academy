import os
import glob

pub_cache = os.path.expandvars(r'%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev')
# Let's search under this directory
matches = glob.glob(os.path.join(pub_cache, 'file_picker-*', 'lib', 'src', 'file_picker.dart'))
if not matches:
    # try standard .pub-cache in user profile
    pub_cache = os.path.expanduser('~/.pub-cache/hosted/pub.dev')
    matches = glob.glob(os.path.join(pub_cache, 'file_picker-*', 'lib', 'src', 'file_picker.dart'))

print("Found file_picker files:", matches)
for match in matches:
    print("File:", match)
    with open(match, 'r', encoding='utf-8') as f:
        content = f.read()
        # look for static get platform or similar
        lines = content.splitlines()
        for idx, line in enumerate(lines):
            if 'class FilePicker' in line or 'platform' in line.lower():
                print(f"{idx+1}: {line}")
