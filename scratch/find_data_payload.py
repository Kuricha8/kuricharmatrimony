with open(r'e:\kurichiyar matrimony\lib\features\registration\registration_state_mixin.dart', 'r', encoding='utf-8') as f:
    text = f.read()

idx = text.find('SAVING PROFILE TO FIRESTORE')
if idx != -1:
    # let's look at 5000 characters before this
    start = max(0, idx - 8000)
    print(text[start:idx+500])
