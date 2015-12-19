# terraform-provider-vagrantkite
Vagrant Kite Provider for Terraform

# Usage

Following fields should be passed to use this plugin.

- filePath: Full path of the file for Vagrantfile (required)
- queryString: Kite Query string for finding which klient to send the commands (required)

Optional fields:

- box: Box type of underlying Vagrant machine. By default ubuntu/trusty64
- hostname: Hostname of the Vagrant machine. Defaults to klient's username
- memory: Memory(MB) of the underlying Vagrant box. Defaults to 1024
- cpus: Number of CPU's to be used for the underlying Vagrant box. Defaults to 1

# Example

```
resource "vagrantkite_build" "myfirstvm" {
    filePath = "/home/etc/Vagrantfile"
    queryString = "///////8c396fd6-c91c-4454-45c2-5c461ad32645"
}
```

or

```
resource "vagrantkite_build" "myfirstvm" {
    filePath = "/home/arslan/myGoApp/Vagrantfile"
    queryString = "///////8c396fd6-c91c-4454-45c2-5c461ad32645"
	box = "ubuntu/trusty64"
	cpus = 2
	memory = 2048
}
```
