/*
 * index.js: Top-level include for the Rackspace Cloud LoadBalancers module
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

exports.Client = require('./client').Client;
exports.LoadBalancer = require('./loadbalancer').LoadBalancer;
exports.Node = require('./node').Node;
exports.Protocols = require('./protocols').Protocols;
exports.VirtualIp = require('./virtualip').VirtualIp;
exports.VirtualIpTypes = require('./virtualip').VirtualIpTypes;

exports.createClient = function (options) {
  return new exports.Client(options);
};
