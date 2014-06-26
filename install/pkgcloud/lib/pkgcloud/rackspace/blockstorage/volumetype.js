/*
 * volumetype.js: OpenStack Block Storage volume type
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    base = require('../../core/base'),
    _ = require('underscore');

var VolumeType = exports.VolumeType = function VolumeType(client, details) {
  base.Model.call(this, client, details);
};

utile.inherits(VolumeType, base.Model);

VolumeType.prototype._setProperties = function (details) {
  this.id = details.id;
  this.name = details.name;
  this.extra_specs = details.extra_specs;
};

VolumeType.prototype.toJSON = function() {
  return _.pick(this, ['id', 'name', 'extra_specs']);
};
