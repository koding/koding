## pkgcloud documentation

pkgcloud is a multi-provider cloud provisioning library for node.js that abstracts away differences among multiple cloud providers.

### Unified Vocabulary

Due to the differences between the vocabulary for each service provider, **[pkgcloud uses its own unified vocabulary](vocabulary.md).**

**Note:** Unified vocabularies may not yet be defined for *beta* services.

### Supported Providers

Supporting every API for every cloud service provider in Node.js is a huge undertaking, but _that is the long-term goal of `pkgcloud`_. **Special attention has been made to ensure that each service type has enough providers for a critical mass of portability between providers** (i.e. Each service implemented has multiple providers).

If a service does not have at least two providers, it is considered a *beta* interface; We reserve the right to improve the API as multiple providers will allow generalization to be better determined.

* **Compute** [*Compute Client Commonality*](providers/compute-commonality.md)
  * [Amazon](providers/amazon.md#using-compute)
  * [Azure](providers/azure.md#using-compute)
  * [DigitalOcean](providers/digitalocean.md#using-compute)
  * [HP](providers/hp/compute.md)
  * [Joyent](providers/joyent.md#using-compute)
  * [Openstack](providers/openstack/compute.md)
  * [Rackspace](providers/rackspace/compute.md)
* **Storage**
  * [Amazon](providers/amazon.md#using-storage)
  * [Azure](providers/azure.md#using-storage)
  * [HP](providers/hp/storage.md)
  * [Openstack](providers/openstack/storage.md)
  * [Rackspace](providers/rackspace/storage.md)
* **Databases**
  * [IrisCouch](providers/iriscouch.md)
  * [MongoLab](providers/mongolab.md)
  * [Rackspace](providers/rackspace/database.md)
  * [MongoHQ](providers/mongohq.md)
  * [RedisToGo](providers/redistogo.md)
* **DNS** *(beta)*
  * [Rackspace](providers/rackspace/dns.md)
* **Block Storage** *(beta)*
  * [Rackspace](providers/rackspace/blockstorage.md)
* **Load Balancers** *(beta)*
  * [Rackspace](providers/rackspace/loadbalancer.md)
* **Networking** *(beta)*
    * [Openstack](providers/openstack/network.md)
    * [HP](providers/openstack/hp.md)
