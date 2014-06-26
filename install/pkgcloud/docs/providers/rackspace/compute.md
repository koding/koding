##Using the Rackspace Compute provider

As of the `v0.8` release of `pkgcloud`, the Compute provider uses Next Generation Cloud Servers, meaning you'll need to use a version <=0.7.x to use First Generation Cloud Servers.

Creating a client is straight-forward:

``` js
  var rackspace = pkgcloud.compute.createClient({
    provider: 'rackspace',
    username: 'your-user-name',
    apiKey: 'your-api-key'
  });
```

[More options for creating clients](README.md)

### API Methods

**Servers**

#### client.getServers(callback)
Lists all servers that are available to use on your Rackspace account

Callback returns `f(err, servers)` where `servers` is an `Array`

#### client.createServer(options, callback)
Creates a server with the options specified

Options are as follows:

```js
{
  name: 'serverName', // required
  flavor: 'flavor1',  // required
  image: 'image1',    // required
  personality: []     // optional
}
```
Returns the server in the callback `f(err, server)`

#### client.destroyServer(server, callback)
Destroys the specified server

Takes server or serverId as an argument  and returns the id of the destroyed server in the callback `f(err, serverId)`

#### client.getServer(server, callback)
Gets specified server

Takes server or serverId as an argument and returns the server in the callback
`f(err, server)`

#### client.rebootServer(server, options, callback)
Reboots the specifed server with options

Options include:

```js
{
  type: 'HARD' // optional (defaults to 'SOFT')
}
```
Returns callback with a confirmation

#### client.getVersion(callback)

Get the current version of the api returned in a callback `f(err, version)`

#### client.getLimits(callback)

Get the current API limits returned in a callback `f(err, limits)`

**flavors**

#### client.getFlavors(callback)

Returns a list of all possible server flavors available in the callback `f(err,
flavors)`

#### client.getFlavor(flavor, callback)
Returns the specified rackspace flavor of Rackspace Images by ID or flavor
object in the callback `f(err, flavor)`

**images**

#### client.getImages(callback)
Returns a list of the images available for your account

`f(err, images)`

#### client.getImage(image, callback)
Returns the image specified

`f(err, image)`

#### client.createImage(options, callback)
Creates an Image based on a server

Options include:

```js
{
  name: 'imageName',  // required
  server: 'serverId'  // required
}
```

Returns the newly created image

`f(err, image)`

#### client.destroyImage(image, callback)
Destroys the specified image and returns a confirmation

`f(err, {ok: imageId})`

## Volume Attachments

Attaching a volume to a compute instance requires using a rackspace compute client, as well as possessing a `volume` or `volumeId`. Detaching volumes behaves the same way.

#### client.getVolumeAttachments(server, callback)

Gets an array of volumeAttachments for the provided server.

`f(err, volumeAttachments)`

#### client.getVolumeAttachmentDetails(server, attachment, callback)

Gets the details for a provided server and attachment. `attachment` may either be the `attachmentId` or an object with `attachmentId` as a property.

`f(err, volumeAttachment)`

#### client.attachVolume(server, volume, callback)

Attaches the provided `volume` to the `server`. `volume` may either be the `volumeId` or an instance of `Volume`.

`f(err, volumeAttachment)`

#### client.detachVolume(server, attachment, callback)

Detaches the provided `attachment` from the server. `attachment` may either be the `attachmentId` or an object with `attachmentId` as a property. If the `volume` is mounted this call will return an err.

`f(err)`