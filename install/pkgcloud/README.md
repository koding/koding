# pkgcloud [![Build Status](https://secure.travis-ci.org/pkgcloud/pkgcloud.png?branch=master)](http://travis-ci.org/pkgcloud/pkgcloud) [![NPM version](https://badge.fury.io/js/pkgcloud.png)](http://badge.fury.io/js/pkgcloud)

pkgcloud is a standard library for node.js that abstracts away differences among multiple cloud providers.

* [Getting started](#getting-started)
  * [Basic APIs](#basic-apis)
  * [Unified Vocabulary](#unified-vocabulary)
  * [Supported APIs](#supported-apis)
* [Compute](#compute)
* [Storage](#storage)
  * [Uploading Files](#uploading)
  * [Downloading Files](#downloading)
* [Database](#databases)
* [DNS](#dns----beta) *(beta)*
* [Block Storage](#block-storage----beta) *(beta)*
* [Load Balancers](#load-balancers----beta) *(beta)*
* [Network](#network----beta) *(beta)*
* _Fine Print_
  * [Installation](#installation)
  * [Tests](#tests)
  * [Logging](#logging)
  * [Code Coverage](#code-coverage)
  * [Contribute!](#contributing)
  * [Roadmap](#roadmap)

<a name="getting-started"></a>
## Getting Started

You can install `pkgcloud` via `npm` or add to it to [dependencies](https://npmjs.org/doc/json.html#dependencies) in your `package.json` file:

```
npm install pkgcloud
```

Currently there are six service types which are handled by pkgcloud:

* [Compute](#compute)
* [Storage](#storage)
* [Database](#databases)
* [DNS](#dns----beta) *(beta)*
* [Block Storage](#block-storage----beta) *(beta)*
* [Load Balancers](#load-balancers----beta) *(beta)*
* [Network](#network----beta) *(beta)*

In our [Roadmap](#roadmap), we plan to add support for more services, such as Queueing, Monitoring, and more. Additionally, we plan to implement more providers for the *beta* services, thus moving them out of *beta*.

<a name="basic-apis"></a>
### Basic APIs for pkgcloud

Services provided by `pkgcloud` are exposed in two ways:

* **By service type:** For example, if you wanted to create an API client to communicate with a compute service you could simply:

``` js
  var client = require('pkgcloud').compute.createClient({
    //
    // The name of the provider (e.g. "joyent")
    //
    provider: 'provider-name',

    //
    // ... Provider specific credentials
    //
  });
```

* **By provider name:** For example, if you knew the name of the provider you wished to communicate with you could do so directly:

``` js
  var client = require('pkgcloud').providers.joyent.compute.createClient({
    //
    // ... Provider specific credentials
    //
  });
```

All API clients exposed by `pkgcloud` can be instantiated through `pkgcloud[serviceType].createClient({ ... })` or `pkcloud.providers[provider][serviceType].createClient({ ... })`.

<a name="unified-vocabulary"></a>
### Unified Vocabulary

Due to the differences between the vocabulary for each service provider, **[pkgcloud uses its own unified vocabulary](docs/vocabulary.md).**

* **Compute:** [Server](#server), [Image](#image), [Flavor](#flavor)
* **Storage:** [Container](#container), [File](#file)
* **DNS:** [Zone](#zone), [Record](#record)

**Note:** Unified vocabularies may not yet be defined for *beta* services.

<a name="supported-apis"></a>
### Supported APIs

Supporting every API for every cloud service provider in Node.js is a huge undertaking, but _that is the long-term goal of `pkgcloud`_. **Special attention has been made to ensure that each service type has enough providers for a critical mass of portability between providers** (i.e. Each service implemented has multiple providers).

If a service does not have at least two providers, it is considered a *beta* interface; We reserve the right to improve the API as multiple providers will allow generalization to be better determined.

* **[Compute](#compute)**
  * [Amazon](docs/providers/amazon.md#using-compute)
  * [Azure](docs/providers/azure.md#using-compute)
  * [DigitalOcean](docs/providers/digitalocean.md#using-compute)
  * [HP](docs/providers/hp/compute.md)
  * [Joyent](docs/providers/joyent.md#using-compute)
  * [Openstack](docs/providers/openstack/compute.md)
  * [Rackspace](docs/providers/rackspace/compute.md)
* **[Storage](#storage)**
  * [Amazon](docs/providers/amazon.md#using-storage)
  * [Azure](docs/providers/azure.md#using-storage)
  * [HP](docs/providers/hp/storage.md)
  * [Openstack](docs/providers/openstack/storage.md)
  * [Rackspace](docs/providers/rackspace/storage.md)
* **[Database](#databases)**
  * [IrisCouch](docs/providers/iriscouch.md)
  * [MongoLab](docs/providers/mongolab.md)
  * [Rackspace](docs/providers/rackspace/database.md)
  * [MongoHQ](docs/providers/mongohq.md)
  * [RedisToGo](docs/providers/redistogo.md)
* **[DNS](#dns----beta)** *(beta)*
  * [Rackspace](docs/providers/rackspace/dns.md)
* **[Block Storage](#block-storage----beta)** *(beta)*
  * [Rackspace](docs/providers/rackspace/blockstorage.md)
* **[Load Balancers](#load-balancers----beta)** *(beta)*
  * [Rackspace](docs/providers/rackspace/loadbalancer.md)
* **[Network](#network----beta)** *(beta)*
    * [HP](docs/providers/hp/network.md)
    * [Openstack](docs/providers/openstack/network.md)

## Compute

The `pkgcloud.compute` service is designed to make it easy to provision and work with VMs. To get started with a `pkgcloud.compute` client just create one:

``` js
  var client = require('pkgcloud').compute.createClient({
    //
    // The name of the provider (e.g. "joyent")
    //
    provider: 'provider-name',

    //
    // ... Provider specific credentials
    //
  });
```

Each compute provider takes different credentials to authenticate; these details about each specific provider can be found below:

* [Amazon](docs/providers/amazon.md#using-compute)
* [Azure](docs/providers/azure.md#using-compute)
* [DigitalOcean](docs/providers/digitalocean.md#using-compute)
* [HP](docs/providers/hp/compute.md)
* [Joyent](docs/providers/joyent.md#using-compute)
* [Openstack](docs/providers/openstack/compute.md)
* [Rackspace](docs/providers/rackspace/compute.md)

Each instance of `pkgcloud.compute.Client` returned from `pkgcloud.compute.createClient` has a set of uniform APIs:

### Server
* `client.getServers(function (err, servers) { })`
* `client.createServer(options, function (err, server) { })`
* `client.destroyServer(serverId, function (err, server) { })`
* `client.getServer(serverId, function (err, server) { })`
* `client.rebootServer(server, function (err, server) { })`

### Image
* `client.getImages(function (err, images) { })`
* `client.getImage(imageId, function (err, image) { })`
* `client.destroyImage(image, function (err, ok) { })`
* `client.createImage(options, function (err, image) { })`

### Flavor
* `client.getFlavors(function (err, flavors) { })`
* `client.getFlavor(flavorId, function (err, flavor) { })`

## Storage

The `pkgcloud.storage` service is designed to make it easy to upload and download files to various infrastructure providers. **_Special attention has been paid so that methods are streams and pipe-capable._**

To get started with a `pkgcloud.storage` client just create one:

``` js
  var client = require('pkgcloud').storage.createClient({
    //
    // The name of the provider (e.g. "joyent")
    //
    provider: 'provider-name',

    //
    // ... Provider specific credentials
    //
  });
```

Each storage provider takes different credentials to authenticate; these details about each specific provider can be found below:

* [Amazon](docs/providers/amazon.md#using-storage)
* [Azure](docs/providers/azure.md#using-storage)
* [HP](docs/providers/hp/storage.md)
* [Openstack](docs/providers/openstack/storage.md)
* [Rackspace](docs/providers/rackspace/storage.md)

Each instance of `pkgcloud.storage.Client` returned from `pkgcloud.storage.createClient` has a set of uniform APIs:

### Container
* `client.getContainers(function (err, containers) { })`
* `client.createContainer(options, function (err, container) { })`
* `client.destroyContainer(containerName, function (err) { })`
* `client.getContainer(containerName, function (err, container) { })`

### File
* `client.upload(options, function (err) { })`
* `client.download(options, function (err) { })`
* `client.getFiles(container, function (err, files) { })`
* `client.getFile(container, file, function (err, server) { })`
* `client.removeFile(container, file, function (err) { })`

Both the `.upload(options)` and `.download(options)` have had **careful attention paid to make sure they are pipe and stream capable:**

### Upload a File
``` js
  var pkgcloud = require('pkgcloud'),
      fs = require('fs');

  var client = pkgcloud.storage.createClient({ /* ... */ });

  fs.createReadStream('a-file.txt').pipe(client.upload({
    container: 'a-container',
    remote: 'remote-file-name.txt'
  }));
```

### Download a File
``` js
  var pkgcloud = require('pkgcloud'),
      fs = require('fs');

  var client = pkgcloud.storage.createClient({ /* ... */ });

  client.download({
    container: 'a-container',
    remote: 'remote-file-name.txt'
  }).pipe(fs.createWriteStream('a-file.txt'));
```

## Databases

The `pkgcloud.database` service is designed to consistently work with a variety of Database-as-a-Service (DBaaS) providers.

To get started with a `pkgcloud.storage` client just create one:

``` js
  var client = require('pkgcloud').database.createClient({
    //
    // The name of the provider (e.g. "joyent")
    //
    provider: 'provider-name',

    //
    // ... Provider specific credentials
    //
  });
```

Each database provider takes different credentials to authenticate; these details about each specific provider can be found below:

* **CouchDB**
  * [IrisCouch](docs/providers/iriscouch.md#couchdb)
* **MongoDB**
  * [MongoLab](docs/providers/mongolab.md)
  * [MongoHQ](docs/providers/mongohq.md)
* **Redis**
  * [IrisCouch](docs/providers/iriscouch.md#redis)
  * [RedisToGo](docs/providers/redistogo.md)
* **MySQL**
  * [Rackspace](docs/providers/rackspace/databases.md)
* **Azure Tables**
  * [Azure](docs/providers/azure.md#database)

Due to the various differences in how these DBaaS providers provision databases only a small surface area of the API for instances of `pkgcloud.database.Client` returned from `pkgcloud.database.createClient` is consistent across all providers:

* `client.create(options, callback)`

All of the individual methods are documented for each DBaaS provider listed above.

## DNS -- Beta

##### Note: DNS is considered Beta until there are multiple providers; presently only Rackspace are supported.

The `pkgcloud.dns` service is designed to make it easy to manage DNS zones and records on various infrastructure providers. **_Special attention has been paid so that methods are streams and pipe-capable._**

To get started with a `pkgcloud.dns` client just create one:

``` js
  var client = require('pkgcloud').dns.createClient({
    //
    // The name of the provider (e.g. "rackspace")
    //
    provider: 'provider-name',

    //
    // ... Provider specific credentials
    //
  });
```

#### Providers

* [Rackspace](docs/providers/rackspace/dns.md)

Each instance of `pkgcloud.dns.Client` returned from `pkgcloud.dns.createClient` has a set of uniform APIs:

### Zone
* `client.getZones(details, function (err, zones) { })`
* `client.getZone(zone, function (err, zone) { })`
* `client.createZone(details, function (err, zone) { })`
* `client.updateZone(zone, function (err) { })`
* `client.deleteZone(zone, function (err) { })`

### Record
* `client.getRecords(zone, function (err, records) { })`
* `client.getRecord(zone, record, function (err, record) { })`
* `client.createRecord(zone, record, function (err, record) { })`
* `client.updateRecord(zone, record, function (err, record) { })`
* `client.deleteRecord(zone, record, function (err) { })`

## Block Storage -- Beta

##### Note: Block Storage is considered Beta until there are multiple providers; presently only Rackspace are supported.

The `pkgcloud.blockstorage` service is designed to make it easy to create and manage block storage volumes and snapshots.

To get started with a `pkgcloud.blockstorage` client just create one:

``` js
  var client = require('pkgcloud').blockstorage.createClient({
    //
    // The name of the provider (e.g. "rackspace")
    //
    provider: 'provider-name',

    //
    // ... Provider specific credentials
    //
  });
```

#### Providers

* [Rackspace](docs/providers/rackspace/blockstorage.md)

Each instance of `pkgcloud.blockstorage.Client` returned from `pkgcloud.blockstorage.createClient` has a set of uniform APIs:

### Volume
* `client.getVolumes(options, function (err, volumes) { })`
* `client.getVolume(volume, function (err, volume) { })`
* `client.createVolume(details, function (err, volume) { })`
* `client.updateVolume(volume, function (err, volume) { })`
* `client.deleteVolume(volume, function (err) { })`

### Snapshot
* `client.getSnapshots(options, function (err, snapshots) { })`
* `client.getSnapshot(snapshot, function (err, snapshot) { })`
* `client.createSnapshot(details, function (err, snapshot) { })`
* `client.updateSnapshot(snapshot, function (err, snapshot) { })`
* `client.deleteSnapshot(snapshot, function (err) { })`

## Load Balancers -- Beta

##### Note: Load Balancers is considered Beta until there are multiple providers; presently only Rackspace are supported.

The `pkgcloud.loadbalancer` service is designed to make it easy to create and manage block storage volumes and snapshots.

To get started with a `pkgcloud.loadbalancer` client just create one:

``` js
  var client = require('pkgcloud').loadbalancer.createClient({
    //
    // The name of the provider (e.g. "rackspace")
    //
    provider: 'provider-name',

    //
    // ... Provider specific credentials
    //
  });
```

#### Providers

* [Rackspace](docs/providers/rackspace/loadbalancer.md)

Each instance of `pkgcloud.loadbalancer.Client` returned from `pkgcloud.loadbalancer.createClient` has a set of uniform APIs:

### LoadBalancers
* `client.getLoadBalancers(options, function (err, loadBalancers) { })`
* `client.getLoadBalancer(loadBalancer, function (err, loadBalancer) { })`
* `client.createLoadBalancer(details, function (err, loadBalancer) { })`
* `client.updateLoadBalancer(loadBalancer, function (err) { })`
* `client.deleteLoadBalancer(loadBalancer, function (err) { })`

### Nodes
* `client.getNodes(loadBalancer, function (err, nodes) { })`
* `client.addNodes(loadBalancer, nodes, function (err, nodes) { })`
* `client.updateNode(loadBalancer, node, function (err) { })`
* `client.removeNode(loadBalancer, node, function (err) { })`

## Network -- Beta

##### Note: Network is considered Beta until there are multiple providers; presently only HP & Openstack providers are supported.

The `pkgcloud.network` service is designed to make it easy to create and manage networks.

To get started with a `pkgcloud.network` client just create one:

``` js
  var client = require('pkgcloud').network.createClient({
    //
    // The name of the provider (e.g. "openstack")
    //
    provider: 'provider-name',

    //
    // ... Provider specific credentials
    //
  });
```

#### Providers

* [HP](docs/providers/hp/network.md)
* [Openstack](docs/providers/openstack/network.md)


Each instance of `pkgcloud.network.Client` returned from `pkgcloud.network.createClient` has a set of uniform APIs:

### Networks
* `client.getNetworks(options, function (err, networks) { })`
* `client.getNetwork(network, function (err, network) { })`
* `client.createNetwork(options, function (err, network) { })`
* `client.updateNetwork(network, function (err, network) { })`
* `client.deleteNetwork(network, function (err, networkId) { })`


### Subnets
* `client.getSubnets(options, function (err, subnets) { })`
* `client.getSubnet(subnet, function (err, subnet) { })`
* `client.createSubnet(options, function (err, subnet) { })`
* `client.updateSubnet(subnet, function (err, subnet) { })`
* `client.deleteSubnet(subnet, function (err, subnetId) { })`

### Ports
* `client.getPorts(options, function (err, ports) { })`
* `client.getPort(port, function (err, port) { })`
* `client.createPort(options, function (err, port) { })`
* `client.updatePort(port, function (err, port) { })`
* `client.deletePort(port, function (err, portId) { })`

## Installation

``` bash
  $ npm install pkgcloud
```

## Tests
For run the tests you will need `mocha@1.9.x` or higher, please install it and then run:

``` bash
 $ npm test
```

The tests use the [`hock`](https://github.com/mmalecki/hock) library for mock up the response of providers, so the tests run without do any connection to the providers, there is a notorius advantage of speed on that, also you can run the tests without Internet connection and also can highlight a change of API just disabling `hock`.


### Running tests without mocks
By default the `npm test` command run the tests enabling `hock`. And sometimes you will want to test against the live provider, so you need to do this steps, in order to test without mocks.

1. Copy a provider config file from `test/configs/mock` to `test/configs`
2. Fill in with your own credentials for the provider.
3. (Optional) The compute test suite run the common tests for all providers listed on `test/configs/providers.json`, there you can enable or disable providers.
4. Run the tests using mocha.

``` bash
Mocha installed globally
 $ mocha -R spec test/*/*/*-test.js test/*/*/*/*-test.js

Linux/Mac - Mocha installed locally
 $ ./node_modules/.bin/mocha -R spec test/*/*/*-test.js test/*/*/*/*-test.js

Windows - Mocha installed locally:
 $ node_modules\.bin\mocha.cmd -R spec test/*/*/*-test.js test/*/*/*/*-test.js

```

### Other ways to run the tests
Also you can run the tests directly using `mocha` with `hock` enabled:

``` bash
Linux/Mac - Mocha installed globally:
 $ MOCK=on mocha -R spec test/*/*/*-test.js test/*/*/*/*-test.js

Linux/Mac - Mocha installed locally:
 $ MOCK=on node_modules/.bin/mocha -R spec test/*/*/*-test.js test/*/*/*/*-test.js

Windows - Mocha installed globally:
 $ set MOCK=on&mocha -R spec test/*/*/*-test.js test/*/*/*/*-test.js

Windows - Mocha installed locally:
 $ set MOCK=on&node_modules\.bin\mocha.cmd -R spec test/*/*/*-test.js test/*/*/*/*-test.js
```

Even better, you can run the tests for some specific provider:

``` bash
Linux/Mac - Mocha installed globally:
 $ MOCK=on mocha -R spec test/iriscouch/*/*-test.js

Linux/Mac - Mocha installed locally:
 $ MOCK=on ./node_modules/.bin/mocha -R spec test/iriscouch/*/*-test.js

Windows - Mocha installed globally:
 $ set MOCK=on&mocha -R spec test/iriscouch/*/*-test.js

Windows - Mocha installed locally:
 $ set MOCK=on&node_modules\.bin\mocha.cmd -R spec test/iriscouch/*/*-test.js

```

## Logging
Any client you create with `createClient` can emit logging events. If you're interested in more detail from the internals of `pkgcloud`, you can wire up an event handler for log events.

```Javascript
var client = pkgcloud.compute.createClient(options);

client.on('log::*', function(message, object) {
  if (object) {
   console.log(this.event.split('::')[1] + ' ' + message)
   console.dir(object);
  }
  else {
    console.log(this.event.split('::')[1]  + ' ' + message);
  }
});

```

The valid log events raised are `log::debug`, `log::verbose`, `log::info`, `log::warn`, and `log::error`. There is also a [more detailed logging example using pkgcloud with Winston](docs/logging-with-winston.md).

## Code Coverage
You will need jscoverage installed in order to run code coverage.  There seems to be many forks of the jscoverage project, but the recommended one is [node-jscoverage](https://github.com/visionmedia/node-jscoverage), because we use [node-coveralls](https://github.com/cainus/node-coveralls) to report coverage to http://coveralls.io.  node-coveralls requires output from [mocha-lcov-reporter](https://github.com/StevenLooman/mocha-lcov-reporter), whose documentation mentions node-jscoverage.

### Warning

**Running coverage will mess with your lib folder.  It will make a backup lib-bak before running and restore it if the coverage task runs successfully.**

In order to simplify cleanup if something goes wrong, it is recommended to have all all new files added and all changes committed before running coverage, so you'll be able to restore with these commands if something goes wrong:

``` bash
git clean -fd
git checkout lib
```

### Coverage Pre-requisites

Please make sure jscoverage has been installed following the instructions at [node-jscoverage](https://github.com/visionmedia/node-jscoverage).

### Local Coverage

<code>make test-cov</code>

### Run Coverage locally and send to coveralls.io

Travis takes care of coveralls, so this shouldn't be necessary unless you're troubleshooting a problem with Travis/Coveralls.
You'll need to have access to the coveralls repo_token, which should only be visible to pkgcloud/pkgcloud admins.

1. Create a .coveralls.yml containing the repo_token from https://coveralls.io/r/pkgcloud/pkgcloud
2. Run <code>make test-coveralls</code>

<a name="contributing"></a>
## Contribute!
We welcome contribution to `pkgcloud` by any and all individuals or organizations. Before contributing please take a look at the [Contribution Guidelines in CONTRIBUTING.md](CONTRIBUTING.md).

We are pretty flexible about these guidelines, but the closer you follow them the more likely we are to merge your pull-request.

<a name="roadmap"></a>
## Roadmap

1. Backport latest fixes from `node-cloudfiles` and `node-cloudservers`
2. Implement more providers for Block Storage, DNS, and Load Balancing
3. Add more services: Monitoring, Queueing, Autoscale.
4. Implement `fs` compatible file API.
5. Support additional service providers.

#### Author: [Nodejitsu Inc.](http://nodejitsu.com)
#### Contributors: [Charlie Robbins](https://github.com/indexzero), [Nuno Job](https://github.com/dscape), [Daniel Aristizabal](https://github.com/cronopio), [Marak Squires](https://github.com/marak), [Dale Stammen](https://github.com/stammen), [Ken Perkins](https://github.com/kenperkins)
#### License: MIT
