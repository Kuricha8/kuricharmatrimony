import os, re, json

lib_dir = r'e:\kurichiyar matrimony\lib'

# Let's inspect registration_state_mixin.dart specifically for the complete user registration payload
reg_mixin_path = os.path.join(lib_dir, 'features', 'registration', 'registration_state_mixin.dart')
if os.path.exists(reg_mixin_path):
    with open(reg_mixin_path, 'r', encoding='utf-8', errors='ignore') as f:
        reg_code = f.read()
    print("Found registration_state_mixin.dart")
else:
    print("registration_state_mixin.dart NOT found")

# Let's find all user serialization files in core/models
models_dir = os.path.join(lib_dir, 'core', 'models')
model_files = []
for root, _, files in os.walk(models_dir):
    for f in files:
        if f.endswith('.dart'):
            model_files.append(os.path.join(root, f))

print(f"Model files found: {len(model_files)}")
for mf in model_files:
    print(" - ", os.path.relpath(mf, lib_dir))
