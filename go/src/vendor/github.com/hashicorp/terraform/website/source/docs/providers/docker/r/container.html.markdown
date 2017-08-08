---
layout: "docker"
page_title: "Docker: docker_container"
sidebar_current: "docs-docker-resource-container"
description: |-
  Manages the lifecycle of a Docker container.
---

# docker\_container

Manages the lifecycle of a Docker container.

## Example Usage

```hcl
# Start a container
resource "docker_container" "ubuntu" {
  name  = "foo"
  image = "${docker_image.ubuntu.latest}"
}

# Find the latest Ubuntu precise image.
resource "docker_image" "ubuntu" {
  name = "ubuntu:precise"
}
```

## Argument Reference

The following arguments are supported:

* `name` - (Required, string) The name of the Docker container.
* `image` - (Required, string) The ID of the image to back this container.
  The easiest way to get this value is to use the `docker_image` resource
  as is shown in the example above.

* `command` - (Optional, list of strings) The command to use to start the
    container. For example, to run `/usr/bin/myprogram -f baz.conf` set the
    command to be `["/usr/bin/myprogram", "-f", "baz.conf"]`.
* `entrypoint` - (Optional, list of strings) The command to use as the
    Entrypoint for the container. The Entrypoint allows you to configure a
    container to run as an executable. For example, to run `/usr/bin/myprogram`
    when starting a container, set the entrypoint to be
    `["/usr/bin/myprogram"]`.
* `user` - (Optional, string) User used for run the first process. Format is
    `user` or `user:group` which user and group can be passed literraly or
    by name.
* `dns` - (Optional, set of strings) Set of DNS servers.
* `dns_opts` - (Optional, set of strings) Set of DNS options used by the DNS provider(s), see `resolv.conf` documentation for valid list of options.
* `dns_search` - (Optional, set of strings) Set of DNS search domains that are used when bare unqualified hostnames are used inside of the container.
* `env` - (Optional, set of strings) Environment variables to set.
* `labels` - (Optional, map of strings) Key/value pairs to set as labels on the
  container.
* `links` - (Optional, set of strings) Set of links for link based
  connectivity between containers that are running on the same host.
* `hostname` - (Optional, string) Hostname of the container.
* `domainname` - (Optional, string) Domain name of the container.
* `restart` - (Optional, string) The restart policy for the container. Must be
  one of "no", "on-failure", "always", "unless-stopped".
* `max_retry_count` - (Optional, int) The maximum amount of times to an attempt
  a restart when `restart` is set to "on-failure"
* `must_run` - (Optional, bool) If true, then the Docker container will be
  kept running. If false, then as long as the container exists, Terraform
  assumes it is successful.
* `capabilities` - (Optional, block) See [Capabilities](#capabilities) below for details.
* `ports` - (Optional, block) See [Ports](#ports) below for details.
* `host` - (Optional, block) See [Extra Hosts](#extra_hosts) below for
  details.
* `privileged` - (Optional, bool) Run container in privileged mode.
* `publish_all_ports` - (Optional, bool) Publish all ports of the container.
* `volumes` - (Optional, block) See [Volumes](#volumes) below for details.
* `memory` - (Optional, int) The memory limit for the container in MBs.
* `memory_swap` - (Optional, int) The total memory limit (memory + swap) for the
  container in MBs. This setting may compute to `-1` after `terraform apply` if the target host doesn't support memory swap, when that is the case docker will use a soft limitation.
* `cpu_shares` - (Optional, int) CPU shares (relative weight) for the container.
* `log_driver` - (Optional, string) The logging driver to use for the container.
  Defaults to "json-file".
* `log_opts` - (Optional, map of strings) Key/value pairs to use as options for
  the logging driver.
* `network_alias` - (Optional, set of strings) Network aliases of the container for user-defined networks only.
* `network_mode` - (Optional, string) Network mode of the container.
* `networks` - (Optional, set of strings) Id of the networks in which the
  container is.
* `destroy_grace_seconds` - (Optional, int) If defined will attempt to stop the container before destroying. Container will be destroyed after `n` seconds or on successful stop.
* `upload` - (Optional, block) See [File Upload](#upload) below for details.

<a id="capabilities"></a>
### Capabilities

`capabilities` is a block within the configuration that allows you to add or drop linux capabilities. For more information about what capabilities you can add and drop please visit the docker run documentation.

* `add` - (Optional, set of strings) list of linux capabilities to add.
* `drop` - (Optional, set of strings) list of linux capabilities to drop.

Example:

```hcl
resource "docker_container" "ubuntu" {
  name = "foo"
  image = "${docker_image.ubuntu.latest}"
  capabilities {
    add = ["ALL"]
    drop = ["SYS_ADMIN"]
  }
}
```

<a id="ports"></a>
### Ports

`ports` is a block within the configuration that can be repeated to specify
the port mappings of the container. Each `ports` block supports
the following:

* `internal` - (Required, int) Port within the container.
* `external` - (Required, int) Port exposed out of the container.
* `ip` - (Optional, string) IP address/mask that can access this port.
* `protocol` - (Optional, string) Protocol that can be used over this port,
  defaults to TCP.

<a id="extra_hosts"></a>
### Extra Hosts

`host` is a block within the configuration that can be repeated to specify
the extra host mappings for the container. Each `host` block supports
the following:

* `host` - (Required, string) Hostname to add.
* `ip` - (Required, string) IP address this hostname should resolve to.

This is equivalent to using the `--add-host` option when using the `run`
command of the Docker CLI.

<a id="volumes"></a>
### Volumes

`volumes` is a block within the configuration that can be repeated to specify
the volumes attached to a container. Each `volumes` block supports
the following:

* `from_container` - (Optional, string) The container where the volume is
  coming from.
* `host_path` - (Optional, string) The path on the host where the volume
  is coming from.
* `volume_name` - (Optional, string) The name of the docker volume which
  should be mounted.
* `container_path` - (Optional, string) The path in the container where the
  volume will be mounted.
* `read_only` - (Optional, bool) If true, this volume will be readonly.
  Defaults to false.

One of `from_container`, `host_path` or `volume_name` must be set.

<a id="upload"></a>
### File Upload

`upload` is a block within the configuration that can be repeated to specify
files to upload to the container before starting it.
Each `upload` supports the following

* `content` - (Required, string) A content of a file to upload.
* `file` - (Required, string) path to a file in the container.

## Attributes Reference

The following attributes are exported:

 * `ip_address` - The IP address of the container as read from its
   NetworkSettings.
 * `ip_prefix_length` - The IP prefix length of the container as read from its
   NetworkSettings.
 * `gateway` - The network gateway of the container as read from its
   NetworkSettings.
 * `bridge` - The network bridge of the container as read from its
   NetworkSettings.
