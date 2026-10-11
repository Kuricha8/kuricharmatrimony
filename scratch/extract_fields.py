import os
import re
import json

root_dir = r"e:\kurichiyar matrimony\lib"

# Let's inspect all files and extract collection operations, payload keys, models
fields_by_collection = {}

# Patterns
# 1. db.collection('X')....add({ ... }) or set({ ... }) or update({ ... })
map_assign_pattern = re.compile(r"['\"]([a-zA-Z0-9_]+)['\"]\s*:\s*([^,\n}]+)")

for root, dirs, files in os.walk(root_dir):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8', errors='ignore') as fp:
                lines = fp.readlines()
                current_col = None
                for i, line in enumerate(lines):
                    col_m = re.search(r"\.collection\s*\(\s*['\"]([^'\"]+)['\"]\s*\)", line)
                    if col_m:
                        current_col = col_m.group(1)
                        if current_col not in fields_by_collection:
                            fields_by_collection[current_col] = set()
                        # scan next 30 lines for dictionary keys
                        block = "".join(lines[i:min(i+35, len(lines))])
                        for k, v in map_assign_pattern.findall(block):
                            if k not in ['collection', 'doc', 'instance', 'then', 'catchError']:
                                fields_by_collection[current_col].add(k)

print("=== FIELDS DETECTED PER COLLECTION ===")
for c, keys in sorted(fields_by_collection.items()):
    print(f"\nCollection: {c} ({len(keys)} fields detected)")
    for k in sorted(keys)[:20]:
        print(f"  - {k}")
    if len(keys) > 20:
        print(f"  ... and {len(keys) - 20} more")
