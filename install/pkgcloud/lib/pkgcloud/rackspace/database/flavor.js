/*
 * flavor.js: Rackspace Cloud Databases flavor
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    base = require('../../openstack/compute/flavor');

var Flavor = exports.Flavor = function Flavor(client, details) {
  base.Flavor.call(this, client, details);
};

utile.inherits(Flavor, base.Flavor);

Flavor.prototype._setProperties = function (details) {
  var selfLink = details.links.filter(function (link) {
    return (link.rel === 'self');
  });
  this.href = selfLink.pop().href;
  this.id = details.id;
  this.name = details.name;
  this.ram = details.ram;
};
