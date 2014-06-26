/*
 * client.js: Compute client for Rackspace Cloudservers
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    rackspace = require('../../client'),
    StorageClient = require('../../../openstack/storage/storageClient').StorageClient,
    _ = require('underscore');

var Client = exports.Client = function (options) {
  rackspace.Client.call(this, options);

  this.models = {
    Container: require('../container').Container,
    File: require('../file').File
  };

  utile.mixin(this, require('../../../openstack/storage/client/containers'));
  utile.mixin(this, require('../../../openstack/storage/client/files'));
  utile.mixin(this, require('./archive'));
  utile.mixin(this, require('./cdn-containers'));
  utile.mixin(this, require('./files'));

  this.serviceType = 'object-store';
  this.cdnServiceType = 'rax:object-cdn';
};

utile.inherits(Client, rackspace.Client);
_.extend(Client.prototype, StorageClient.prototype);

