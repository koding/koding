/*
 * flavors.js: Implementation of Joyent Flavors Client.
 *
 * (C) 2012, Nodejitsu Inc.
 *
 */

var pkgcloud = require('../../../../../lib/pkgcloud'),
    base     = require('../../../core/compute'),
    compute  = pkgcloud.providers.joyent.compute;

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
    path: this.account + '/packages'
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, body.map(function (result) {
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
// Gets a specified flavor of Joyent DataSets using the provided details
// object.
//
exports.getFlavor = function getFlavor(flavor, callback) {
  var self     = this,
      flavorId = flavor instanceof base.Flavor ? flavor.id : flavor;

  // joyent decided to add spaces to their identifiers
  flavorId = encodeURIComponent(flavorId);

  return this._request({
    path: this.account + '/packages/' + flavorId
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, new compute.Flavor(self, body), res);
  });
};