<!--[metadata]>
+++
title = "Inspect the service"
description = "Inspect the application"
keywords = ["tutorial, cluster management, swarm mode"]
advisory = "rc"
[menu.main]
identifier="inspect-application"
parent="swarm-tutorial"
weight=17
+++
<![end-metadata]-->

# Inspect a service on the swarm

When you have [deployed a service](deploy-service.md) to your swarm, you can use
the Docker CLI to see details about the service running in the swarm.

1. If you haven't already, open a terminal and ssh into the machine where you
run your manager node. For example, the tutorial uses a machine named
`manager1`.

2. Run `docker service inspect --pretty <SERVICE-ID>` to display the details
about a service in an easily readable format.

    To see the details on the `helloworld` service:

    ```
    $ docker service inspect --pretty helloworld

    ID:		9uk4639qpg7npwf3fn2aasksr
    Name:		helloworld
    Mode:		REPLICATED
     Replicas:		1
    Placement:
    UpdateConfig:
     Parallelism:	1
    ContainerSpec:
     Image:		alpine
     Args:	ping docker.com
    ```

    >**Tip**: To return the service details in json format, run the same command
    without the `--pretty` flag.

    ```
    $ docker service inspect helloworld
    [
    {
        "ID": "9uk4639qpg7npwf3fn2aasksr",
        "Version": {
            "Index": 418
        },
        "CreatedAt": "2016-06-16T21:57:11.622222327Z",
        "UpdatedAt": "2016-06-16T21:57:11.622222327Z",
        "Spec": {
            "Name": "helloworld",
            "TaskTemplate": {
                "ContainerSpec": {
                    "Image": "alpine",
                    "Args": [
                        "ping",
                        "docker.com"
                    ]
                },
                "Resources": {
                    "Limits": {},
                    "Reservations": {}
                },
                "RestartPolicy": {
                    "Condition": "any",
                    "MaxAttempts": 0
                },
                "Placement": {}
            },
            "Mode": {
                "Replicated": {
                    "Replicas": 1
                }
            },
            "UpdateConfig": {
                "Parallelism": 1
            },
            "EndpointSpec": {
                "Mode": "vip"
            }
        },
        "Endpoint": {
            "Spec": {}
        }
    }
    ]
    ```

4. Run `docker service tasks <SERVICE-ID>` to see which nodes are running the
service:

    ```
    $ docker service tasks helloworld

    ID                         NAME          SERVICE     IMAGE   LAST STATE         DESIRED STATE  NODE
    8p1vev3fq5zm0mi8g0as41w35  helloworld.1  helloworld  alpine  Running 3 minutes  Running        worker2
    ```

    In this case, the one instance of the `helloworld` service is running on the
    `worker2` node. You may see the service running on your manager node. By
    default, manager nodes in a Swarm can execute tasks just like worker nodes.

    Swarm also shows you the `DESIRED STATE` and `LAST STATE` of the service
    task so you can see if tasks are running according to the service
    definition.

4. Run `docker ps` on the node where the task is running to see details about
the container for the task.

    >**Tip**: If `helloworld` is running on a node other than your manager node,
    you must ssh to that node.

    ```bash
    $docker ps

    CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
    e609dde94e47        alpine:latest       "ping docker.com"   3 minutes ago       Up 3 minutes                            helloworld.1.8p1vev3fq5zm0mi8g0as41w35
    ```

## What's next?

Next, you can [change the scale](scale-service.md) for the service running in
the swarm.
