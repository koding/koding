/*
 * flavors.js: Implementation of Azure Flavors Client.
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

var pkgcloud = require('../../../../../lib/pkgcloud'),
    base     = require('../../../core/compute'),
    compute  = pkgcloud.providers.azure.compute;

//
// ### function getFlavors (callback)
// #### @callback {function} f(err, flavors). `flavors` is an array that
// represents the flavors that are available to your account
//
// Lists all flavors available to your account.
//
exports.getFlavors = function getFlavors(callback) {
  var self = this;

  callback(null, Object.keys(compute.Flavor.options).map(function (name) {
    return new compute.Flavor(self, { name: name });
  }));
};

//
// ### function getFlavor (flavor, callback)
// #### @image    {Flavor|String} Flavor ID or an Flavor
// #### @callback {function} f(err, flavor). `flavor` is an object that
// represents the flavor that was retrieved.
//
// Gets a specified flavor of AWS DataSets using the provided details
// object.
//
exports.getFlavor = function getFlavor(flavor, callback) {
  var flavorId = flavor instanceof base.Flavor ? flavor.id : flavor;

  if (flavor instanceof base.Flavor) {
    return callback(null, flavor);
  }

  callback(null, new compute.Flavor(this, { id : flavorId }));
};
