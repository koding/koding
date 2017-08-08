---
layout: "intro"
page_title: "Provision"
sidebar_current: "gettingstarted-provision"
description: |-
  Introduces provisioners that can initialize instances when they're created.
---

# Provision

You're now able to create and modify infrastructure. Now let's see
how to use provisioners to initialize instances when they're created.

If you're using an image-based infrastructure (perhaps with images
created with [Packer](https://www.packer.io)), then what you've
learned so far is good enough. But if you need to do some initial
setup on your instances, then provisioners let you upload files,
run shell scripts, or install and trigger other software like
configuration management tools, etc.

## Defining a Provisioner

To define a provisioner, modify the resource block defining the
"example" EC2 instance to look like the following:

```hcl
resource "aws_instance" "example" {
  ami           = "ami-b374d5a5"
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "echo ${aws_instance.example.public_ip} > ip_address.txt"
  }
}
```

This adds a `provisioner` block within the `resource` block. Multiple
`provisioner` blocks can be added to define multiple provisioning steps.
Terraform supports
[multiple provisioners](/docs/provisioners/index.html),
but for this example we are using the `local-exec` provisioner.

The `local-exec` provisioner executes a command locally on the machine
running Terraform. We're using this provisioner versus the others so
we don't have to worry about specifying any
[connection info](/docs/provisioners/connection.html) right now.

## Running Provisioners

Provisioners are only run when a resource is _created_. They
are not a replacement for configuration management and changing
the software of an already-running server, and are instead just
meant as a way to bootstrap a server. For configuration management,
you should use Terraform provisioning to invoke a real configuration
management solution.

Make sure that your infrastructure is
[destroyed](/intro/getting-started/destroy.html) if it isn't already,
then run `apply`:

```
$ terraform apply
aws_instance.example: Creating...
  ami:           "" => "ami-b374d5a5"
  instance_type: "" => "t2.micro"
aws_eip.ip: Creating...
  instance: "" => "i-213f350a"

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Terraform will output anything from provisioners to the console,
but in this case there is no output. However, we can verify
everything worked by looking at the `ip_address.txt` file:

```
$ cat ip_address.txt
54.192.26.128
```

It contains the IP, just as we asked!

## Failed Provisioners and Tainted Resources

If a resource successfully creates but fails during provisioning,
Terraform will error and mark the resource as "tainted." A
resource that is tainted has been physically created, but can't
be considered safe to use since provisioning failed.

When you generate your next execution plan, Terraform will not attempt to restart
provisioning on the same resource because it isn't guaranteed to be safe. Instead,
Terraform will remove any tainted resources and create new resources, attempting to
provision them again after creation.

Terraform also does not automatically roll back and destroy the resource
during the apply when the failure happens, because that would go
against the execution plan: the execution plan would've said a
resource will be created, but does not say it will ever be deleted.
If you create an execution plan with a tainted resource, however, the
plan will clearly state that the resource will be destroyed because
it is tainted.

## Destroy Provisioners

Provisioners can also be defined that run only during a destroy
operation. These are useful for performing system cleanup, extracting
data, etc.

For many resources, using built-in cleanup mechanisms is recommended
if possible (such as init scripts), but provisioners can be used if
necessary.

The getting started guide won't show any destroy provisioner examples.
If you need to use destroy provisioners, please
[see the provisioner documentation](/docs/provisioners).

## Next

Provisioning is important for being able to bootstrap instances.
As another reminder, it is not a replacement for configuration
management. It is meant to simply bootstrap machines. If you use
configuration management, you should use the provisioning as a way
to bootstrap the configuration management tool.

In the next section, we start looking at [variables as a way to
parameterize our configurations](/intro/getting-started/variables.html).
