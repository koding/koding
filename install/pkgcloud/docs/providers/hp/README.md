![HP Helion icon](http://www8.hp.com/hpnext/sites/default/files/content/documents/HP%20Helion%20Logo_Cloud_Martin%20Fink_New%20Style%20of%20IT_Hewlett-Packard.PNG)

## Using the HP Helion Cloud provider in pkgcloud

The HP  Helion Cloud provider in pkgcloud supports the following services:

* [**Compute**](compute.md) (cloud compute)
* [**Network**](network.md) (network)
* [**Storage**](storage.md) (object storage)

### Activating your HP  Helion Cloud services

If this is your first time using HP  Helion Cloud Services, please follow [this](https://community.hpcloud.com/article/hp-public-cloud-quick-start-guide) guide to get started.
### Getting Started with Compute

We've provided a [simple compute example](getting-started-compute.md) where it creates a couple of compute instances.

### Authentication

For all of the HP Cloud services, you create a client with the same options:

```Javascript
var client = require('pkgcloud').compute.createClient({
    provider: 'hp',
    username: 'your-user-name',
    apiKey: 'your-api-key'
});
```
### Getting your API key

You can provision API keys in your cloud management console.
Please see [here](https://community.hpcloud.com/article/managing-your-access-keys) for more instructions.

### Authentication Endpoints and Regions

All of the HP `createClient` calls have a few options that can be provided:

#### authUrl

`authUrl` specifies the authentication endpoint used to create a token for your HP client.
See here for more details : [Regions](http://docs.hpcloud.com/api/identity/#2.2RegionsandAvailabilityZones)
If you're targeting an HP Private Cloud instance, please contact your administrator for the authUrl.

##### Authenticating against the US-West endpoint

```Javascript
var client = require('pkgcloud').compute.createClient({
    provider: 'hp',
    username: 'your-user-name',
    apiKey: 'your-api-key',
    region: 'region-a.geo-1',
    authUrl: 'https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/'
});
```

##### Authenticating against the US-East endpoint

```Javascript
var client = require('pkgcloud').compute.createClient({
    provider: 'hp',
    username: 'your-user-name',
    apiKey: 'your-api-key',
    region: 'region-b.geo-1',
    authUrl: 'https://region-b.geo-1.identity.hpcloudsvc.com:35357/v2.0/'
});
```

#### region

`region` specifies which region of a service to use. HP has services deployed in multiple regions.
See here for more details : [Regions](http://docs.hpcloud.com/api/identity/#2.2RegionsandAvailabilityZones)
If you're targeting an HP Private Cloud instance, please contact your administrator for region names.

##### Specifying a custom region

```Javascript
var client = require('pkgcloud').compute.createClient({
    provider: 'hp',
    username: 'your-user-name',
    apiKey: 'your-api-key',
    region: 'region-a.custom.corp'
});
```

#### Tokens and Expiration

When you make your first call to a HP provider, your client is authenticated transparent to your API call. HP will issue you a token, with an expiration. When that token expires, the client will automatically re-authenticate and retrieve a new token. The caller shouldn't have to worry about this happening.
