/*
 * volume.js: OpenStack BlockStorage volume
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    base = require('../../core/base'),
    _ = require('underscore');

var Volume = exports.Volume = function Volume(client, details) {
  base.Model.call(this, client, details);
};

utile.inherits(Volume, base.Model);

Volume.prototype._setProperties = function (details) {
  this.id = details.id;
  this.status = details.status;
  this.name = details.name || details['display_name'];
  this.description = details.description || details['display_description'];
  this.createdAt = details['created_at'];
  this.size = details.size;
  this.volumeType = details.volumeType || details['volume_type'];
  this.attachments = details.attachments;
  this.snapshotId = details.snapshotId || details['snapshot_id'];
};

Volume.prototype.toJSON = function () {
  return _.pick(this, ['id', 'status', 'name', 'description', 'createdAt',
    'size', 'volumeType', 'attachments', 'snapshotId']);
};


