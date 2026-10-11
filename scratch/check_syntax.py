import re

path = r'e:\kurichiyar matrimony\lib\features\auth_splash\widgets\guest_public_hub_tab.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

# remove strings and comments
clean = re.sub(r'\"(\\.|[^\"])*\"|\'(\\.|[^\'])*\'|//.*|/\*.*?\*/', '', code, flags=re.DOTALL)
pairs = {'(': ')', '{': '}', '[': ']'}
stack = []
for i, char in enumerate(clean):
    if char in pairs:
        stack.append((char, i))
    elif char in pairs.values():
        if not stack:
            print(f'Unmatched closing {char} at {i}')
            break
        last, pos = stack.pop()
        if pairs[last] != char:
            print(f'Mismatched {last} at {pos} with {char} at {i}')
            break
else:
    if stack:
        print(f'Unclosed {stack[-1]}')
    else:
        print('guest_public_hub_tab.dart is 100% PERFECTLY BALANCED!')
