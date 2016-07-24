---
layout: "azurerm"
page_title: "Azure Resource Manager: azurerm_virtual_machine"
sidebar_current: "docs-azurerm-resource-virtualmachine"
description: |-
  Create a Virtual Machine.
---

# azurerm\_virtual\_machine

Create a virtual machine.

## Example Usage

```
resource "azurerm_resource_group" "test" {
    name = "acctestrg"
    location = "West US"
}

resource "azurerm_virtual_network" "test" {
    name = "acctvn"
    address_space = ["10.0.0.0/16"]
    location = "West US"
    resource_group_name = "${azurerm_resource_group.test.name}"
}

resource "azurerm_subnet" "test" {
    name = "acctsub"
    resource_group_name = "${azurerm_resource_group.test.name}"
    virtual_network_name = "${azurerm_virtual_network.test.name}"
    address_prefix = "10.0.2.0/24"
}

resource "azurerm_network_interface" "test" {
    name = "acctni"
    location = "West US"
    resource_group_name = "${azurerm_resource_group.test.name}"

    ip_configuration {
    	name = "testconfiguration1"
    	subnet_id = "${azurerm_subnet.test.id}"
    	private_ip_address_allocation = "dynamic"
    }
}

resource "azurerm_storage_account" "test" {
    name = "accsa"
    resource_group_name = "${azurerm_resource_group.test.name}"
    location = "westus"
    account_type = "Standard_LRS"

    tags {
        environment = "staging"
    }
}

resource "azurerm_storage_container" "test" {
    name = "vhds"
    resource_group_name = "${azurerm_resource_group.test.name}"
    storage_account_name = "${azurerm_storage_account.test.name}"
    container_access_type = "private"
}

resource "azurerm_virtual_machine" "test" {
    name = "acctvm"
    location = "West US"
    resource_group_name = "${azurerm_resource_group.test.name}"
    network_interface_ids = ["${azurerm_network_interface.test.id}"]
    vm_size = "Standard_A0"

    storage_image_reference {
	publisher = "Canonical"
	offer = "UbuntuServer"
	sku = "14.04.2-LTS"
	version = "latest"
    }

    storage_os_disk {
        name = "myosdisk1"
        vhd_uri = "${azurerm_storage_account.test.primary_blob_endpoint}${azurerm_storage_container.test.name}/myosdisk1.vhd"
        caching = "ReadWrite"
        create_option = "FromImage"
    }

    os_profile {
	computer_name = "hostname"
	admin_username = "testadmin"
	admin_password = "Password1234!"
    }

    os_profile_linux_config {
	disable_password_authentication = false
    }
}
```

## Argument Reference

The following arguments are supported:

* `name` - (Required) Specifies the name of the virtual machine resource. Changing this forces a
    new resource to be created.
* `resource_group_name` - (Required) The name of the resource group in which to
    create the virtual machine.
* `location` - (Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
* `plan` - (Optional) A plan block as documented below.
* `availability_set_id` - (Optional) The Id of the Availablity Set in which to create the virtual machine
* `vm_size` - (Required) Specifies the [size of the virtual machine](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-size-specs/).
* `storage_image_reference` - (Optional) A Storage Image Reference block as documented below.
* `storage_os_disk` - (Required) A Storage OS Disk block as referenced below.
* `storage_data_disk` - (Optional) A list of Storage Data disk blocks as referenced below.
* `os_profile` - (Required) An OS Profile block as documented below.
* `os_profile_windows_config` - (Required, when a windows machine) A Windows config block as documented below.
* `os_profile_linux_config` - (Required, when a linux machine) A Linux config block as documented below.
* `os_profile_secrets` - (Optional) A collection of Secret blocks as documented below.
* `network_interface_ids` - (Required) Specifies the list of resource IDs for the network interfaces associated with the virtual machine.

For more information on the different example configurations, please check out the [azure documentation](https://msdn.microsoft.com/en-us/library/mt163591.aspx#Anchor_2)

`Plan` supports the following:

* `name` - (Required) Specifies the name of the image from the marketplace.
* `publisher` - (Optional) Specifies the publisher of the image.
* `product` - (Optional) Specifies the product of the image from the marketplace.

`storage_image_reference` supports the following:

* `publisher` - (Required) Specifies the publisher of the image used to create the virtual machine
* `offer` - (Required) Specifies the offer of the image used to create the virtual machine.
* `sku` - (Required) Specifies the SKU of the image used to create the virtual machine.
* `version` - (Optional) Specifies the version of the image used to create the virtual machine.

`storage_os_disk` supports the following:

* `name` - (Required) Specifies the disk name.
* `vhd_uri` - (Required) Specifies the vhd uri.
* `create_option` - (Required) Specifies how the virtual machine should be created. Possible values are `attach` and `FromImage`.
* `caching` - (Optional) Specifies the caching requirements.

`storage_data_disk` supports the following:

* `name` - (Required) Specifies the name of the data disk.
* `vhd_uri` - (Required) Specifies the uri of the location in storage where the vhd for the virtual machine should be placed.
* `create_option` - (Required) Specifies how the data disk should be created.
* `disk_size_gb` - (Required) Specifies the size of the data disk in gigabytes.
* `lun` - (Required) Specifies the logical unit number of the data disk. 

`os_profile` supports the following:

* `computer_name` - (Optional) Specifies the name of the virtual machine.
* `admin_username` - (Required) Specifies the name of the administrator account.
* `admin_password` - (Required) Specifies the password of the administrator account.
* `custom_data` - (Optional) Specifies a base-64 encoded string of custom data. The base-64 encoded string is decoded to a binary array that is saved as a file on the Virtual Machine. The maximum length of the binary array is 65535 bytes.

`os_profile_windows_config` supports the following:

* `provision_vm_agent` - (Optional)
* `enable_automatic_upgrades` - (Optional)
* `winrm` - (Optional) A collection of WinRM configuration blocks as documented below.
* `additional_unattend_config` - (Optional) An Additional Unattended Config block as documented below.

`winrm` supports the following:

* `protocol` - (Required) Specifies the protocol of listener
* `certificate_url` - (Optional) Specifies URL of the certificate with which new Virtual Machines is provisioned.

`additional_unattend_config` supports the following:

* `pass` - (Required) Specifies the name of the pass that the content applies to. The only allowable value is `oobeSystem`.
* `component` - (Required) Specifies the name of the component to configure with the added content. The only allowable value is `Microsoft-Windows-Shell-Setup`.
* `setting_name` - (Required) Specifies the name of the setting to which the content applies. Possible values are: `FirstLogonCommands` and `AutoLogon`.
* `content` - (Optional) Specifies the base-64 encoded XML formatted content that is added to the unattend.xml file for the specified path and component.

`os_profile_linux_config` supports the following:

* `disable_password_authentication` - (Required) Specifies whether password authentication should be disabled.
* `ssh_keys` - (Optional) Specifies a collection of `key_path` and `key_data` to be placed on the virtual machine.

`os_profile_secrets` supports the following:

* `source_vault_id` - (Required) Specifies the key vault to use.
* `vault_certificates` - (Required, on windows machines) A collection of Vault Certificates as documented below

`vault_certificates` support the following:

* `certificate_url` - (Required) It is the Base64 encoding of a JSON Object that which is encoded in UTF-8 of which the contents need to be `data`, `dataType` and `password`.
* `certificate_store` - (Required, on windows machines) Specifies the certificate store on the Virtual Machine where the certificate should be added to.

## Attributes Reference

The following attributes are exported:

* `id` - The virtual machine ID.