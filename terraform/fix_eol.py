p = 'main.tf'
with open(p, 'rb') as f:
    s = f.read()
new = s.replace(b'\r\n', b'\n')
with open(p, 'wb') as f:
    f.write(new)
print('converted')
