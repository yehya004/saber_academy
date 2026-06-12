import os
import glob

pub_cache = os.path.expandvars(r'%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev')
matches = glob.glob(os.path.join(pub_cache, 'flutter_local_notifications-22.*', 'lib', 'src', 'flutter_local_notifications_plugin.dart'))
if not matches:
    pub_cache = os.path.expanduser('~/.pub-cache/hosted/pub.dev')
    matches = glob.glob(os.path.join(pub_cache, 'flutter_local_notifications-22.*', 'lib', 'src', 'flutter_local_notifications_plugin.dart'))

print("Found flutter_local_notifications files:", matches)
for match in matches:
    print("File:", match)
    with open(match, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.splitlines()
        
        # Search for initialize, show, and zonedSchedule methods
        for idx, line in enumerate(lines):
            if 'Future<bool?> initialize' in line or 'Future<void> show' in line or 'Future<void> zonedSchedule' in line:
                print(f"--- Method at line {idx+1}: {line}")
                # Print the next 10 lines
                for offset in range(1, 15):
                    if idx + offset < len(lines):
                        print(f"  {idx+1+offset}: {lines[idx+offset]}")
