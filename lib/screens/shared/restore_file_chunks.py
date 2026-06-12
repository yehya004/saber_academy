import json
import sys

# Set standard output to UTF-8
sys.stdout.reconfigure(encoding='utf-8')

log_file = r"C:\Users\Yehya\.gemini\antigravity\brain\af8dfd62-e85d-4508-88a6-4dd7b303bbe7\.system_generated\logs\transcript.jsonl"

with open(log_file, "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    try:
        obj = json.loads(line)
        tool_calls = obj.get("tool_calls", [])
        for tc in tool_calls:
            name = tc.get("name")
            args = tc.get("args", {})
            if "mushaf_viewer_screen.dart" in str(args.get("TargetFile", "")):
                print(f"\n--- STEP {i} ({name}) ---")
                
                # Check target file
                tf = args.get("TargetFile")
                print(f"TargetFile: {tf}")
                
                if name == "replace_file_content":
                    print(f"StartLine: {args.get('StartLine')}, EndLine: {args.get('EndLine')}")
                    tc_content = args.get('TargetContent', '')
                    rc_content = args.get('ReplacementContent', '')
                    print(f"TargetContent:\n{tc_content}")
                    print(f"ReplacementContent:\n{rc_content}")
                elif name == "multi_replace_file_content":
                    chunks = args.get("ReplacementChunks")
                    if isinstance(chunks, str):
                        try:
                            chunks = json.loads(chunks, strict=False)
                        except Exception as je:
                            print(f"Failed to parse chunks string: {je}")
                    
                    if isinstance(chunks, list):
                        print(f"Number of chunks: {len(chunks)}")
                        for idx, chunk in enumerate(chunks):
                            print(f"  Chunk {idx}: StartLine: {chunk.get('StartLine')}, EndLine: {chunk.get('EndLine')}")
                            print(f"  TargetContent:\n{chunk.get('TargetContent')}")
                            print(f"  ReplacementContent:\n{chunk.get('ReplacementContent')}")
                    else:
                        print(f"Chunks type: {type(chunks)}, val: {str(chunks)[:200]}")
    except Exception as e:
        print(f"Error parsing line {i}: {e}")
