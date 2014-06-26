# Using DigitalOcean with `pkgcloud`

* [Using Compute](#using-compute)

<a name="using-compute"></a>
## Using Compute

DigitalOcean requires a client ID and API key.

```js
var pkgcloud = require('pkgcloud');
var digitalocean = pkgcloud.compute.createClient({
  provider: 'digitalocean',
  clientId: '<client-id>',
  apiKey: '<api-key>'
});
```
