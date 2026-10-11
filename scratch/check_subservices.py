import os, re

lib_dir = r'e:\kurichiyar matrimony\lib'

files_to_check = [
    r'features\agent_dashboard\services\agent_client_service.dart',
    r'features\agent_dashboard\services\agent_call_service.dart',
    r'features\agent_registration\agent_registration_screen.dart',
    r'core\services\match_status_security_service.dart',
    r'features\auth_splash\terms_and_conditions_page.dart',
    r'features\matching\match_audio_pool_service.dart',
    r'features\family_tree\family_registration_screen.dart',
    r'features\family_tree\notice_and_approval_screen.dart',
    r'core\services\in_app_update_service.dart'
]

for rel in files_to_check:
    p = os.path.join(lib_dir, rel)
    print(f"\n==================== {rel} ====================")
    if os.path.exists(p):
        with open(p, 'r', encoding='utf-8', errors='ignore') as fp:
            content = fp.read()
            # print all matches of collection or set or update or add
            for line in content.split('\n'):
                if any(k in line for k in ['collection(', '.doc(', '.set(', '.update(', '.add(', 'FieldValue.']):
                    print("  ", line.strip()[:140])
    else:
        print("File not found")
