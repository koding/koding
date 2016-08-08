<!--[metadata]>
+++
title = "node demote"
description = "The node demote command description and usage"
keywords = ["node, demote"]
[menu.main]
parent = "smn_cli"
+++
<![end-metadata]-->

# node demote

```markdown
Usage:  docker node demote NODE [NODE...]

Demote a node from manager in the swarm

Options:
      --help   Print usage

```

Demotes an existing manager so that it is no longer a manager. This command targets a docker engine that is a manager in the swarm cluster.


```bash
$ docker node demote <node name>
```

## Related information

* [node promote](node_promote.md)
