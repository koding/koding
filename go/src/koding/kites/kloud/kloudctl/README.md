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

Export MongoDB DSN, e.g.:

```bash
$ export KLOUDCTL_MONGODB_URL=127.0.0.1:27017
```

Create a softlayer machine, hiding it from the user:

```bash
$ kloudctl group create -f hackathon-sjc01 -users rafal -nostack
```

Make the machine visible:

```bash
$ kloudctl group stack -users rafal -machine softlayer-vm-0
```

Hide it again:

```bash
$ kloudctl group stack -users rafal -machine softlayer-vm-0 -rm
```

Debug kite communication / events:

```bash
$ kloudctl group -debug create -f hackathon-sjc01 -users rafal -nostack
```

Create thousands machines at once with at most 20 vm being created at a time (throttling):

```bash
$ cat >usernames.txt <<EOF
user-1
user-2
...
user-n
EOF
```
```bash
$ cat usernames.txt | kloudctl group create -f hackathon-sjc01 -users - -nostack -t 20
```
