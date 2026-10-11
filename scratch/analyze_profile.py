import os, re, json

lib_dir = r'e:\kurichiyar matrimony\lib'

def analyze_profile_models():
    profile_dir = os.path.join(lib_dir, 'core', 'models', 'profile')
    for f in os.listdir(profile_dir):
        if f.endswith('.dart'):
            path = os.path.join(profile_dir, f)
            print(f"=== {f} ===")
            with open(path, 'r', encoding='utf-8', errors='ignore') as fp:
                for line in fp:
                    line_s = line.strip()
                    if line_s.startswith('final ') or "['" in line_s or '":' in line_s or 'toFirestore' in line_s or 'toMap' in line_s:
                        print("  ", line_s[:100])

analyze_profile_models()
