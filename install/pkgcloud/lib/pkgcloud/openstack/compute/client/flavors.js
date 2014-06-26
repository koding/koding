/*
 * flavors.js: Implementation of OpenStack Flavors Client.
 *
 * (C) 2013, Nodejitsu Inc.
 *
 */
var pkgcloud = require('../../../../../lib/pkgcloud'),
    base     = require('../../../core/compute'),
    urlJoin  = require('url-join'),
    compute  = pkgcloud.providers.openstack.compute;

var _urlPrefix = 'flavors';

/**
 * client.getFlavors
 *
 * @description get an array of flavors for the current account
 *
 * @param callback
 * @returns {*}
 */
exports.getFlavors = function(callback) {
  var self = this;

  return this._request({
    path: urlJoin(_urlPrefix, 'detail')
  }, function (err, body) {
    if (err) {
      return callback(err);
    }
    if (!body || !body.flavors) {
      return callback(new Error('Unexpected empty response'));
    }
    else {
      return callback(null, body.flavors.map(function (result) {
        return new compute.Flavor(self, result);
      }));
    }
  });
};

/**
 * client.getFlavor
 *
 * @description get a flavor for the current account
 *
 * @param {String|object}     flavor     the flavor or flavorId to get
 * @param callback
 * @returns {*}
 */
exports.getFlavor = function getFlavor(flavor, callback) {
  var self     = this,
      flavorId = flavor instanceof base.Flavor ? flavor.id : flavor;

  return this._request({
    path: urlJoin(_urlPrefix, flavorId)
  }, function (err, body) {
    if (err) {
      return callback(err);
    }
    if (!body || !body.flavor) {
      return callback(new Error('Unexpected empty response'));
    }
    else {
      return callback(null, new compute.Flavor(self, body.flavor));
    }
  });
};