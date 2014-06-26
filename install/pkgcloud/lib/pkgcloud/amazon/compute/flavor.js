/*
 * flavor.js: AWS Cloud Package
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    base  = require('../../core/compute/flavor');

var Flavor = exports.Flavor = function Flavor(client, details) {
  base.Flavor.call(this, client, details);
};

utile.inherits(Flavor, base.Flavor);

Flavor.options = {
  'm1.small': { ram: 1.7 * 1024, disk: 160 },
  'm1.medium': { ram: 3.75 * 1024, disk: 410 },
  'm1.large': { ram: 7.5 * 1024, disk: 850 },
  'm1.xlarge': { ram: 15 * 1024, disk: 1690 },
  'c1.medium': { ram: 1.7 * 1024, disk: 350 },
  'c1.xlarge': { ram: 7 * 1024, disk: 1690 },
  'm2.xlarge': { ram: 17.1 * 1024, disk: 420 },
  'm2.2xlarge': { ram: 34.2 * 1024, disk: 850 },
  'm2.4xlarge': { ram: 68.4 * 1024, disk: 1690 },
  'cc1.4xlarge': { ram: 23 * 1024, disk: 1690 },
  'cg1.4xlarge': { ram: 22 * 1024, disk: 1690 },
  'cc2.8xlarge': { ram: 60.5 * 1024, disk: 3370 },
  't1.micro': { ram: 613, disk: 0 }
};

Flavor.prototype._setProperties = function (details) {
  var id = details.name || 'm1.small';

  if (!Flavor.options[id]) throw new TypeError('No such AWS Flavor: ' + id);

  this.id   = id;
  this.name = id;
  this.ram  = Flavor.options[id].ram;
  this.disk = Flavor.options[id].disk;
};
