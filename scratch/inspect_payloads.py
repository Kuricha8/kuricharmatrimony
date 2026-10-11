import os, re, sys
sys.stdout.reconfigure(encoding='utf-8')

lib_dir = r'e:\kurichiyar matrimony\lib'

def inspect_code_blocks(rel_path, target_words):
    p = os.path.join(lib_dir, rel_path)
    if not os.path.exists(p):
        return
    with open(p, 'r', encoding='utf-8', errors='ignore') as fp:
        lines = fp.readlines()
    print(f"\n==================== {rel_path} ====================")
    for i, line in enumerate(lines):
        if any(w in line for w in target_words):
            start = max(0, i - 5)
            end = min(len(lines), i + 25)
            print(f"--- Around line {i+1} ---")
            for j in range(start, end):
                print(f"{j+1}: {lines[j].rstrip()}")

inspect_code_blocks(r'features\agent_dashboard\services\agent_client_service.dart', ['profile_edit_requests', 'activity_logs'])
inspect_code_blocks(r'features\agent_dashboard\services\agent_call_service.dart', ['calls', 'agents'])
inspect_code_blocks(r'core\services\match_status_security_service.dart', ['matches', 'proposals'])
inspect_code_blocks(r'features\family_tree\family_registration_screen.dart', ['ft_members', 'ft_approvals'])
inspect_code_blocks(r'features\family_tree\notice_and_approval_screen.dart', ['ft_notices'])
inspect_code_blocks(r'features\auth_splash\terms_and_conditions_page.dart', ['terms_agreements'])
inspect_code_blocks(r'features\matching\match_audio_pool_service.dart', ['match_audio_pool'])
inspect_code_blocks(r'core\services\in_app_update_service.dart', ['app_updates'])
