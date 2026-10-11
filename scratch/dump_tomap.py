import os

lib_dir = r'e:\kurichiyar matrimony\lib'

def dump_toMap(rel_path):
    print(f"\n==================== {rel_path} ====================")
    p = os.path.join(lib_dir, rel_path)
    with open(p, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    # find toMap
    idx = content.find('Map<String, dynamic> toMap()')
    if idx != -1:
        print(content[idx:idx+1500])
    else:
        print("toMap not found")

dump_toMap(r'core\models\profile\user_education_career.dart')
dump_toMap(r'core\models\profile\user_family_details.dart')
