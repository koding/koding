/*
 * record.js: Rackspace Cloud DNS Record
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    base = require('../../core/dns/record'),
    _ = require('underscore');

var Record = exports.Record = function Record(zone, details) {
  base.Record.call(this, zone, details);
};

utile.inherits(Record, base.Record);

Record.prototype._setProperties = function (details) {
  var self = this;
  self.id = details.id;
  self.name = details.name;
  self.type = details.type;
  self.data = details.data;
  self.ttl = details.ttl;
  self.updated = new Date(details.updated);
  self.created = new Date(details.created);
};

Record.prototype.toJSON = function () {
  return _.pick(this, ['id', 'name', 'type', 'ttl', 'data',
    'created', 'updated']);
};
