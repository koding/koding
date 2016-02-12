# terraform-provider-vagrant
Vagrant Kite Provider for Terraform

# Usage

Following fields should be passed to use this plugin.

- filePath: Full path of the file for Vagrantfile (required)
- queryString: Kite Query string for finding which klient to send the commands (required)
- provisionData: JSON data encoded as base64 needed for provision Klient inside the box (required)

Optional fields:

- box: Box type of underlying Vagrant machine. By default ubuntu/trusty64.
- hostname: Hostname of the Vagrant machine. Defaults to klient's username.
- memory: Memory(MB) of the underlying Vagrant box (Virtualbox feature). Defaults to 1024.
- cpus: Number of CPU's to be used for the underlying Vagrant box (Virtualbox feature). Defaults to 1.

Advanced optional fields (only use them if you know what you do):

- registerURL: Register URL for the Klient inside the Vagrant box. This is
  computed automatically and assigns itself the PublicIP of that current
  machine. However we might want to change it if the Host machine is not
  accesible to the public network
- kontrolURL: Kontrol URL for the Klient inside the Vagrant box. This is read
  from the kite.key automatically and Klient registers to that Kontrol URl. If
  we pass this field, klient will automatically register itself to this URL
  instead of the from kite.key.
- klientURL: Overwrite URL to get the klient.deb during provisioning of
  the vagrant box.

Computed fields:

- klientHostURL: URL of the Klient inside the Host machine (outside Vagrant).
- klientGuestURL: URL of the Klient inside the Vagrant box.

# Example

```
resource "vagrant_instance" "myfirstvm" {
    filePath = "/home/etc/Vagrantfile"
    queryString = "///////8c396fd6-c91c-4454-45c2-5c461ad32645"
    provisionData = "eyJVc2VybmFtZSI6ImFyc2xhbiIsIkhvc3RuYW1lIjoiYXJzbGFuIiwiR3J"
}
```

or for example change the `memory` or `cpus` fields:

```
resource "vagrant_instance" "myfirstvm" {
    filePath = "/home/arslan/myGoApp/Vagrantfile"
    queryString = "///////8c396fd6-c91c-4454-45c2-5c461ad32645"
    provisionData = "eyJVc2VybmFtZSI6ImFyc2xhbiIsIkhvc3RuYW1lIjoiYXJzbGFuIiwiR3J"

    box = "ubuntu/trusty64"
    cpus = 2
    memory = 2048
}
```

