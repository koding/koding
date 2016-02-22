Softlayer
=========

# Tools

- `sl` (managing VLANs) - [koding/kites/kloud/scripts/sl](./go/src/koding/kites/kloud/scripts/sl)
- `kloudctl` (managing machines) - [koding/kites/kloud/kloudctl](./go/src/koding/kites/kloud/kloudctl)
- `images` (managing base images) - [README.md](./go/src/koding/kites/kloud/docs/ami-creation.md#updating-softlayer-base-image)
- - official `slcli` (everything else) - http://softlayer-python.readthedocs.org/en/latest/install.html

# Prerequisites

```bash
~ $ cd ${KODING_REPO}
koding $ export GOPATH=${PWD}/go
koding $ export PATH=${GOPATH}/bin:${PATH}
```

## Installation

- sl

```bash
koding $ go install koding/kites/kloud/scripts/sl
```

- kloudctl
```bash
koding $ go install koding/kites/kloud/kloudctl
```

## Environment variables

```bash
koding $ cat >> ~/.bashrc <<EOF
export SOFTLAYER_API_KEY="#{slKeys.vm_kloud.apiKey}"
export SOFTLAYER_USER_NAME="#{slKeys.vm_kloud.username}"
export KLOUDCTL_MONGODB_URL="#{mongo}";
# export KLOUDCTL_DEBUG="1";
export KITE_KONTROL_URL="https://koding.com/kontrol/kite";
export KITE_ENVIRONMENT=production
EOF
```

- slKeys.vm_kloud - https://github.com/koding/credential/blob/6faa820/config/main.prod.coffee#L11-L12
- mongo - https://github.com/koding/credential/blob/6faa820/config/main.prod.coffee#L82

# Getting started

## Checking machine

### via MongoDB

```bash
mongo> db.jMachines.find({"credential": "rjeczalik", "slug": "softlayer-vm-0"}, {"domain": 1, "ipAddress": 1, "status.state": 1, "_id": 0})
```
```json
{
  "domain": "urkseca4aeee.rjeczalik.koding.io",
  "ipAddress": "169.54.128.8",
  "status": {
    "state": "Running"
  }
}
```

### via kloudctl

```bash
koding $ ./kloudctl group create -dry -users rjeczalik
```
```
Preparing jMachine documents for users...
0 to be machines built
1 error(s) occurred:

* jMachine status for "rjeczalik": the machine is already running
nothing to build
```

Querying multiple users at once:

```bash
koding $ cat >userlist.txt <<EOF
caikoding
cihangirsavas
devrim
dicle
didemacet
fatihacet
gokmen
leeolayvar
mehmet
nitin
ozan
rjeczalik
selin
senthil
sent-hil
sinan
sonmez
stefan
stefanbc
szkl
tpiha
turunc
umut
usirin
EOF
```
```bash
koding $ cat userlist.txt | kloudctl group create -dry -users -
```
```bash
Preparing jMachine documents for users...
0 to be machines built
24 error(s) occurred:

* jMachine status for "cihangirsavas": the machine is already running
* jMachine status for "devrim": the machine is already running
* jMachine status for "didemacet": the machine is already running
* jMachine status for "fatihacet": the machine is already running
* jMachine status for "ozan": the machine is already running
* jMachine status for "senthil": the machine is already running
* jMachine status for "stefanbc": the machine is already running
* jMachine status for "usirin": the machine is already running
* jMachine status for "dicle": the machine is already running
* jMachine status for "gokmen": the machine is already running
* jMachine status for "mehmet": the machine is already running
* jMachine status for "nitin": the machine is already running
* jMachine status for "selin": the machine is already running
* jMachine status for "stefan": the machine is already running
* jMachine status for "caikoding": the machine is already running
* jMachine status for "gokhan": this is going to be rebuild without -dry
* jMachine status for "leeolayvar": the machine is already running
* jMachine status for "sonmez": the machine is already running
* jMachine status for "szkl": the machine is already running
* jMachine status for "cihangir": the machine is already running
* jMachine status for "sent-hil": the machine is already running
* jMachine status for "sinan": the machine is already running
* jMachine status for "turunc": the machine is already running
* jMachine status for "umut": the machine is already running
nothing to build
```

### via Softlayer

```bash
~ $ slcli vm list --tag koding-user:rjeczalik
```
```bash
:..........:...........:..............:................:............:........:
:    id    :  hostname :  primary_ip  :   backend_ip   : datacenter : action :
:..........:...........:..............:................:............:........:
: 16109405 : rjeczalik : 169.54.128.8 : 10.122.209.232 :   sjc01    :   -    :
:..........:...........:..............:................:............:........:
```

Available tags:

- `koding-user:<jMachines.credential>`
- `koding-env:<environment>`
- `koding-machineid:<jMachines.ObjectId>`
- `koding-domain:<jMachines.domain>`

### via SSH

```bash
~ $ export USER_IP=$(slcli vm list --tag koding-user:rjeczalik | tr -s ' ' | cut -d' ' -f3)
~ $ ssh -i $KLOUD_RSA_PEM root@$USER_IP
```
```bash
Welcome to Ubuntu 14.04.3 LTS (GNU/Linux 3.13.0-74-generic x86_64)

 * Documentation:  https://help.ubuntu.com/
Last login: Fri Feb 19 12:40:54 2016 from 89-67-178-12.dynamic.chello.pl
This virtual hackathon is powered by...

  _____ ____  __  __    _____ _                 _
 |_   _|  _ \|  \/  |  / ____| |               | |
   | | | |_) | \  / | | |    | | ___  _   _  __| |
   | | |  _ <| |\/| | | |    | |/ _ \| | | |/ _` |
  _| |_| |_) | |  | | | |____| | (_) | |_| | (_| |
 |_____|____/|_|  |_|  \_____|_|\___/ \__,_|\__,_| SoftLayer

root: ~ $ 
```

### via Klient Kite

```bash
~ $ export USER_IP=$(slcli vm list --tag koding-user:rjeczalik | tr -s ' ' | cut -d' ' -f3)
~ $ curl $USER_IP:56789/kite
```
```bash
Welcome to SockJS!
```

## Creating a machine

### Production datacenters / VLANs

Before creating machine we need to determine in which datacenter it will run. Finding a datacenter basically means finding a VLAN which has spare capacity. Each single VLAN has capacity of ~250 VMs by default (it can be slightly increased by Softlayer Team on demand, but rather don't count on that).

We don't care about VLANs which are untagged, but are attached to our account.

In order to list production VLANs use `sl` tool. Each VLAN has two tags:

- `koding-env`, either production, dev, sandbox etc. if kloud runs in production in won't see VLANs tagged other than production
- `koding-vlan-cap`, set to 250 for each VLAN, based on this value kloud will balance machines among all vlans for the given datacenter

```bash
koding $ sl vlan list
```bash
ID            Internal ID	Total	Available	Instances	Datacenter	Tags
1172807	1443		0	0		1		par01		[koding-vlan-cap=250,koding-env=production]
1171871	1366		64	61		207		sjc01		[koding-vlan-cap=250,koding-env=production]
1171873	1400		64	61		208		sjc01		[koding-env=production,koding-vlan-cap=250]
1171875	1407		64	61		204		sjc01		[koding-env=production,koding-vlan-cap=250]
1171877	1410		64	61		204		sjc01		[koding-env=production,koding-vlan-cap=250]
1171879	1417		64	61		201		sjc01		[koding-env=production,koding-vlan-cap=250]
1171881	1418		64	61		200		sjc01		[koding-env=production,koding-vlan-cap=250]
1171883	1420		64	61		201		sjc01		[koding-vlan-cap=250,koding-env=production]
1171885	1425		64	61		134		sjc01		[koding-vlan-cap=250,koding-env=production]
1171487	1872		64	61		1		tok02		[koding-vlan-cap=250,koding-env=production]
1171483	1518		64	61		233		wdc04		[koding-env=production,koding-vlan-cap=250]
1171489	1772		64	61		232		wdc04		[koding-vlan-cap=250,koding-env=production]
1171491	1773		64	61		226		wdc04		[koding-env=production,koding-vlan-cap=250]
1171497	1774		64	61		232		wdc04		[koding-env=production,koding-vlan-cap=250]
1171499	1775		64	61		225		wdc04		[koding-env=production,koding-vlan-cap=250]
1171501	1776		64	61		242		wdc04		[koding-env=production,koding-vlan-cap=250]
1171503	1777		64	61		237		wdc04		[koding-vlan-cap=250,koding-env=production]
1171505	1778		64	61		225		wdc04		[koding-env=production,koding-vlan-cap=250]
1171507	1779		64	61		230		wdc04		[koding-env=production,koding-vlan-cap=250]
1171509	1780		64	61		234		wdc04		[koding-env=production,koding-vlan-cap=250]
1171511	1781		64	61		226		wdc04		[koding-env=production,koding-vlan-cap=250]
1171513	1782		64	61		228		wdc04		[koding-vlan-cap=250,koding-env=production]
1171859	1206		0	0		318		sjc03		[koding-env=production,koding-vlan-cap=250]
1171861	1229		0	0		361		sjc03		[koding-vlan-cap=250,koding-env=production]
1171863	1235		0	0		318		sjc03		[koding-env=production,koding-vlan-cap=250]
1171865	1236		0	0		315		sjc03		[koding-vlan-cap=250,koding-env=production]
1171835	1251		0	0		256		dal09		[koding-env=production,koding-vlan-cap=250]
1171837	1252		0	0		256		dal09		[koding-env=production,koding-vlan-cap=250]
1171839	1253		0	0		249		dal09		[koding-env=production,koding-vlan-cap=250]
1171841	1254		0	0		252		dal09		[koding-env=production,koding-vlan-cap=250]
1171843	1255		0	0		257		dal09		[koding-vlan-cap=250,koding-env=production]
1171845	1256		0	0		250		dal09		[koding-vlan-cap=250,koding-env=production]
1171847	1257		0	0		353		dal09		[koding-env=production,koding-vlan-cap=250]
1171849	1258		0	0		248		dal09		[koding-vlan-cap=250,koding-env=production]
```

From the above list we see most of the datacenters are pretty crowded, some overprovisionned, but `sjc01` looks like it have the most spare capacity.

[The kloudctl directory](https://github.com/koding/koding/tree/c60ba0ff/go/src/koding/kites/kloud/kloudctl) contains template files for each datacenter we have vlans in:

- `hackathon-dal09.json` for dal09
- `hackathon-sjc03.json` for sjc03
- `hackathon-wdc04.json` for wdc04
- `hackathon-sjc01.json` for sjc01

Creating machine for user:

```bash
koding $ kloudctl group create -f hackathon-sjc01.json -users rjeczalik
```
```bash
Preparing jMachine documents for users...
1 machine to be built
Requesting to process "softlayer-vm-0"
watching status for "56c766e8bc09c90729ffb7b9"
2016-02-19 19:03:05.6797201 +0000 UTC: status for "56c766e8bc09c90729ffb7b9": Building
2016-02-19 19:03:20.554644929 +0000 UTC: status for "56c766e8bc09c90729ffb7b8": Building
2016-02-19 19:03:20.766824502 +0000 UTC: status for "56c766e8bc09c90729ffb7b9": Building
2016-02-19 19:03:35.850424965 +0000 UTC: status for "56c766e8bc09c90729ffb7b8": Building
2016-02-19 19:03:35.933874654 +0000 UTC: status for "56c766e8bc09c90729ffb7b9": Building
2016-02-19 19:03:51.02228675 +0000 UTC: status for "56c766e8bc09c90729ffb7b9": Building
...
```

After the machine is successfully built, it's invisible to a user. Attaching it to the user's stack will make it visible:

```bash
koding $ kloudctl group stack -users rjeczalik -machine 'softlayer-vm-0'
```
```bash
processing 1 users...
processed "rjeczalik" user stack
```

The same commands, but for scale:

```bash
koding $ cat userlist.txt | kloudctl group create -f hackathon-sjc01.json -t 20 -users -
koding $ # 20 concurrent builds is a safe and tested value
```
```bash
koding $ cat userlist.txt | kloudctl group stack -machine 'softlayer-vm-0' -j 64 -users -
koding $ # 64 concurrent processings is a safe and tested value
```

## Deleting a machine

- we would want to modify a jMachine document when:
  - building a machine failed and rebuilding it again fails on kloud
  - when jMachine.meta.id is missing or is some bad value (0 is bad value here)
  - when jMachine.meta.vlanId is some bad value (0 is ok for vlanId - it means: kloud please autobalance me), which causes failures on rebuild
- we would want to delete a Softlayer machine when it's dead broken and we want to make a room for more

### MongoDB

Helper scripts:

- gives a jMachine.ObjectId given the username (and optionally machine slug)

```bash
prod-find-machine() { 
    local usr=${1:-rjeczalik};
    local slug=${2:-softlayer-vm-0};
    ( mongo -u user -p password host:port/database 2> /dev/null | tail -n+3 | sed '$ d' ) <<< "db.jMachines.find({\"credential\": \"$usr\", \"slug\": \"$slug\"}, {\"_id\": 1})" | tr -d ' ' | cut -d\" -f4
}
```
```bash
~ $ prod-find-machine rjeczalik softlayer-vm-0
56c6673abc09c91ab3e9f0bd
```

- gives a jUsers.ObjectId given the jUsers.Username

```bash
prod-find-user() { 
    local usr=${1:-rjeczalik};
    ( mongo -u user -p password host:port/database 2> /dev/null | tail -n+3 | sed '$ d' ) <<< "db.jAccounts.find({\"profile.nickname\": \"$usr\"}, {\"_id\": 1})" | tr -d ' ' | cut -d\" -f4
}
```
```bash
~ $ prod-find-user rjeczalik
530c63a19e4dc2247000e798
```

- gives a jUsers.Username given the jUsers.ObjectId

```bash
prod-revfind-user() { 
    local id=${1};
    ( mongo -u user -p password host:port/database 2> /dev/null | tail -n+3 | sed '$ d' ) <<< "db.jUsers.find({\"_id\": ObjectId(\"$id\")}, {\"username\": 1, \"_id\": 0})" | jq -r .username
}
```
```bash
~ $ prod-revfind-user 530c63a19e4dc2247000e798
rjeczalik
```

- deletes a jMachine document given the jMachines.ObjectId

```bash
prod-del-machine () { 
    local id=${1:-};
    if [[ -z "${id}" ]]; then
        echo "arg is empty" 2>&1;
        return 1;
    fi;
    ( mongo -u user -p password host:port/database 2> /dev/null | tail -n+3 | sed '$ d' ) <<< "db.jMachines.remove({\"_id\": ObjectId(\"${id}\")})"
}
```
```bash
~ $ prod-del-machine 56c6673abc09c91ab3e9f0bd
Cannot use commands write mode, degrading to compatibility mode
WriteResult({ "nRemoved" : 1 })
```

### Softlayer

```bash
~ $ slcli vm list --tag koding-user:rjeczalik | tr -s ' ' | cut -d' ' -f1
16109405
```
```bash
~ $ slcli vm cancel 16109405 <<< 16109405
```

# Known issues

- multiple `softlayer-vm-0`

Early `kloudctl` version had a race problem which might created a duplicated `softlayer-vm-0` (all of the duplicates are removed now). If user has multiple machines with the same slug/label, the UI won't work. Solution is to determinate which machine is running for the user and has a valid jMachine document (matching `jMachines.ipAddress` etc.) and delete the other ones (both jMachine and Softlayer vm).

To detect the probem:

```bash
~ $ prod-find-machine rjeczalik softlayer-vm-0
56c6673abc09c91ab3e9f0bd
54c6233abc09c91ab3e9e421
```

If the `54c6233abc09c91ab3e9e421` is the running machine, delete the other one:

```bash
~ $ slcli vm list --tag koding-machineid:56c6673abc09c91ab3e9f0bd | tr -s ' ' | cut -d' ' -f1
16109639
```
```bash
~ $ slcli vm cancel 16109639 <<< 16109639
```
```bash
~ $ prod-del-machine 56c6673abc09c91ab3e9f0bd
```
