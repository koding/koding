## Using the Openstack provider in pkgcloud

The OpenStack provider in pkgcloud supports the following services:

* [**Compute**](compute.md) (Nova)
* [**Storage**](storage.md) (Swift)

### Getting Started with Compute

We've provided a [simple compute example](getting-started-compute.md) where it creates a couple of compute instances.

### Authentication

For all of the Openstack services, you create a client with the same options:

```Javascript
var client = require('pkgcloud').compute.createClient({
    provider: 'openstack',
    username: 'your-user-name',
    password: 'your-password',
    authUrl: 'https://your-identity-service'
});
```

### Authentication Endpoints and Regions

All of the Openstack `createClient` calls have a few options that can be provided:

#### region

`region` specifies which region of a service to use.

##### Specifying a custom region

```Javascript
var client = require('pkgcloud').compute.createClient({
    provider: 'openstack',
    username: 'your-user-name',
    password: 'your-api-key',
    authUrl: 'https://your-identity-service'
    region: 'Calxeda-AUS1'
});
```

#### Tokens and Expiration

When you make your first call to a Openstack provider, your client is authenticated transparent to your API call. Openstack will issue you a token, with an expiration. When that token expires, the client will automatically re-authenticate and retrieve a new token. The caller shouldn't have to worry about this happening.
