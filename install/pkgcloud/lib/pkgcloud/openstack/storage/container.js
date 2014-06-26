/*
 * container.js: Openstack Object Storage Container
 *
 * (C) 2013 Rackspace, Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    base = require('../../core/storage/container'),
    _ = require('underscore');

var Container = exports.Container = function Container(client, details) {
  base.Container.call(this, client, details);
};

utile.inherits(Container, base.Container);

Container.prototype.updateMetadata = function (callback) {
  this.client.updateContainerMetadata(this.container, callback);
};

Container.prototype.removeMetadata = function (metadataToRemove, callback) {
  this.client.removeContainerMetadata(this, metadataToRemove, callback);
};

Container.prototype._setProperties = function (details) {
  this.name = details.name || this.name;
  this.ttl = details.ttl || this.ttl;
  this.logRetention = details.logRetention || this.logRetention;
  this.count = details.count || this.count || 0
  this.bytes = details.bytes || this.bytes || 0;
  this.metadata = details.metadata || this.metadata || {};
};

Container.prototype.toJSON = function () {
  return _.pick(this, ['name', 'ttl', 'logRetention', 'count',
    'bytes', 'metadata']);
};



