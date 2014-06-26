/*
 * index.js: Top-level include for the Telefonica compute module
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

exports.Client = require('./client').Client;
exports.Flavor = require('../../joyent/compute/flavor').Flavor;
exports.Image  = require('../../joyent/compute/image').Image;
exports.Server = require('../../joyent/compute/server').Server;

exports.createClient = function (options) {
  return new exports.Client(options);
};
