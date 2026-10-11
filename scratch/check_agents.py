import os, re

lib_dir = r'e:\kurichiyar matrimony\lib'

for root, _, files in os.walk(lib_dir):
    for f in files:
        if f.endswith('.dart'):
            p = os.path.join(root, f)
            with open(p, 'r', encoding='utf-8', errors='ignore') as fp:
                content = fp.read()
                if "'agents'" in content or '"agents"' in content or 'agent_applications' in content or 'agent_client' in content or 'agent_call' in content:
                    print(f"=== {f} ({os.path.relpath(p, lib_dir)}) ===")
                    # print lines around agents
                    for line in content.split('\n'):
                        if 'agents' in line or 'agent' in line.lower() and ('set(' in line or 'update(' in line or 'collection(' in line or 'add(' in line or 'doc(' in line):
                            print("  ", line.strip()[:120])
