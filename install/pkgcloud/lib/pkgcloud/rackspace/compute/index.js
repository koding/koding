  /*
 * index.js: Top-level include for the Rackspace compute module
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

exports.Client = require('./client').Client;
exports.Flavor = require('../../openstack/compute/flavor').Flavor;
exports.Image = require('../../openstack/compute/image').Image;
exports.Server = require('./server').Server;

exports.createClient = function (options) {
  return new exports.Client(options);
};
