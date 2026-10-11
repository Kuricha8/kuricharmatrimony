with open(r'e:\kurichiyar matrimony\lib\core\services\firebase_firestore_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

print("firebase_firestore_service length:", len(text))
for line in text.split('\n'):
    if 'collection(' in line or 'Future' in line or 'Stream' in line or 'Map<String, dynamic>' in line:
        print(line.strip()[:120])
