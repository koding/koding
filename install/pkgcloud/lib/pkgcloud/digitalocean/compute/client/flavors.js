/*
 * flavors.js: Implementation of DigitalOcean Flavors Client.
 *
 * (C) 2012, Nodejitsu Inc.
 *
 */

var pkgcloud = require('../../../../../lib/pkgcloud'),
    base     = require('../../../core/compute'),
    compute  = pkgcloud.providers.digitalocean.compute;

//
// ### function getFlavors (callback)
// #### @callback {function} f(err, flavors). `flavors` is an array that
// represents the flavors that are available to your account
//
// Lists all flavors available to your account.
//
exports.getFlavors = function getFlavors(callback) {
  var self = this;
  return this._request({
    path: '/sizes'
  }, function (err, body, res) {
    if (err || !body.sizes) {
      return callback(err || new Error('No flavors provided.'));
    }
    
    callback(null, body.sizes.map(function (result) {
      return new compute.Flavor(self, result);
    }), res);    
  });
};

//
// ### function getFlavor (flavor, callback)
// #### @image    {Flavor|String} Flavor ID or an Flavor
// #### @callback {function} f(err, flavor). `flavor` is an object that
// represents the flavor that was retrieved.
//
// Gets a specified flavor of DigitalOcean DataSets using the provided details
// object.
//
exports.getFlavor = function getFlavor(flavor, callback) {
  var flavorId = flavor instanceof base.Flavor ? flavor.id : flavor,
      self     = this;

  return this._request({
    path: '/sizes'
  }, function (err, body, res) {
    if (err || !body.sizes) {
      return callback(err || new Error('No flavors found.'));
    }

    var flavor = body.sizes.filter(function (flavor) {
      return flavor.id == flavorId;
    })[0];
    
    return !flavor
      ? callback(new Error('No flavor found with id: ' + flavorId))
      : callback(null, new Flavor(self, flavor));
  });
};