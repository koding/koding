/*
 * index.js: Storage client for HP Cloudservers
 *
 * (C) 2014 Hewlett-Packard Development Company, L.P.
 * Phani Raj
 *
 */

var utile = require('utile'),
    hp = require('../../client'),
    StorageClient = require('../../../openstack/storage/storageClient').StorageClient,
    _ = require('underscore');

var Client = exports.Client = function (options) {
  hp.Client.call(this, options);

  this.models = {
    Container: require('../../../openstack/storage/container').Container,
    File: require('../../../openstack/storage/file').File
  };

  utile.mixin(this, require('../../../openstack/storage/client/containers'));
  utile.mixin(this, require('../../../openstack/storage/client/files'));

  this.serviceType = 'object-store';
};

utile.inherits(Client, hp.Client);
_.extend(Client.prototype, StorageClient.prototype);
