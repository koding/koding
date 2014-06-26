##Using the Rackspace Block Storage provider

#### BETA - This API may change as additional providers for block storage are added to pkgcloud

Creating a block-storage client is straight-forward:

``` js
  var rackspace = pkgcloud.blockstorage.createClient({
    provider: 'rackspace',
    username: 'your-user-name',
    apiKey: 'your-api-key'
  });
```

[More options for creating clients](README.md)

Note: For **attaching volumes to compute instances**, please see the [compute volume attachments](compute.md#volume-attachments) documentation.

* Volume
  * [Model](#volume-model)
  * [APIs](#volume-apis)
* Snapshot
  * [Model](#snapshot-model)
  * [APIs](#snapshot-apis)
* VolumeType
  * [Model](#volumetype-model)
  * [APIs](#volumetype-apis)

### Volume Model

A Volume for BlockStorage has following properties:

```Javascript
{
  id: '12345678-1111-2222-3333-123456789012', // id of the volume
  name: 'foo3',
  description: 'my volume',
  status: 'available', // status of the volume
  size: 100, // in GB
  volumeType: 'SATA',
  attachments: [], // array of the attachments for this volume
  snapshotId: null, // snapshotId, if any, for this volume
  createdAt: '2013-07-26T15:54:04.000000'
}
```

### Snapshot Model

A Snapshot for BlockStorage has the following properties:

```Javascript
{
  id: '12345678-1111-2222-3333-123456789012', // id of the snapshot
  name: 'foo3',
  description: 'my snapshot',
  status: 'available', // status of the snapshot
  size: 100, // in GB
  volumeId: '12345678-1111-2222-3333-123456789012',
  createdAt: '2013-07-26T15:54:04.000000'
}
```

### VolumeType Model

A VolumeType for BlockStorage has the following properties:

```Javascript
{
  id: '12345678-1111-2222-3333-123456789012', // id of the snapshot
  name: 'SSD',
  extra_specs: {} // not used presently
}
```

### Volume APIs

#### client.getVolumes(options, callback)
Lists all volumes that are available to use on your Rackspace account

Callback returns `f(err, volumes)` where `volumes` is an `Array`. `options` is an optional `boolean` which will return the full volume details if true.

#### client.getVolume(volume, callback)
Gets specified volume.

Takes volume or volumeId as an argument and returns the volume in the callback
`f(err, volume)`

#### client.createVolume(details, callback)
Creates a volume with the details specified

Options are as follows:

```js
{
  name: 'volumeName', // required
  description: 'my volume',  // required
  size: 100,    // 100-1000 gb
  volumeType: 'SSD' // optional, defaults to spindles
  snapshotId: '1234567890' // optional, the snapshotId to use when creating the volume
}
```
Returns the new volume in the callback `f(err, volume)`

#### client.deleteVolume(volume, callback)
Deletes the specified volume

Takes volume or volumeId as an argument and returns an error if unsuccessful `f(err)`

#### client.updateVolume(volume, callback)
Updates the name & description on the provided volume. Does not support resize.

Returns callback with a confirmation

### Snapshot APIs

#### client.getSnapshots(options, callback)
Lists all snapshots that are available to use on your Rackspace account

Callback returns `f(err, snapshots)` where `snapshots` is an `Array`. `options` is an optional `boolean` which will return the full snapshot details if true.

#### client.getSnapshot(snapshot, callback)
Gets specified snapshot.

Takes snapshot or snapshotId as an argument and returns the snapshot in the callback
`f(err, snapshot)`

#### client.createSnapshot(details, callback)
Creates a snapshot with the details specified

Options are as follows:

```js
{
  name: 'volumeName', // required
  description: 'my volume',  // required
  volumeId: 'asdf1234', // required, volume id of the new snapshot
  force: true // optional, defaults to false. force creation of the snapshot
}
```
Returns the new snapshot in the callback `f(err, snapshot)`

#### client.deleteSnapshot(snapshot, callback)
Deletes the specified snapshot

Takes snapshot or snapshotId as an argument and returns an error if unsuccessful `f(err)`

#### client.updateSnapshot(snapshot, callback)
Updates the name & description on the provided snapshot.

Returns callback with a confirmation

### VolumeType APIs

Volume types are used to define which kind of new volume to create.

#### client.getVolumeTypes(callback)
Lists all volumeTypes that are available to use on your Rackspace account

Callback returns `f(err, volumeTypes)` where `volumeTypes` is an `Array`.

#### client.getVolumeType(volumeType, callback)
Gets specified volumeType.

Takes volumeType or volumeTypeId as an argument and returns the volumeType in the callback
`f(err, volumeType)`
