import sys
import json
import csv

bindings = json.load(sys.stdin)
writer = csv.writer(sys.stdout)
keys_sorted = ['name', 'description', 'binding', 'readonly', 'enabled', 'hidden', 'options']
writer.writerow(keys_sorted)

for b in bindings:
  row = list()
  for k in keys_sorted:
    row.append(b[k])
  writer.writerow(row)
