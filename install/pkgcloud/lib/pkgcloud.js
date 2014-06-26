/*
 * pkgcloud.js: Top-level include for the pkgcloud module
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var path = require('path');

var pkgcloud = exports;

require('pkginfo')(module, 'version');

var components = [
  './pkgcloud/core/base',
  './pkgcloud/common',
  './pkgcloud/core/compute',
  './pkgcloud/core/storage'
];

var providers = [
  'amazon',
  'azure',
  'digitalocean',
  'iriscouch',
  'joyent',
  'mongohq',
  'mongolab',
  'openstack',
  'rackspace',
  'redistogo',
  'telefonica',
  'hp'
];

var services = [
  'blockstorage',
  'compute',
  'cdn',
  'database',
  'dns',
  'loadbalancer',
  'network',
  'storage'
];

//
// Setup lazy-loaded exports for faster loading
//
components.forEach(function (component) {
  var name = path.basename(component),
      hidden = '_' + name;

  pkgcloud.__defineGetter__(name, function () {
    if (!pkgcloud[hidden]) {
      pkgcloud[hidden] = require(component);
    }

    return pkgcloud[hidden];
  });
});

//
// Initialize our providers
//
pkgcloud.providers = {};

//
// Setup empty exports to be populated later
//
services.forEach(function (key) {
  pkgcloud[key] = {};
});

//
// Setup core `pkgcloud.*.createClient` methods for all
// provider functionality.
//
services.forEach(function (service) {
  pkgcloud[service].createClient = function (options) {
    if (!options.provider) {
      throw new Error('options.provider is required to create a new pkgcloud client.');
    }

    var provider = pkgcloud.providers[options.provider];

    if (!provider) {
      throw new Error(options.provider + ' is not a supported provider');
    }

    if (!provider[service]) {
      throw new Error(options.provider + ' does not expose a ' + service + ' service');
    }

    return new provider[service].createClient(options);
  };
});

//
// Setup all providers as lazy-loaded getters
//
providers.forEach(function (provider) {
  pkgcloud.providers.__defineGetter__(provider, function () {
    return require('./pkgcloud/' + provider);
  });
});
