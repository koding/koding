/*
 * index.js: Top-level include for the HP networking client.
 *
 * (C) 2014 Hewlett-Packard Development Company, L.P.
 *
 */

exports.Client = require('./client').Client;
exports.Network = require('../../openstack/network/network').Network;
exports.Subnet = require('../../openstack/network/subnet').Subnet;
exports.Port = require('../../openstack/network/port').Port;

exports.createClient = function (options) {
  return new exports.Client(options);
};
