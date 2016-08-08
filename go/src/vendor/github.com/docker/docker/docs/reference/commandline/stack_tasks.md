<!--[metadata]>
+++
title = "stack tasks"
description = "The stack tasks command description and usage"
keywords = ["stack, tasks"]
advisory = "experimental"
[menu.main]
parent = "smn_cli"
+++
<![end-metadata]-->

# stack tasks (experimental)

```markdown
Usage:  docker stack tasks [OPTIONS] STACK

List the tasks in the stack

Options:
  -a, --all            Display all tasks
  -f, --filter value   Filter output based on conditions provided
      --help           Print usage
      --no-resolve     Do not map IDs to Names
```

Lists the tasks that are running as part of the specified stack. This
command has to be run targeting a manager node.

## Filtering

The filtering flag (`-f` or `--filter`) format is a `key=value` pair. If there
is more than one filter, then pass multiple flags (e.g. `--filter "foo=bar" --filter "bif=baz"`).
Multiple filter flags are combined as an `OR` filter. For example,
`-f name=redis.1 -f name=redis.7` returns both `redis.1` and `redis.7` tasks.

The currently supported filters are:

* [id](#id)
* [name](#name)
* [desired-state](#desired-state)

## Related information

* [stack config](stack_config.md)
* [stack deploy](stack_deploy.md)
* [stack rm](stack_rm.md)
* [stack services](stack_services.md)
