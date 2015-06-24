---
layout: "docs"
page_title: "Provisioner Connections"
sidebar_current: "docs-provisioners-connection"
description: |-
  Many provisioners require access to the remote resource. For example, a provisioner may need to use SSH or WinRM to connect to the resource.
---

# Provisioner Connections

Many provisioners require access to the remote resource. For example,
a provisioner may need to use SSH or WinRM to connect to the resource.

Terraform uses a number of defaults when connecting to a resource, but these
can be overridden using `connection` block in either a `resource` or `provisioner`.
Any `connection` information provided in a `resource` will apply to all the
provisioners, but it can be scoped to a single provisioner as well. One use case
is to have an initial provisioner connect as root to setup user accounts, and have
subsequent provisioners connect as a user with more limited permissions.

## Example usage

```
# Copies the file as the root user using SSH
provisioner "file" {
    source = "conf/myapp.conf"
    destination = "/etc/myapp.conf"
    connection {
        user = "root"
        password = "${var.root_password}"
    }
}

# Copies the file as the Administrator user using WinRM
provisioner "file" {
    source = "conf/myapp.conf"
    destination = "C:/App/myapp.conf"
    connection {
        type = "winrm"
        user = "Administrator"
        password = "${var.admin_password}"
    }
}
```

## Argument Reference

**The following arguments are supported by all connection types:**

* `type` - The connection type that should be used. Valid types are "ssh" and "winrm"
  This defaults to "ssh".

* `user` - The user that we should use for the connection. Defaults to "root" when
  using type "ssh" and defaults to "Administrator" when using type "winrm".

* `password` - The password we should use for the connection. In some cases this is
  provided by the provider.

* `host` - The address of the resource to connect to. This is provided by the provider.

* `port` - The port to connect to. Defaults to 22 when using type "ssh" and defaults
  to 5985 when using type "winrm".

* `timeout` - The timeout to wait for the connection to become available. This defaults
  to 5 minutes. Should be provided as a string like "30s" or "5m".

* `script_path` - The path used to copy scripts to meant for remote execution.

**Additional arguments only supported by the "ssh" connection type:**

* `key_file` - The SSH key to use for the connection. This takes preference over the
  password if provided.

* `agent` - Set to true to enable using ssh-agent to authenticate.

**Additional arguments only supported by the "winrm" connection type:**

* `https` - Set to true to connect using HTTPS instead of HTTP.

* `insecure` - Set to true to not validate the HTTPS certificate chain.

* `cacert` - The CA certificate to validate against.
