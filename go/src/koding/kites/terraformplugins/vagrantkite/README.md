# terraform-provider-vagrantkite
Vagrant Kite Provider for Terraform

# Usage

Following fields should be passed to use this plugin.

- filePath: Full path of the file for Vagrantfile
- queryString: Kite Query string for finding which klient to send the commands
- vagrantFile: Content of the Vagrantfile that will be used while creating the vagrant machine

# Example

```
resource "vagrantkite_build" "myfirstvm" {
    filePath = "/home/etc/Vagrantfile"
    queryString = "///////8c396fd6-c91c-4454-45c2-5c461ad32645"
    vagrantFile = "foobar"
}
```
