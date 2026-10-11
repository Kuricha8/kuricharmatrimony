import os
import re
import json

collection_pattern = re.compile(r"\.collection\s*\(\s*['\"]([^'\"]+)['\"]\s*\)")
collection_var_pattern = re.compile(r"\.collection\s*\(\s*([a-zA-Z0-9_]+)\s*\)")

results = {}
all_collections = set()

for root, dirs, files in os.walk(r'e:\kurichiyar matrimony\lib'):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8', errors='ignore') as fp:
                content = fp.read()
                matches = collection_pattern.findall(content)
                for col in matches:
                    all_collections.add(col)
                    if col not in results:
                        results[col] = []
                    rel_path = os.path.relpath(path, r'e:\kurichiyar matrimony')
                    results[col].append(rel_path)

print(f"Total Unique Collections: {len(all_collections)}")
for col in sorted(all_collections):
    print(f"- {col} (used in {len(results[col])} files)")
