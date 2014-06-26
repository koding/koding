  /*
 * index.js: Top-level include for the Rackspace storage module
 *
 * (C) 2014 Hewlett-Packard Development Company, L.P.
 * Phani Raj
 *
 */

exports.Client = require('./client').Client;
exports.Flavor = require('../../openstack/compute/flavor').Flavor;
exports.Image = require('../../openstack/compute/image').Image;
exports.Server = require('../../openstack/compute/server').Server;

exports.createClient = function (options) {
  return new exports.Client(options);
};
