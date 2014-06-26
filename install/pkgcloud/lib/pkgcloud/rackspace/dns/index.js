/*
 * index.js: Top-level include for the Rackspace dns service
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

exports.Client = require('./client').Client;
exports.Record = require('./record').Record;
exports.Status = require('./status').Status;
exports.Zone = require('./zone').Zone;

exports.createClient = function (options) {
  return new exports.Client(options);
};