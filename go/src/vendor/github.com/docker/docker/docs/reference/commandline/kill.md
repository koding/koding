<!--[metadata]>
+++
title = "kill"
description = "The kill command description and usage"
keywords = ["container, kill, signal"]
[menu.main]
parent = "smn_cli"
+++
<![end-metadata]-->

# kill

```markdown
Usage:  docker kill [OPTIONS] CONTAINER [CONTAINER...]

Kill one or more running container

Options:
      --help            Print usage
  -s, --signal string   Signal to send to the container (default "KILL")
```

The main process inside the container will be sent `SIGKILL`, or any
signal specified with option `--signal`.

> **Note:**
> `ENTRYPOINT` and `CMD` in the *shell* form run as a subcommand of `/bin/sh -c`,
> which does not pass signals. This means that the executable is not the container’s PID 1
> and does not receive Unix signals.
