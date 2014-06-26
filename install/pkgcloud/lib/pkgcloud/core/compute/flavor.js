/*
 * flavor.js: Base flavor from which all pkgcloud flavors inherit from
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    model = require('../base/model');

var Flavor = exports.Flavor = function (client, details) {
  model.Model.call(this, client, details);
};

utile.inherits(Flavor, model.Model);

Flavor.prototype.refresh = function (callback) {
  return this.client.getFlavor(this, callback);
};
