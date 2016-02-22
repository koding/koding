scripts/sl
==========

Tool for interfacing with Softlayer, implements missing functionality of the original `slcli` tool.

### Usage

Before first usage export Softlayer credentials for your shell session:

```
$ export SOFTLAYER_API_KEY=<?>
$ export SOFTLAYER_USER_NAME=<?>
```

### Datacenters

Example usage of the `-t` template flag.

#### List all datacenters:

```
$ sl datacenter list -t "{{range .}}{{.Name | println}}{{end}}"
ams01
ams03
che01
...
```

#### List details of all datacenters

```
$ sl datacenter list -t "{{json .}}"
[
	{
		"id": 265592,
		"name": "ams01",
...
```
