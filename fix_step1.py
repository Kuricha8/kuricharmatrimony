import json
import re

def fix_step1():
    filepath = r"e:\kurichiyar matrimony\lib\features\registration\widgets\step1_basic_info.dart"
    lines_to_fix = [129, 131, 145, 170, 236, 238, 240, 247, 249, 261, 263, 297, 301, 328, 332, 565, 568, 570, 610, 640, 759, 762]
    # zero-indexed
    lines_to_fix = [l - 1 for l in lines_to_fix]
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read().split('\n')
        
    # We iterate backwards so line numbers don't shift!
    lines_to_fix.sort(reverse=True)
    
    for l in lines_to_fix:
        if l >= len(content): continue
        line = content[l]
        
        if "{" in line or "}" in line:
            continue
            
        # Match 'if (...) statement;'
        # or 'if (...) ' and the statement is on the next line.
        
        if "if " in line and line.strip().endswith(";"):
            # It's all on one line
            parts = line.split(")")
            if len(parts) >= 2:
                idx = line.rfind(")")
                before = line[:idx+1]
                after = line[idx+1:]
                content[l] = before + " {" + after + " }"
        elif "if " not in line and line.strip().endswith(";"):
            # Statement is on this line, the 'if' was on the line before
            content[l] = "  { " + line.strip() + " }"
            
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(content))

if __name__ == "__main__":
    fix_step1()
