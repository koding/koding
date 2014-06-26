/*
 * zone.js: Rackspace Cloud DNS Zone
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    base = require('../../core/dns/zone'),
    _ = require('underscore');

var Zone = exports.Zone = function Zone(client, details) {
  base.Zone.call(this, client, details);
};

utile.inherits(Zone, base.Zone);

Zone.prototype._setProperties = function (details) {
  var self = this;

  self.id = details.id;
  self.name = details.name;
  self.accountId = details.accountId;
  self.ttl = details.ttl;
  self.emailAddress = details.emailAddress;
  self.updated = new Date(details.updated);
  self.created = new Date(details.created);
  self.nameservers = details.nameservers || [];

};

Zone.prototype.toJSON = function () {
  return _.pick(this, ['id', 'name', 'description', 'ttl', 'accountId',
    'nameservers', 'emailAddress', 'created', 'updated']);
};
