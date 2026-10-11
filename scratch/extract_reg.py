import re

with open(r'e:\kurichiyar matrimony\lib\features\registration\registration_state_mixin.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's find map literals in registration_state_mixin
print("File length:", len(text))

# Find lines where data is assigned to firestore
for line in text.split('\n'):
    if 'firestore' in line.lower() or 'collection' in line.lower() or 'set(' in line or 'update(' in line:
        print(line.strip()[:120])
