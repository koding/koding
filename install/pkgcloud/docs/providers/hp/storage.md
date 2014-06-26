![HP Helion icon](http://www8.hp.com/hpnext/sites/default/files/content/documents/HP%20Helion%20Logo_Cloud_Martin%20Fink_New%20Style%20of%20IT_Hewlett-Packard.PNG)

## Using the HP Object Storage provider

* Container
  * [Model](#container-model)
  * [APIs](#container-apis)
* File
  * [Model](#file-model)
  * [APIs](#file-apis)

Creating a client is straight-forward:

``` js
  var hpStorage = pkgcloud.storage.createClient({
    provider: 'hp',
    username: 'your-user-name',
    apiKey: 'your-api-key',
    region: 'region of identity service',
    authUrl: 'https://your-identity-service'
  });
```

Learn about [more options for creating clients](README.md) in the HP `storage` provider.

### Container Model

A Container for HP Object Storage has following properties:

```Javascript
{
  name: 'my-container',
  count: 1, // number of files in your container
  bytes: 12345, // size of the container in bytes
  metadata: { // key value pairs for the container
    // ...
  }
}
```

### File Model

A File for HP Object Storage has the following properties:

```Javascript
{
  name: 'my-file',
  container:  'my-container', // may be an instance of container if provided
  size: 12345, // size of the file in bytes
  contentType: 'plain/text' // Mime type for the file
  lastModified: Fri Dec 14 2012 10:16:50 GMT-0800 (PST), // Last modified date of the file
  etag: '1234567890abcdef', // MD5 sum of the file
  metadata: {} // optional object metadata
}
```

### Container APIs

* [`client.getContainers(function(err, containers) { })`](#clientgetcontainersfunctionerr-containers--)
* [`client.getContainer(container, function(err, container) { })`](#clientgetcontainercontainer-functionerr-container--)
* [`client.createContainer(container, function(err, container) { })`](#clientcreatecontainercontainer-functionerr-container--)
* [`client.destroyContainer(container, function(err, result) { })`](#clientdestroycontainercontainer-functionerr-result--)
* [`client.updateContainerMetadata(container, function(err, container) { })`](#clientupdatecontainermetadatacontainer-functionerr-container--)
* [`client.removeContainerMetadata(container, metadataToRemove, function(err, container) { })`](#clientremovecontainermetadatacontainer-metadatatoremove-functionerr-container--)

### Container API Details

For all of the container methods, you can pass either an instance of [`container`](#container) or the container name as `container`. For example:

```Javascript
client.getContainer('my-container', function(err, container) { ... });
```

This call is functionally equivalent to:

```Javascript
var myContainer = new Container({ name: 'my-container' });

client.getContainer(myContainer, function(err, container) { ... });
```

#### client.getContainers(function(err, containers) { })

Retreives the containers for the current client instance as an array of [`container`](#container-model)

#### client.getContainer(container, function(err, container) { })

Retrieves the specified [`container`](#container-model) from the current client instance.

#### client.createContainer(container, function(err, container) { })

Creates a new [`container`](#container-model) with the name from argument `container`. You can optionally provide `metadata` on the request:

```javascript
client.createContainer({
 name: 'my-container',
 metadata: {
  brand: 'bmw',
  model: '335i'
  year: 2009
 }}, function(err, container) {
  // ...
 })
```

#### client.destroyContainer(container, function(err, result) { })

Removes the [`container`](#container-model) from the storage account. If there are any files within the `container`, they will be deleted before removing the `container` on the client. `result` will be `true` on success.

#### client.updateContainerMetadata(container, function(err, container) { })

Updates the metadata on the provided [`container`](#container-model) . Currently, the `updateContainer` method only adds new metadata fields. If you need to remove specific metadata properties, you should call `client.removeContainerMetadata(...)`.

```javascript
container.metadata.color = 'red';
client.updateContainerMetadata(container, function(err, container) {
  // ...
})
```

#### client.removeContainerMetadata(container, metadataToRemove, function(err, container) { })

Removes the keys in the `metadataToRemove` object from the stored [`container`](#container-model) metadata.

```Javascript
client.removeContainerMetadata(container, { year: false }, function(err, c) {
  // ...
});
```

### File APIs

* [`client.upload(options, function(err, result) { })`](#clientuploadoptions-functionerr-result--)
* [`client.download(options, function(err, file) { })`](#clientdownloadoptions-functionerr-file--)
* [`client.getFile(container, file, function(err, file) { })`](#clientgetfilecontainer-file-functionerr-file--)
* [`client.getFiles(container, function(err, file) { })`](#clientgetfilescontainer-functionerr-file--)
* [`client.removeFile(container, file, function(err, result) { })`](#clientremovefilecontainer-file-functionerr-result--)
* [`client.updateFileMetadata(container, file, function(err, file) { })`](#clientupdatefilemetadatacontainer-file-functionerr-file--)

### File API Details

For all of the file methods, you can pass either an instance of [`container`](#container-model) or the container name as `container`. For example:

```Javascript
client.getFile('my-container', 'my-file', function(err, file) { ... });
```

This call is functionally equivalent to:

```Javascript
var myContainer = new Container({ name: 'my-container' });

client.getFile(myContainer, 'my-file', function(err, file) { ... });
```

#### client.upload(options, function(err, result) { })

Returns a writeable stream. Upload a new file to a [`container`](#container-model). `result` will be `true` on success.

To upload a file, you need to provide an `options` argument:

```Javascript
var options = {
    // required options
    container: 'my-container', // this can be either the name or an instance of container
    remote: 'my-file', // name of the new file

    // optional, either stream or local
    stream: myStream, // any instance of a readable stream
    local: '/path/to/local/file' // a path to any local file

    // Other optional values
    metadata: { // provide any number of property/values for metadata
      campaign: '2012 magazine'
    },
    headers: { // optionally provide raw headers to send to cloud files
      'content-type': 'application/json'
    }
};
```

You need not provide either `stream` or `local`. `client.upload` returns a writeable stream, so you can simply pipe directly into it from your stream. For example:

```Javascript
var fs = require('fs'),
    pkgcloud = require('pkgcloud');

var client = pkgcloud.providers.hp.storage.createClient({ ... });

var myFile = fs.createReadStream('/my/local/file');

myFile.pipe(client.upload({
    container: 'my-container',
    remote: 'my-file'
}, function(err, result) {
    // handle the upload result
}));
```

You could also upload a local file via the `local` property on `options`:

```Javascript
var pkgcloud = require('pkgcloud');

var client = pkgcloud.providers.hp.storage.createClient({ ... });

client.upload({
    container: 'my-container',
    remote: 'my-file',
    local: '/path/to/my/file'
}, function(err, result) {
    // handle the upload result
});
```

This is functionally equivalent to piping from an `fs.createReadStream`, but has a simplified calling convention.

#### client.download(options, function(err, file) { })

Returns a readable stream. Download a [`file`](#file-model) from a [`container`](#container-model).

To download a file, you need to provide an `options` argument:

```Javascript
var options = {
    // required options
    container: 'my-container', // this can be either the name or an instance of container
    remote: 'my-file', // name of the new file

    // optional, either stream or local
    stream: myStream, // any instance of a writeable stream
    local: '/path/to/local/file' // the path to a local file to write to
};
```

You need not provide either `stream` or `local`. `client.download` returns a readable stream, so you can simply pipe it into your writeable stream. For example:

```Javascript
var fs = require('fs'),
    pkgcloud = require('pkgcloud');

var client = pkgcloud.providers.hp.storage.createClient({ ... });

var myFile = fs.createWriteStream('/my/local/file');

client.download({
    container: 'my-container',
    remote: 'my-file'
}, function(err, result) {
    // handle the download result
})).pipe(myFile);
```

You could also download to a local file via the `local` property on `options`:

```Javascript
var pkgcloud = require('pkgcloud');

var client = pkgcloud.providers.hp.storage.createClient({ ... });

client.download({
    container: 'my-container',
    remote: 'my-file',
    local: '/path/to/my/file'
}, function(err, result) {
    // handle the download result
});
```

This is functionally equivalent to piping from an `fs.createWriteStream`, but has a simplified calling convention.

#### client.getFile(container, file, function(err, file) { })

Retrieves the specified [`file`](#file-model) details in the specified [`container`](#container-model) from the current client instance.

#### client.getFiles(container, function(err, files) { })

Retreives an array of [`file`](#file-model) for the provided [`container`](#container-model).

#### client.removeFile(container, file, function(err, result) { })

Removes the provided [`file`](#file-model) from the provided [`container`](#container-model).

#### client.updateFileMetadata(container, file, function(err, file) { })

Updates the [`file`](#file-model) metadata in the the provided [`container`](#container-model).

File metadata is completely replaced with each call to updateFileMetadata. This is different than container metadata. To delete a property, just remove it from the metadata attribute on the `File` and call `updateFileMetadata`.
```javascript
file.metadata = {
 campaign = '2011 website'
};

client.updateFileMetadata(file.container, file, function(err, file) {
  // ...
});
```
