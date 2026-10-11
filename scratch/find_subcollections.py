import os
import re

subcol_pattern = re.compile(r"\.collection\s*\(\s*['\"]([^'\"]+)['\"]\s*\)\s*\.doc\s*\([^)]*\)\s*\.collection\s*\(\s*['\"]([^'\"]+)['\"]\s*\)")

subcollections = set()

for root, dirs, files in os.walk(r'e:\kurichiyar matrimony\lib'):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8', errors='ignore') as fp:
                content = fp.read()
                matches = subcol_pattern.findall(content)
                for p, s in matches:
                    subcollections.add((p, s))

print("Subcollections found:")
for p, s in sorted(subcollections):
    print(f"- {p} -> {s}")
