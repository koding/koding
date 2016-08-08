<!--[metadata]>
+++
title = "service tasks"
description = "The service tasks command description and usage"
keywords = ["service, tasks"]
advisory = "rc"
[menu.main]
parent = "smn_cli"
+++
<![end-metadata]-->

# service tasks

```Markdown
Usage:	docker service tasks [OPTIONS] SERVICE

List the tasks of a service

Options:
  -a, --all            Display all tasks
  -f, --filter value   Filter output based on conditions provided
      --help           Print usage
      --no-resolve     Do not map IDs to Names
```

Lists the tasks that are running as part of the specified service. This command
has to be run targeting a manager node.


## Examples

### Listing the tasks that are part of a service

The following command shows all the tasks that are part of the `redis` service:

```bash
$ docker service tasks redis
ID                         NAME      SERVICE IMAGE        LAST STATE          DESIRED STATE  NODE
0qihejybwf1x5vqi8lgzlgnpq  redis.1   redis   redis:3.0.6  Running 8 seconds   Running        manager1
bk658fpbex0d57cqcwoe3jthu  redis.2   redis   redis:3.0.6  Running 9 seconds   Running        worker2
5ls5s5fldaqg37s9pwayjecrf  redis.3   redis   redis:3.0.6  Running 9 seconds   Running        worker1
8ryt076polmclyihzx67zsssj  redis.4   redis   redis:3.0.6  Running 9 seconds   Running        worker1
1x0v8yomsncd6sbvfn0ph6ogc  redis.5   redis   redis:3.0.6  Running 8 seconds   Running        manager1
71v7je3el7rrw0osfywzs0lko  redis.6   redis   redis:3.0.6  Running 9 seconds   Running        worker2
4l3zm9b7tfr7cedaik8roxq6r  redis.7   redis   redis:3.0.6  Running 9 seconds   Running        worker2
9tfpyixiy2i74ad9uqmzp1q6o  redis.8   redis   redis:3.0.6  Running 9 seconds   Running        worker1
3w1wu13yuplna8ri3fx47iwad  redis.9   redis   redis:3.0.6  Running 8 seconds   Running        manager1
8eaxrb2fqpbnv9x30vr06i6vt  redis.10  redis   redis:3.0.6  Running 8 seconds   Running        manager1
```


## Filtering

The filtering flag (`-f` or `--filter`) format is a `key=value` pair. If there
is more than one filter, then pass multiple flags (e.g. `--filter "foo=bar" --filter "bif=baz"`).
Multiple filter flags are combined as an `OR` filter. For example,
`-f name=redis.1 -f name=redis.7` returns both `redis.1` and `redis.7` tasks.

The currently supported filters are:

* [id](#id)
* [name](#name)
* [desired-state](#desired-state)


#### ID

The `id` filter matches on all or a prefix of a task's ID.

```bash
$ docker service tasks -f "id=8" redis
ID                         NAME      SERVICE  IMAGE        LAST STATE         DESIRED STATE  NODE
8ryt076polmclyihzx67zsssj  redis.4   redis    redis:3.0.6  Running 4 minutes  Running        worker1
8eaxrb2fqpbnv9x30vr06i6vt  redis.10  redis    redis:3.0.6  Running 4 minutes  Running        manager1
```

#### Name

The `name` filter matches on task names.

```bash
$ docker service tasks -f "name=redis.1" redis
ID                         NAME      SERVICE  IMAGE        DESIRED STATE  LAST STATE         NODE
0qihejybwf1x5vqi8lgzlgnpq  redis.1   redis    redis:3.0.6  Running        Running 8 seconds  manager1
```


#### desired-state

The `desired-state` filter can take the values `running` and `accepted`.


## Related information

* [service create](service_create.md)
* [service inspect](service_inspect.md)
* [service ls](service_ls.md)
* [service rm](service_rm.md)
* [service scale](service_scale.md)
* [service update](service_update.md)
