## Using the Rackspace provider in pkgcloud

The Rackspace provider in pkgcloud supports the following services:

* [**Compute**](compute.md) (Cloud Servers)
* [**Storage**](storage.md) (Cloud Files)
* [**Databases**](databases.md) (Cloud Databases)
* [**DNS**](dns.md) (Cloud DNS) *(beta)*
* [**Block Storage**](blockstorage.md) (Cloud Block Storage) *(beta)*
* [**Load Balancers**](loadbalancer.md) (Cloud Load Balancers) *(beta)*

### Getting Started with Compute

We've provided a [simple compute example](getting-started-compute.md) where it creates a couple of compute instances.

### Authentication

For all of the Rackspace services, you create a client with the same options:

```Javascript
var client = require('pkgcloud').compute.createClient({
    provider: 'rackspace',
    username: 'your-user-name',
    apiKey: 'your-api-key'
});
```

In addition to your `apiKey`, you could alternately provide your `password` as an option to `createClient`.

### Authentication Endpoints and Regions

All of the Rackspace `createClient` calls have a few options that can be provided:

#### authUrl

`authUrl` specifies the authentication endpoint used to create a token for your Rackspace client. By default, this is set to the Global endpoint: https://identity.api.rackspacecloud.com.

##### Authenticating against the London endpoint

```Javascript
var client = require('pkgcloud').compute.createClient({
    provider: 'rackspace',
    username: 'your-user-name',
    apiKey: 'your-api-key',
    authUrl: 'https://lon.identity.api.rackspacecloud.com'
});
```

#### region

`region` specifies which region of a service to use. For example, when you authenticate with the global endpoint for compute, you have the option of either `DFW`, `ORD`, or `SYD`. The default region is `DFW`. Previous pkgcloud versions did not let you specify which region you used, so all calls were against `DFW`.

##### Specifying a custom region

```Javascript
var client = require('pkgcloud').compute.createClient({
    provider: 'rackspace',
    username: 'your-user-name',
    apiKey: 'your-api-key',
    region: 'ORD'
});
```

#### Tokens and Expiration

When you make your first call to a Rackspace provider, your client is authenticated transparent to your API call. Rackspace will issue you a token, with an expiration. When that token expires, the client will automatically re-authenticate and retrieve a new token. The caller shouldn't have to worry about this happening.

#### Internal URLs

As part of the options, you can tell `pkgcloud` to use the Internal (Service Net) URLs for a service, if possible.

 ```Javascript
 var client = require('pkgcloud').storage.createClient({
     provider: 'rackspace',
     username: 'your-user-name',
     apiKey: 'your-api-key',
     useInternal: true
 });
 ```

 This setting is explicit. If you set it to true, and you have no connectivity to the internal URL for a service, your connections will timeout.