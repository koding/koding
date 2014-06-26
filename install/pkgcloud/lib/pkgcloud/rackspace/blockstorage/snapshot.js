/*
 * volume.js: OpenStack BlockStorage snapshot
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    base = require('../../core/base'),
    _ = require('underscore');

var Snapshot = exports.Snapshot = function Snapshot(client, details) {
  base.Model.call(this, client, details);
};

utile.inherits(Snapshot, base.Model);

Snapshot.prototype._setProperties = function (details) {
  this.id = details.id;
  this.status = details.status;
  this.name = details.name || details['display_name'];
  this.description = details.description || details['display_description'];
  this.createdAt = details['created_at'];
  this.volumeId = details['volume_id'];
  this.size = details.size;
  this.metadata = details.metadata;
};

Snapshot.prototype.toJSON = function () {
  return _.pick(this, ['id', 'status', 'name', 'description', 'createdAt', 'size', 'volumeId', 'metadata']);
};





