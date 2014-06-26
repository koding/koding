![HP Helion icon](http://www8.hp.com/hpnext/sites/default/files/content/documents/HP%20Helion%20Logo_Cloud_Martin%20Fink_New%20Style%20of%20IT_Hewlett-Packard.PNG)

##Using the HP Cloud Network provider

Creating a client is straight-forward:

``` js
  var hPNetwork = pkgcloud.network.createClient({
    provider: 'hp',
    username: 'your-user-name',
    apiKey: 'your-api-key',
    region: 'region of identity service',
    authUrl: 'https://your-identity-service'
  });
```
### API Methods

**Networks**

#### client.getNetworks(callback)
Lists all networks that are available to use on your HP Cloud account

Callback returns `f(err, networks)` where `networks` is an `Array`

#### client.getNetwork(network, callback)
Gets specified network

Takes network or networkId as an argument and returns the network in the callback
`f(err, network)`

#### client.createNetwork(options, callback)
Creates a network with the options specified

Options are as follows:

```js
{
  name: 'networkName', // optional
  adminStateUp : true,  // optional
  shared : true,    // optional, Admin only
  tenantId : 'tenantId'     // optional, Admin only
}
```
Returns the network in the callback `f(err, network)`

#### client.updateNetwork(options, callback)
Updates a network with the options specified

Options are as follows:

```js
{
  id : 'networkId', // required
  name: 'networkName', // optional
  adminStateUp : true,  // optional
  shared : true,    // optional, Admin only
  tenantId : 'tenantId'     // optional, Admin only
}
```
Returns the network in the callback `f(err, network)`

#### client.destroyNetwork(network, callback)
Destroys the specified network

Takes network or networkId as an argument  and returns the id of the destroyed network in the callback `f(err, networkId)`

**Subnets**

#### client.getSubnets(callback)
Lists all subnets that are available to use on your HP Cloud account

Callback returns `f(err, subnets)` where `subnets` is an `Array`

#### client.getSubnet(subnet, callback)
Gets specified subnet

Takes subnet or subnetId as an argument and returns the subnet in the callback
`f(err, subnet)`

#### client.createSubnet(options, callback)
Creates a subnet with the options specified

Options are as follows:

```js
{
  name: 'subnetName', // optional
  networkId : 'networkId',  // required, The ID of the attached network.
  shared : true,    // optional, Admin only
  tenantId : 'tenantId'     // optional, The ID of the tenant who owns the network. Admin-only
  gatewayIp : 'gateway ip address', // optional,The gateway IP address.
  enableDhcp : true // Set to true if DHCP is enabled and false if DHCP is disabled.
}
```
Returns the subnet in the callback `f(err, subnet)`

#### client.updateSubnet(options, callback)
Updates a subnet with the options specified

Options are as follows:

```js
{
  id : 'subnetId', // required
  name: 'subnetName', // optional
  networkId : 'networkId',  // required, The ID of the attached network.
  shared : true,    // optional, Admin only
  tenantId : 'tenantId'     // optional, The ID of the tenant who owns the network. Admin-only
  gatewayIp : 'gateway ip address', // optional,The gateway IP address.
  enableDhcp : true // Set to true if DHCP is enabled and false if DHCP is disabled.
}
```
Returns the subnet in the callback `f(err, subnet)`

#### client.destroySubnet(subnet, callback)
Destroys the specified subnet

Takes subnet or subnetId as an argument  and returns the id of the destroyed subnet in the callback `f(err, subnetId)`

**Ports**

#### client.getPorts(callback)
Lists all ports that are available to use on your HP Cloud account

Callback returns `f(err, ports)` where `ports` is an `Array`

#### client.getPort(port, callback)
Gets specified port

Takes port or portId as an argument and returns the port in the callback
`f(err, port)`

#### client.createPort(options, callback)
Creates a port with the options specified

Options are as follows:

```js
{
  name: 'portName', // optional
  adminStateUp : true,  // optional, The administrative status of the router. Admin-only
  networkId : 'networkId',  // required, The ID of the attached network.
  status  : 'text status',    // optional, The status of the port.
  tenantId : 'tenantId'     // optional, The ID of the tenant who owns the network. Admin-only
  macAddress: 'mac address'     // optional
  fixedIps : ['ip address1', 'ip address 2'], // optional.
  securityGroups : ['security group1', 'security group2'] // optional, Specify one or more security group IDs.
}
```
Returns the port in the callback `f(err, port)`

#### client.updatePort(options, callback)
Updates a port with the options specified

Options are as follows:

```js
{
  id : 'portId', // required
  name: 'portName', // optional
  adminStateUp : true,  // optional, The administrative status of the router. Admin-only
  networkId : 'networkId',  // required, The ID of the attached network.
  status  : 'text status',    // optional, The status of the port.
  tenantId : 'tenantId'     // optional, The ID of the tenant who owns the network. Admin-only
  macAddress: 'mac address'     // optional
  fixedIps : ['ip address1', 'ip address 2'], // optional.
  securityGroups : ['security group1', 'security group2'] // optional, Specify one or more security group IDs.
}
```
Returns the port in the callback `f(err, port)`

#### client.destroyPort(port, callback)
Destroys the specified port

Takes port or portId as an argument  and returns the id of the destroyed port in the callback `f(err, portId)`
