kloudctl
========


### kloudctl kontrol

Command for reading kite list from kontrol.

*Example usage*

Map kites to AWS instance IDs:

```bash
#!/bin/bash

set -euo pipefail

kontrol-instance-ids() {
  kloudctl kontrol list -t "{{range .}}{{host .URL | println}}{{end}}" | tr '\n' ',' | xargs echo | rev | cut -c 2- | rev |
    while read ips; do
      aws ec2 describe-instances --filter Name=ip-address,Values=$ips;
    done | jq -r '.Reservations[].Instances[].InstanceId'
}
```

Terminate all your EC2 instances built during development:

```bash
$ kontrol-instance-ids | tr '\n' ' ' | xargs aws ec2 terminate-instances --instance-ids
```

### kloudctl team

*TODO(rjeczalik)*

### kloudctl vagrant

*TODO(rjeczalik)*

### kloudctl group

*TODO(rjeczalik)*
