import os

lib_dir = r'e:\kurichiyar matrimony\lib'

def dump_file(rel_path):
    print(f"\n==================== {rel_path} ====================")
    p = os.path.join(lib_dir, rel_path)
    if os.path.exists(p):
        with open(p, 'r', encoding='utf-8', errors='ignore') as f:
            print(f.read())
    else:
        print("File not found")

dump_file(r'core\models\profile\user_education_career.dart')
dump_file(r'core\models\profile\user_family_details.dart')
dump_file(r'core\models\profile\user_lineage_details.dart')
