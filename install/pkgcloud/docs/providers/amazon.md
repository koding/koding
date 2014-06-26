# Using Amazon Web Services (aws) with `pkgcloud`

* [Using Compute](#using-compute)
* [Using Storage](#using-storage)

<a name="using-compute"></a>
## Using Compute

``` js
  var amazon = pkgcloud.compute.createClient({
    provider: 'amazon',
    key: 'asdfkjas;dkj43498aj3n',
    keyId: '98kja34lkj'
  });
```

<a name="using-storage"></a>
## Using Storage

``` js
  var amazon = pkgcloud.storage.createClient({
    provider: 'amazon', // 'aws', 's3'
    key: 'asdfkjas;dkj43498aj3n',
    keyId: '98kja34lkj'
  });
```
