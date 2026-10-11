import os, re, json

lib_dir = r'e:\kurichiyar matrimony\lib'
collections = set()
file_col_map = {}

for root, _, files in os.walk(lib_dir):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8', errors='ignore') as fp:
                content = fp.read()
                # matches .collection('...')
                matches = re.findall(r"\.collection\(\s*['\"]([^'\"]+)['\"]\s*\)", content)
                for m in matches:
                    collections.add(m)
                    if m not in file_col_map:
                        file_col_map[m] = []
                    file_col_map[m].append(os.path.relpath(path, lib_dir))

print(f"Total Collections Found: {len(collections)}")
for col in sorted(list(collections)):
    files = list(set(file_col_map[col]))
    print(f"- {col} (in {len(files)} files: {', '.join(files[:3])})")
