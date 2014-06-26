/*
 * index.js: Top-level include for the Rackspace database module
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

exports.Client    = require('./client').Client;
exports.Flavor    = require('./flavor').Flavor;
exports.Instance  = require('./instance').Instance;
exports.Database  = require('./database').Database;
exports.User      = require('./user').User;

exports.createClient = function createClient(options) {
  return new exports.Client(options);
};
