<!--[metadata]>
+++
title = "Drain a node"
description = "Drain nodes on the Swarm"
keywords = ["tutorial, cluster management, swarm, service, drain"]
advisory="rc"
[menu.main]
identifier="swarm-tutorial-drain-node"
parent="swarm-tutorial"
weight=21
+++
<![end-metadata]-->

# Drain a node on the swarm

In earlier steps of the tutorial, all the nodes have been running with `ACTIVE`
availability. The swarm manager can assign tasks to any `ACTIVE` node, so up to
now all nodes have been available to receive tasks.

Sometimes, such as planned maintenance times, you need to set a node to `DRAIN`
availability. `DRAIN` availability  prevents a node from receiving new tasks
from the swarm manager. It also means the manager stops tasks running on the
node and launches replica tasks on a node with `ACTIVE` availability.

1. If you haven't already, open a terminal and ssh into the machine where you
run your manager node. For example, the tutorial uses a machine named
`manager1`.

2. Verify that all your nodes are actively available.

    ```bash
    $ docker node ls

    ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
    1bcef6utixb0l0ca7gxuivsj0    worker2   Ready   Active
    38ciaotwjuritcdtn9npbnkuz    worker1   Ready   Active
    e216jshn25ckzbvmwlnh5jr3g *  manager1  Ready   Active        Leader
    ```

3. If you aren't still running the `redis` service from the [rolling
update](rolling-update.md) tutorial, start it now:

    ```bash
    $ docker service create --replicas 3 --name redis --update-delay 10s redis:3.0.6

    c5uo6kdmzpon37mgj9mwglcfw
    ```

4. Run `docker service tasks redis` to see how the Swarm manager assigned the
tasks to different nodes:

    ```bash
    $ docker service tasks redis

    ID                         NAME     SERVICE  IMAGE        LAST STATE          DESIRED STATE  NODE
    7q92v0nr1hcgts2amcjyqg3pq  redis.1  redis    redis:3.0.6  Running 26 seconds  Running        manager1
    7h2l8h3q3wqy5f66hlv9ddmi6  redis.2  redis    redis:3.0.6  Running 26 seconds  Running        worker1
    9bg7cezvedmkgg6c8yzvbhwsd  redis.3  redis    redis:3.0.6  Running 26 seconds  Running        worker2
    ```

    In this case the swarm manager distributed one task to each node. You may
    see the tasks distributed differently among the nodes in your environment.

5. Run `docker node update --availability drain <NODE-ID>` to drain a node that
had a task assigned to it:

    ```bash
    docker node update --availability drain worker1

    worker1
    ```

6. Inspect the node to check its availability:

    ```bash
    $ docker node inspect --pretty worker1

    ID:			38ciaotwjuritcdtn9npbnkuz
    Hostname:		worker1
    Status:
     State:			Ready
     Availability:		Drain
    ...snip...
    ```

    The drained node shows `Drain` for `AVAILABILITY`.

7. Run `docker service tasks redis` to see how the Swarm manager updated the
task assignments for the `redis` service:

    ```bash
    $ docker service tasks redis

    ID                         NAME     SERVICE  IMAGE        LAST STATE              DESIRED STATE  NODE
    7q92v0nr1hcgts2amcjyqg3pq  redis.1  redis    redis:3.0.6  Running 4 minutes       Running        manager1
    b4hovzed7id8irg1to42egue8  redis.2  redis    redis:3.0.6  Running About a minute  Running        worker2
    9bg7cezvedmkgg6c8yzvbhwsd  redis.3  redis    redis:3.0.6  Running 4 minutes       Running        worker2
    ```

    The Swarm manager maintains the desired state by ending the task on a node
    with `Drain` availability and creating a new task on a node with `Active`
    availability.

8. Run  `docker node update --availability active <NODE-ID>` to return the
drained node to an active state:

    ```bash
    $ docker node update --availability active worker1

    worker1
    ```

9. Inspect the node to see the updated state:

   ```bash
   $ docker node inspect --pretty worker1

   ID:			38ciaotwjuritcdtn9npbnkuz
   Hostname:		worker1
   Status:
    State:			Ready
    Availability:		Active
  ...snip...
  ```

  When you set the node back to `Active` availability, it can receive new tasks:

  * during a service update to scale up
  * during a rolling update
  * when you set another node to `Drain` availability
  * when a task fails on another active node
