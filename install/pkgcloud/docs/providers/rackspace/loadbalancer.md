##Using the Rackspace Load Balancer provider

#### BETA - This API may change as additional providers for load balancers are added to pkgcloud

### Table of Contents

* LoadBalancer
  * [Model](#loadbalancer-model)
  * [Managing Load Balancers](#loadbalancer-apis)
  * [Nodes](#nodes)
  * [VirtualIPs](#virtual-ips)
  * [SSL Config](#load-balancer-ssl-termination)
  * [Access Control](#access-control)
  * [Health Monitoring](#health-monitoring)
  * [Session Persistence](#session-persistence)
  * [Connection Logging](#connection-logging)
  * [Connection Throttling](#connection-throttling)
  * [Content Caching](#content-caching)
  * [Custom Error Page](#custom-error-page)
  * [Utility Calls](#utility-calls)
  * [Stats & Usage](#stats-and-usage)
* Node
  * [Model](#node-model)

### Getting Started

Creating a loadbalancer client is straight-forward:

``` js
  var rackspace = pkgcloud.loadbalancer.createClient({
    provider: 'rackspace',
    username: 'your-user-name',
    apiKey: 'your-api-key'
  });
```

*[More options for creating clients](README.md)*

Once you have a client, creating a load balancer is straight-forward.

```Javascript
rackspace.createLoadBalancer({
  name: 'my-load-balancer',
  protocol: pkgcloud.providers.rackspace.loadbalancer.Protocols.HTTP,
  virtualIps: [
    {
      type: pkgcloud.providers.rackspace.loadbalancer.VirtualIpTypes.PUBLIC
    }
  ]
}, function(err, loadBalancer) {
  // use your new loadBalancer here
});
```

There are a number of [other options](#clientcreateloadbalancerdetails-callback) for creating your loadBalancer, but this will create a basic HTTP LoadBalancer on the Rackspace Cloud.



### LoadBalancer Model

A LoadBalancer has following properties:

```Javascript
{
  id: 12345,
  name: 'my-test-loadbalancer',
  protocol: 'HTTP',
  port: 80,
  algorithm: 'WEIGHTED_ROUND_ROBIN',
  halfClosed: false,
  cluster: { name: 'ztm-0001.dfw1.lbaas.rackspace.net' },
  sourceAddresses: // this is where traffic from your LB originates
   { ipv6Public: '2002:4800:4800::25/64',
     ipv4Servicenet: '10.1.1.1',
     ipv4Public: '1.2.3.4' },
  httpsRedirect: false,
  connectionLogging: { enabled: false },
  contentCaching: { enabled: false },
  status: 'ACTIVE',
  timeout: 30,
  nodes:
   [ { address: '192.168.10.3',
       id: 12345,
       type: 'PRIMARY',
       port: 80,
       status: 'ONLINE',
       condition: 'ENABLED',
       weight: 5 },
     { address: '192.168.10.2',
       id: 12346,
       type: 'PRIMARY',
       port: 80,
       status: 'ONLINE',
       condition: 'DISABLED',
       weight: 1 } ],
  virtualIps: // these are the IPs your LB listens on
   [ { address: '1.2.3.5',
       id: 3333,
       type: 'PUBLIC',
       ipVersion: 'IPV4' },
     { address: '2001:4800:4800:4800:4800:4800:0000:0003',
       id: 4444,
       type: 'PUBLIC',
       ipVersion: 'IPV6' } ],
  nodeCount: 2,
  created: { time: '2013-11-21T00:14:03Z' },
  updated: { time: '2013-11-22T06:06:26Z' }
}
```

**Proxy Methods**

An instance of a `LoadBalancer` has a number of convenience proxy methods. For example:

```Javascript
client.getNodes(loadBalancer, function(err, nodes) { ... };

// is equivalent to

loadBalancer.getNodes(function(err, nodes) { ... };
```

View the [complete list of LoadBalancer proxy methods](#loadbalancer-proxy-methods).

### Node Model

A Node for LoadBalancer has the following properties:

```Javascript
{
  id: 33333,
  loadBalancerId: 12345,
  type: 'PRIMARY',
  port: 80,
  weight: 5,
  status: 'ONLINE',
  condition: 'ENABLED',
  address: '192.168.10.3'
}
```

### LoadBalancer APIs

#### client.getLoadBalancers(options, callback)
Lists all LoadBalancers that are available to use on your Rackspace account

Callback returns `f(err, loadbalancers)` where `loadbalancers` is an `Array`. `options` is an optional and unused argument at this time.

#### client.getLoadBalancer(loadBalancer, callback)
Gets specified LoadBalancer.

Takes `loadBalancer` or `loadBalancerId` as an argument and returns the `loadBalancer` in the callback
`f(err, loadBalancer)`

#### client.createLoadBalancer(details, callback)

Creating a new load balancer is one of few calls in the LoadBalancer provider that has numerous optional properties for the new Load Balancer. For a complete list and explanation of the options see the [Rackspace API documentation](http://docs.rackspace.com/loadbalancers/api/v1.0/clb-devguide/content/Create_Load_Balancer-d1e1635.html).

The following JS object provides a brief overview of required and optional parameters for the `createLoadBalancer` `details` argument:
```js
{
  name: 'my-lb', // required
  protocol: pkgcloud.providers.rackspace.loadbalancer.Protocols.HTTP, // required
  virtualIps: [
      {
        type: pkgcloud.providers.rackspace.loadbalancer.VirtualIpTypes.PUBLIC
      }
    ], // required, you must specify at least one virtualIP for you balancer

  nodes: [
    {
      address: '192.168.10.1',
      port: 80,
      condition: 'ENABLED'
    },
    {
      address: '192.168.10.2',
      port: 80,
      condition: 'ENABLED'
    }
  ], // nodes are optional, you can add them later

  timeout: 30 // optional, defaults to 30, timeout in seconds for requests

  accessList: [
    { address: '67.120.50.4', type: 'DENY' },
    { address: '67.120.50.5', type: 'DENY' },
    { address: '67.120.50.6', type: 'ALLOW'}
  ], // accessList is optional, if provided should be an array of objects

  algorithm: 'WEIGHTED_ROUND_ROBIN', // optional, defaults to ROUND_ROBIN

  connectionLogging: {
    enabled: true
  }, // optional, if supplied should be an objected with enabled set to boolean

  connectionThrottle: {
    maxConnectionRate: 0, // 0 for unlimited, 1-100000
    maxConnections: 10,   // 0 for unlimited, 1-100000
    minConnections: 5, // 0 for unlimited, 1-1000 otherwise
    rateInterval: 3600 // frequency in seconds at which maxConnectionRate
                       // is assessed
  }, // optional, if supplied should be an object with these options

  healthMonitor: {
    type: 'CONNECT', // a ping probe, also can be HTTP/HTTPS, see docs for more examples
    delay: 10,
    timeout: 10,
    attemptsBeforeDeactivation: 3
  }, // optional, may be one of two connection types, see the healthMonitor section
     // for more details

  sessionPersistence: {
    persistenceType: 'HTTP_COOKIE'
  } // optional, should be HTTP_COOKIE or SOURCE_IP
}
```

For a list of protocols you can either access `pkgcloud.providers.rackspace.loadbalancer.Protocols` or call `client.getProtocols`.

Similarly, a list of algorithms is available via `client.getAlgorithms`.

Returns the new LoadBalancer in the callback `f(err, loadBalancer)`

#### client.updateLoadBalancer(loadBalancer, callback)
Updates the `name`, `protocol`, `port`, `timeout`, `algorithm`, `httpsRedirect` and `halfClosed` properties of the provided `loadBalancer`.

Returns callback with `f(err)`.

#### client.deleteLoadBalancer(loadBalancer, callback)
Deletes the specified `loadBalancer`.

Takes `loadBalancer` or `loadBalancerId` as an argument and returns an error if unsuccessful `f(err)`

### Nodes

A `Node` is a backend entity for a load balancer. When you setup load balancers, nodes are where you route traffic to based on your load balancers properties.

#### client.getNodes(loadBalancer, callback)

Get an array of `Node` for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument.

Callback is `f(err, nodes)`.

#### client.addNodes(loadBalancer, nodes, callback)

Add a single or array of nodes to the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument. `nodes` should be a single or array of objects.

##### Node Details
```Javascript
{
  address: '192.168.10.1',
  port: 80,
  condition: 'ENABLED', // also supports 'DISABLED' & 'DRAINING'
  type: 'PRIMARY', // use 'SECONDARY' as a fail over node
  weight: 5 // optional, only used on WEIGHTED algorithms
}
```

Each `address` must be unique, and `err` will be present otherwise. Callback is `f(err, nodes)`.

#### client.updateNode(loadBalancer, node, callback)

Update a nodes condition, type, or weight for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument, and `node` as the node to update.

Callback is `f(err)`.

#### client.removeNode(loadBalancer, node, callback)

Remove a `node` from the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument. `node` should be either the `node` or `nodeId`.

Callback is `f(err)`.

#### client.removeNodes(loadBalancer, nodes, callback)

Remove a an array of nodes from the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument. `nodes` should be an array of either the `node` or `nodeId`.

Callback is `f(err)`.

#### client.getNodeServiceEvents(loadBalancer, callback)

Retrieve a list of events associated with the activity between the node and the load balancer for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument.

Callback is `f(err, events)`.

### Virtual IPs

The VirtualIP for a load balancers is the IP (or IPs) for which your load balancer will receive traffic. For example, if you're using a `PUBLIC` `IPV4` VirtualIP, and the value is `1.2.3.4`, this is the address you'd create for a DNS record that maps to your Load Balancer.

Supported types are:

* PUBLIC
* SERVICENET

Supported IP Versions are:

* IPV4
* IPV6

To control specific VirtualIP configuration for your load balancer, you must set it correctly when you create your load balancer.

#### client.getVirtualIps(loadBalancer, callback)

Gets a list of VirtualIPs for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument. Load Balancers must always have at least 1 VirtualIP.

Callback is `f(err, virtualIps)`.

#### client.addIPV6VirtualIp(loadBalancer, callback)

Add a `PUBLIC` `IPV6` VirtualIP to your provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument.

**Note**: You cannot add any `IPV4` addresses after the load balancer is created.

Callback is `f(err, virtualIp)` where `virtualIp` is the newly added VirtualIP

#### client.removeVirtualIp(loadBalancer, virtualIp, callback)

Remove a VirtualIP from the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument. `virtualIp` should be the `id` property from a VirtualIP entity. Callback is `f(err)`.

Load Balancers must always have at least 1 VirtualIP, if you try and remove the last VirtualIP, `err` will be present.

### Load Balancer SSL Termination

You can configure an HTTP protocol load balancer to terminate SSL by providing your SSL certificates. For example, this allows your load balancer to use HTTP_COOKIE for persistent sessions even over HTTPS.

#### client.getSSLConfig(loadBalancer, callback)

Gets the current SSL config for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument. If the load balancer does not have SSL configured, `err` will be present.

Callback is of the signature `f(err, sslConfig)`

An example `sslConfig`:

```Javascript
{
  enabled: true,
  secureTrafficOnly: false,
  securePort: 443,
  certificate: '-----BEGIN CERTIFICATE----- ....... \n-----END CERTIFICATE-----',
  privatekey: '-----BEGIN RSA PRIVATE KEY----- ....... \n-----END RSA PRIVATE KEY-----'
}
```

The `sslConfig` may also have an `intermediatecertificate` if you've setup one as part of your SSL Configuration.

#### client.updateSSLConfig(loadBalancer, details, callback)

Updates the SSL configuration for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument, as well as `details` for your SSL configuration. If SSL is not enabled, it will be enabled, otherwise it will be updated.

Example:

```Javascript
var sslConfig = {
  securePort: '443',
  enabled: true,
  secureTrafficOnly: false
};

fs.readFile('my-certificate.key', function(err, contents) {
  if (err) {
    throw err;
  }

  sslConfig.privatekey = contents.toString();

  fs.readFile('my-certificate.crt', function(err, contents) {
    if (err) {
      throw err;
    }

    sslConfig.certificate = contents.toString();

    fs.readFile('my-certificate-intermediate.crt', function(err, contents) {
      if (err) {
        throw err;
      }

      sslConfig.intermediateCertificate = contents.toString();

      client.updateSSLConfig(loadBalancerId, sslConfig, function (err) {
        console.dir(err);
      });
    });
  });
});
```

More information can be found on the [Rackspace Cloud Load Balancers API documentation](http://docs.rackspace.com/loadbalancers/api/v1.0/clb-devguide/content/SSLTermination-d1e2479.html).

#### client.removeSSLConfig(loadBalancer, callback)

Removes the current SSL config for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument.

If SSL is not enabled, `err` will be present in the callback. Callback signature is `f(err)`.

### Access Control

You can configure your load balancer to accept or deny traffic from specific hosts and subnets.

#### client.getAccessList(loadBalancer, callback)

Get the access list for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument. Callback is `f(err, accessList)`. If there is no accessList, will return an empty array.

#### client.addAccessList(loadBalancer, accessList, callback)

Will add a new entry or array of entries to the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument.

`accessList` should be an object or array of objects with the following syntax:

```Javascript
{
  address: '1.2.3.4',
  type: 'ALLOW' // you may also use 'DENY'
}
```

##### Denying all traffic

Access control is especially useful if you're running a load balancer on ServiceNet, but you want to restrict traffic to only allow your CloudServers. First, you'd need to allow your Cloud Servers. Then, to deny all traffic, except for those that are explicitly allowed, use `'0.0.0.0/0'` for the `address`. Duplicate records will result in `err` being present in the callback.


Callback has the signature `f(err)`.

#### client.deleteAccessListItem(loadBalancer, accessListItem, callback)

When you get a list of accessList items from `client.getAccessList`, each item will have an `id` property in addition to `address` and `type`. If you want to remove a specific entry, you can remove it with `client.deleteAccessListItem` and pass the item or the `id` property.

Takes `loadBalancer` or `loadBalancerId` as the first argument and `accessListItem` or `accessListItemId` as the second argument. Callback is `f(err)`.

#### client.deleteAccessList(loadBalancer, accessList, callback)

Similar to `client.deleteAccessListItem` except that it takes an array of items, as opposed to a single entry. Callback is `f(err)`.

#### client.resetAccessList(loadBalancer, callback)

Completely remove the access list for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument.

Callback is `f(err)`.

### Health Monitoring

Rackspace Cloud Load Balancers allow two types of health monitoring for the nodes: TCP Ping (`CONNECT`) and `HTTP` or `HTTPS`.

#### client.getHealthMonitor(loadBalancer, callback)

Gets the current health monitor configuration for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument. Callback is `f(err, healthMonitor)`.

#### client.updateHealthMonitor(loadBalancer, details, callback)

Add or update a health monitor for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as the first argument, and the health monitor `details` as the second.

There are two types of health monitors:

* CONNECT
* HTTP/HTTPS

Use the `CONNECT` monitor as a basic ping probe to make sure your box is present. Use the `HTTP` or `HTTPS` monitors to make an HTTP call to validate a more complex health check.

##### Connect Details
```Javascript
{
   type: 'CONNECT', // required
   delay: 10, // required, delay in seconds before executing check, 1 to 3600
   timeout: 10, // required, seconds to wait before timing out, 1 to 300
   attemptsBeforeDeactivation: 3, // required, 1 to 10
}
```

##### HTTP Details
```Javascript
{
   type: 'HTTP', // required, use 'HTTPS' to connect over 443/SSL
   delay: 10, // required, delay in seconds before executing check, 1 to 3600
   timeout: 10, // required, seconds to wait before timing out, 1 to 300
   attemptsBeforeDeactivation: 3, // required, 1 to 10
   path: '/', // required, path to query on the node
   statusRegex: '^[2][0-9][0-9]$', // required, evaluate the statusCode
                                   // this example uses any 2xx status as valid
   bodyRegex: '^[234][0-9][0-9]$', // required, regex to evaluate the body contents
   hostHeader: 'myrack.com' // optional, the name of a host for which the health monitors will check.
}
```

Callback is `f(err)`.

#### client.removeHealthMonitor(loadBalancer, callback)

Removes any health monitors for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as the argument. Callback is `f(err)`. If the health monitor is not enabled, `err` will present.

### Session Persistence

Session persistence allows forcing requests from the same client+protocol to route to the same node. There are two modes:

* HTTP_COOKIE
* SOURCE_IP

`HTTP_COOKIE` is only enabled for HTTP load balancers (with or without SSL termination), all other protocols must use `SOURCE_IP`.

#### client.getSessionPersistence(loadBalancer, callback)

Gets the current session persistence configuration for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument. Callback is `f(err, sessionPersistence)`.

#### client.enableSessionPersistence(loadBalancer, type, callback)

Enable session persistence for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument. `type` must be either `HTTP_COOKIE` or `SOURCE_IP`. Callback is `f(err)`. If you try to set `HTTP_COOKIE` for a non-HTTP load balancer, `err` will be present.

#### client.disableSessionPersistence(loadBalancer, callback)

Disables session persistence for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as the argument. Callback is `f(err)`. If session persistence is not enabled, `err` will present.

### Connection Logging

Enable logging (or disable) for connections on your load balancer. Logs will be stored in Cloud Files on your account.

#### client.getConnectionLoggingConfig(loadBalancer, callback)

Get the connection logging configuration for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as the argument. Callback is `f(err, connectionLogging)`.

#### client.updateConnectionLogging(loadBalancer, enabled, callback)

Update the connection logging setting for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as the first argument. `enabled` should be `true` or `false`. Callback is `f(err)`.

Call with `false` to disable connection logging.

### Connection Throttling

Cloud Load Balancers can be configured to use connection throttling. There are some cases where you may need this to control load or help mitigate malicious or abusive traffic to your applications.

#### client.getConnectionThrottleConfig(loadBalancer, callback)

Get the connection throttle configuration for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as the argument. Callback is `f(err, connectionThrottle)`.

#### client.updateConnectionThrottle(loadBalancer, details, callback)

Add or update a connection throttle for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as the first argument, and the connection throttle `details` as the second.

##### Connection Throttle Details
```Javascript
{
   maxConnectionRate: 0, // 0 for unlimited, 1-100000
   maxConnections: 10,   // 0 for unlimited, 1-100000
   minConnections: 5, // 0 for unlimited, 1-1000 otherwise
   rateInterval: 3600 // frequency in seconds at which maxConnectionRate
                      // is assessed
}
```

If you are providing a new connection throttle, all values are required, however you can update an existing throttle with only the values you wish to change.

Callback is `f(err)`.

#### client.disableConnectionThrottle(loadBalancer, callback)

Disables a connection throttle for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as the argument. Callback is `f(err)`. If a connection throttle is not enabled, `err` will present.

### Content Caching

Enable content caching (or disable) for your load balancer.

When content caching is enabled, recently-accessed files are stored on the load balancer for easy retrieval by web clients. Content caching improves the performance of high traffic web sites by temporarily storing data that was recently accessed. While it's cached, requests for that data will be served by the load balancer, which in turn reduces load off the back end nodes. The result is improved response times for those requests and less load on the web server.

For more information see the [Content Caching Documentation](http://docs.rackspace.com/loadbalancers/api/v1.0/clb-devguide/content/ContentCaching-d1e3358.html).

#### client.getContentCachingConfig(loadBalancer, callback)

Get the content caching configuration for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as the argument. Callback is `f(err, contentCaching)`.

#### client.updateContentCaching(loadBalancer, enabled, callback)

Update the content caching setting for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as the first argument. `enabled` should be `true` or `false`. Callback is `f(err)`.

Call with `false` to disable content caching.

### Custom Error Page

You can setup a custom error page for when your load balancer fails to connect to a node for a specific request. The format is standard HTML markup.

#### client.getErrorPage(loadBalancer, callback)

Get the current error page for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as the argument. Callback is `f(err, errorpage)`.

#### client.setErrorPage(loadBalancer, content, callback)

Set the error page markup for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as the first argument. `content` should be the HTML markup for your new error page. Callback is `f(err)`.

#### client.deleteErrorPage(loadBalancer, callback)

Remove the custom error page for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as the argument. Callback is `f(err)`.

### Utility Calls

#### client.getAllowedDomains(callback)

Get a list of allowed domains to be used when adding nodes. This is only used for DNS names for rackspace assets. i.e. `some.asset.at.rackspaceclouddb.com`. Most users should not need this method.

#### client.getAlgorithms(callback)

Get a list of supported algorithms for load balancers.

#### client.getProtocols(callback)

Get a list of supported protocols.

### Stats and Usage

#### client.getBillableLoadBalancers(startTime, endTime, [options], callback)

Gets the billable loadBalancers for your account. Callback is `f(err, loadBalancers)`.

#### client.getStats(loadBalancer, callback)

Get statistics for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument. Callback is `f(err, stats)`.

#### client.getAccountUsage(startTime, endTime, callback)

Get account level usage.

Callback is `f(err, usage)`.

#### client.getCurrentUsage(loadBalancer, callback)

Get the current usage data for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument.

Callback is `f(err, usage)`.

#### client.getHistoricalUsage(loadBalancer, startTime, endTime, callback)

Get historical usage data for the provided `loadBalancer`. Takes `loadBalancer` or `loadBalancerId` as an argument. Data is available for 90 days of service activity.

Callback is `f(err, usage)`.

### LoadBalancer Proxy Methods

##### loadBalancer.getNodes(callback)
##### loadBalancer.addNode(node, callback)
##### loadBalancer.addNodes(nodes, callback)
##### loadBalancer.updateNode(node, callback)
##### loadBalancer.removeNode(node, callback)
##### loadBalancer.removeNodes(nodes, callback)
##### loadBalancer.getNodeServiceEvents(callback)
##### loadBalancer.getVirtualIps(callback)
##### loadBalancer.addIPV6VirtualIp(callback)
##### loadBalancer.removeVirtualIp(virtualIp, callback)
##### loadBalancer.getSSLConfig(callback)
##### loadBalancer.updateSSLConfig(details, callback)
##### loadBalancer.removeSSLConfig(callback)
##### loadBalancer.getAccessList(callback)
##### loadBalancer.addAccessList(accessList, callback)
##### loadBalancer.deleteAccessListItem(accessListItem, callback)
##### loadBalancer.deleteAccessList(accessList, callback)
##### loadBalancer.resetAccessList(callback)
##### loadBalancer.getHealthMonitor(callback)
##### loadBalancer.updateHealthMonitor(details, callback)
##### loadBalancer.removeHealthMonitor(callback)
##### loadBalancer.getSessionPersistence(callback)
##### loadBalancer.enableSessionPersistence(type, callback)
##### loadBalancer.disableSessionPersistence(callback)
##### loadBalancer.getConnectionLoggingConfig(callback)
##### loadBalancer.enableConnectionLogging(callback)
##### loadBalancer.disableConnectionLogging(callback)
##### loadBalancer.getConnectionThrottleConfig(callback)
##### loadBalancer.updateConnectionThrottle(details, callback)
##### loadBalancer.disableConnectionThrottle(callback)
##### loadBalancer.getContentCachingConfig(callback)
##### loadBalancer.enableContentCaching(callback)
##### loadBalancer.disableContentCaching(callback)
##### loadBalancer.getErrorPage(callback)
##### loadBalancer.setErrorPage(content, callback)
##### loadBalancer.deleteErrorPage(callback)
##### loadBalancer.getStats(callback)
##### loadBalancer.getCurrentUsage(callback)
##### loadBalancer.getHistoricalUsage(startTime, endTime, callback)










