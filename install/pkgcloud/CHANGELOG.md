## v0.9.6
* Fixed a long-standing bug in openstack.compute.getFlavor #292

## v0.9.5
* Openstack Network service.
* Added support for HP Cloud provider.
* Added support for Rackspace Storage Temporary URLs

## v0.9.4
* Added support for os-security-groups compute extension

## v0.9.2
* fixed a bug where CDN containers were broken with Rackspace CloudFiles #257

## v0.9.1
* Removing an unnecessary continuity check in openstack identity client
* Switching Debug events to trace events
* Be more explicit with content types for openstack authentication
* Allow passing tenant to the context authenticator
* Fixing the networks property to be on server options for openstack compute

## v0.9.0
* OpenStack Documentation
* Openstack Storage Provider
* fixed a bug with piping downloads from storage services #195
* internal refactor for leaky abstractions
* OpenStack identity client as a proper client

## v0.8.17
* Make default for destroyServer (DigitalOcean) to scrub data #215

## v0.8.16
* Add *beta* support for Rackspace Cloud Load Balancers

## v0.8.15
* Various fixes in openstack/rackspace compute provider
* Added doc updates for rackspace storage provider
* fixed a bug in rackspace dns provider

## v0.8.14
* Added support to specify network in openstack.createServer
* More robust error handling for API inconsistencies in Rackspace/Openstack

## v0.8.13
* Added support for Rackspace Cloud BlockStorage

## v0.8.12
* Changed the callback signature for openstack.identity.getTenantInfo to include body

## v0.8.11
* Added more robust error handling for openstack.identity admin methods

## v0.8.10
* Fixing a bug in rackspace.dns where status call can be an empty response

## v0.8.9
* Fixing a bug when rackspace.dns.createRecord returns an array

## v0.8.8
* Adding support for uploading a tar.gz to Cloud files and extract on upload
* Minor tenant changes for openstack identity providers

## v0.8.7
* Adding Rackspace CloudDNS as a DNS service

## v0.8.5
* Fixing a bug introduced by pre-release services listed in the Openstack Service Catalog

## v0.8.4
* Rackspace provider can now validate token with admin account
* Using through in lieu of pause-stream

## v0.8.3
* Dependency bump for request (2.22.0)
* Support internal Openstack service URLs

## v0.8.2
* Added support for File/Container metadata for Rackspace Storage
* Adding support for Rackspace CDN enabled Containers

## v0.8.1
* Added support for limit/marker options for Rackspace getContainers, getFiles
* removed unused Rackspace.File.rm/ls/cp methods
* Fixed a bug in File.fullPath
* Fixed a bug in Azure header signing

## v0.8.0
* Rewrote Rackspace Client to derive from Openstack Client
* Updated Rackspace & Openstack createClient calls to take a proper URI for authUrl
* Added support to specify region in Rackspace & Openstack createClient options
* Added the ability to automatically re-authenticate on token expiry

## v0.7.3
* Fixed inline authentication for streaming to rackspace/openstack storage #109
* Fixed S3 multi-part upload signing #137
* Optimized S3 upload #124
* Fixed Rackspace authentication to return error on unauthorized #140

## v0.7.2
* Added a pkgcloud User-Agent for outbound HTTP requests #134
* Added tests for core compute method signatures
