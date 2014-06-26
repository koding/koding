/*
 * flavors.js: Implementation of Rackspace Flavors Client.
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var pkgcloud = require('../../../../../lib/pkgcloud'),
    Flavor   = pkgcloud.providers.rackspace.database.Flavor;

// Get Flavors
// Get the list of flavors in an array of Flavor's instances'
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
    path: 'flavors'
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(null, body.flavors.map(function (result) {
          return new Flavor(self, result);
        }));
  });
};

//
// ### function getFlavor (flavor, callback)
// #### @image    {Flavor|String} Flavor ID or an Flavor
// #### @callback {function} f(err, flavor). `flavor` is an object that
// represents the flavor that was retrieved.
//
// Gets a specified flavor of Rackspace Images using the provided details
// object.
//
exports.getFlavor = function getFlavor(id, callback) {
  var self = this;
  return this._request({
    path: 'flavors/' + id
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(null, new Flavor(self, body.flavor));
  });
};
