# Using Azure with `pkgcloud`

* [Using Compute](#using-compute)
  * [Prerequisites](#compute-prerequisites)
* [Using Storage](#using-storage)
  * [Prerequisites](#storage-prerequisites)
* [Certificates](#azure-manage-cert)
  * [Azure Management Certificates](#azure-manage-cert)
  * [Azure SSH Certificates](#azure-ssh-cert)
* [Using Databases](#using-databases)

<a name="using-compute"></a>
## Using Compute

``` js
var pkgcloud = require('../../lib/pkgcloud'),
  fs = require('fs'),
  client,
  options;

//
// Create a pkgcloud compute instance
//
options = {
  provider: 'azure',
  "storageAccount": "test-storage-account",
  "storageAccessKey": "test-storage-access-key",
  "subscriptionId": "azure-account-subscription-id",
  key: fs.readFileSync('path to your account management key file', 'ascii'),
  cert: fs.readFileSync('path to your account management certificate pem file', 'ascii')
};
client = pkgcloud.compute.createClient(options);

//
// Create a server.
// This may take several minutes.
//
options = {
  // pkgcloud compute properties
  name:  'pkgcloud-test',   // name of the server
  flavor: 'ExtraSmall',     // sazure vm size
  image: '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS63DEC20121220', // OS Image

  // Azure vm properties
  location:  'East US',       // Azure location for server
  username:  'pkgcloud',      // Username for server
  password:  'Pkgcloud!!',    // Password for server

  // Azure linux SSH properties
  ssh: {
    cert: fs.readFileSync('path to your ssh pem file', 'ascii')
  },

  // Azure ports (endpoints)
  ports: [
    {
      name : "foo",             // name of port
      protocol : "tcp",         // tcp or udp
      port: "12333",           	// external port number
      localPort: "12333"       	// internal port number
    }
  ]
};

console.log("creating server...");

client.createServer(options, function (err, server) {
  if (err) {
    console.log(err);
  } else {
    // Wait for the server to reach the RUNNING state.
    // This may take several minutes.
    console.log("waiting for server RUNNING state...");
    server.setWait({ status: server.STATUS.running }, 10000, function (err, server) {
      if (err) {
        console.log(err);
      } else {
        console.dir(server);
      }
    });
  }
});



```

<a name="compute-prerequisites"></a>
### Compute Prerequisites

1. Create a [Azure Management Certificate](#azure-manage-cert).
2. Upload the management .cer file to the [Management Certificates](https://manage.windowsazure.com/#Workspace/AdminTasks/ListManagementCertificates) section of the Azure portal. 
3. Specify the location of the management .pem file in the cert field.
4. Specify the location of the management .key file in the key field.
5. Create a [Storage Account](https://manage.windowsazure.com/#Workspace/StorageExtension/storage) if one does not already exist. Storage accounts and Azure VMs will need to be in the same Azure location (East US, West US, etc.).
6. Obtain the Storage Account name and access key from the [Azure Portal](https://manage.windowsazure.com/#Workspace/StorageExtension/storage). Click on 'Manage Keys' to view Storage account name and access key.
7. Specify the Storage account name and access key in the storageAccount and storageAccessKey fields.
8. Create a [Azure SSH Certificate](#azure-ssh-cert) if you will be creating a Linux VM. Specify the path to the certificate pem file in the ssh.cert field. If you used a password when creating the SSH certificate pem file, place the password in the ssh.password field.

<br/>
<a name="using-storage"></a>
## Using Storage

``` js
  var azure = pkgcloud.storage.createClient({
    provider: 'azure',
    storageAccount: "test-storage-account",			// Name of your storage account
    storageAccessKey: "test-storage-access-key" // Access key for storage account
  });
```

<a name="storage-prerequisites"></a>
### Storage Prerequisites

1. Azure storage account must already exist. 
2. Storage account must be in same Azure location as compute servers (East US, West US, etc.). 
3. `storageAccount` and `storageAccessKey` are obtained from the [Storage](https://manage.windowsazure.com/#Workspace/StorageExtension/storage) section of the Azure Portal.

<br/>
<a name="all-azure-options"></a>
## All Azure Options

**Azure Account Settings**

* `storageAccount`: Azure storage account must already exist. Storage account must be in same Azure location as compute servers (East US, West US, etc.). storageAccount name is obtained from the Storage section of the [Azure Portal](https://manage.windowsazure.com/#Workspace/StorageExtension/storage).
* `storageAccessKey`: Azure storage account access key. storageAccessKey is obtained from the Storage section of the [Azure Portal](https://manage.windowsazure.com/#Workspace/StorageExtension/storage).
* `key`: The key file for the Azure management certificate. See [Azure Management Certificates](#azure-manage-cert).
* `cert`: The certificate .pem file for the Azure Management Certificate. See [Azure Management Certificates](#azure-manage-cert).
* `subscriptionId`: The subscription ID of your Azure account obtained from the Administrators section of the [Azure Portal](https://manage.windowsazure.com/#Workspace/AdminTasks/ListUsers).

**Azure Specific Settings**

* `location`: Location of storage account and Azure compute servers (East US, West US, etc.). Storage account and compute servers need to be in same location.
* `username`: The administrator username used to log into the Azure virtual machine. For Windows servers, this field is ignored and administrator is used for the username.
* `password`: The administrator password.
* `ssh.port`: The port to use for SSH on Linux servers.
* `ssh.cert`: The X509 certificate with a 2048-bit RSA keypair. Specify the path to this pem file. See [Azure x.509 SSH Certificates](#azure-ssh-cert).
* `ports`: An array of ports to open on the vm. For each port, specify the port information using a port object with the following members.
	* `name`: the name of the port.
	* `port`:  the external/public port to use for the endpoint.
	* `localPort`: specifies the internal/private port on which the vm is listening to serve the endpoint.
	* `protocol`: specifies the transport protocol for the endpoint.

* `rdp.port`: (Optional. Windows servers only). The port to use for RDP on Windows servers.

<br/>
<a name="azure-manage-cert"></a>
## Azure Management Certificates

### Create an Azure Service Management certificate on Linux/Mac OSX:

1. Create RSA private key. 
``` bash
	openssl genrsa -out management.key 2048
```
**Note: You will use the management.key file for the key property when creatings a pkgcloud Azure compute instance.**

2. Create a self signed certificate.
``` bash
	openssl req -new -key management.key -out management.csr
```

3. Create the management.pem x509 pem file from RSA key created in Step 1 and the self signed certificate created in Step 2. 
``` bash 
	openssl x509 -req -days 365 -in management.csr -signkey management.key -out management.pem
```
**Note: You will use the management.pem file for the cert property when creatings a pkgcloud Azure compute instance.**


4. Concatenate the management PEM file and RSA key file to a temporary .pem file. This file will be used to create the Management Certificate file you will upload to the Azure Portal.
``` bash
	cat management.key management.pem > temp.pem 
```

5. Create the Management Certificate file. This will be the Management Certificate .cer file you need to upload to the [Management Certificates section](https://manage.windowsazure.com/#Workspace/AdminTasks/ListManagementCertificates) of the Azure portal. 
``` bash
    openssl x509 -inform pem -in temp.pem -outform der -out management.cer
```

6. Secure your certificate and key files.
``` bash
	chmod 600 *.*
```

**Note: When creating a pkgcloud Azure compute instance, use the management.cert file for the cert property and the management.key file for the key property.
**

If you need a .pfx version of the management certificate.

``` bash
openssl pkcs12 -export -out management.pfx -in management.pem -inkey management.key -name "My Certificate"
```

<br/>
### Create an Azure Service Management certificate from a .publishsettings file:

For more information about this [read the article on windowsazure.com:](https://www.windowsazure.com/en-us/manage/linux/common-tasks/manage-certificates/) https://www.windowsazure.com/en-us/manage/linux/common-tasks/manage-certificates/

<br/>
### Create an Azure Service Management certificate on Windows:

For more information about this [read the article on MSDN:](http://msdn.microsoft.com/en-us/library/windowsazure/gg551722.aspx) http://msdn.microsoft.com/en-us/library/windowsazure/gg551722.aspx.

<br/>
<a name="azure-ssh-cert"></a>
## Azure x.509 SSH Certificates

### Create an Azure x.509 SSH certificate on Linux/Mac OSX:

1. Create x.509 pem file and key file
	
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout sshkey.key -out sshcert.pem

2. Change the permissions on the private key and certificate for security.

	chmod 600 sshcert.pem	
	chmod 600 sshkey.key
	
3. Specify the path to sshcert.pem in the ssh.cert config property when creating an Azure pkgcloud compute client.

4. If you specified a password when creating the pem file, add the password to the ssh.pemPassword config property when creating an Azure pkgcloud compute client.

5. When connecting with ssh to a running Azure compute server, specify the path to the sshkey.key file.
 
	ssh -i  sshkey.key -p <port> username@servicename.cloudapp.net

For more info: https://www.windowsazure.com/en-us/manage/linux/how-to-guides/ssh-into-linux/

<a name="using-databases"></a>
## Using Databases
Azure Tables is available in `pkgcloud` as a `pkgcloud.databases` target. Here is an example of how to use it:

``` js
  var client = pkgcloud.database.createClient({
    provider: 'azure',
    storageAccount: "test-storage-account",		// Name of your Azure storage account
    storageAccessKey: "test-storage-access-key" // Access key for storage account
  });

  //
  // Create an Azure Table
  //
  client.create({
    name: "test"
  }, function (err, result) {
    //
    // Check the result
    //
    console.log(err, result);

    //
    // Now delete that same Azure Table
    //
    client.remove(result.id, function (err, result) {
      //
      // Check the result
      //
      console.log(err, result);
    });
  });
```

The `client` instance returned by `pkgcloud.database.createClient` has the following methods for Azure Tables:

* `client.create(options, callback)`
* `client.remove(id, callback)`
* `client.list(callback)	// lists all of the Tables in your Azure Storage account`

Use the azure-sdk-for-node to create, query, insert, update, merge, and delete Table entities. For more info: https://github.com/WindowsAzure/azure-sdk-for-node
