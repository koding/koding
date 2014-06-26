/*
 * index.js: Top-level include for the Azure compute module
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

exports.Client = require('./client').Client;
exports.Flavor = require('./flavor').Flavor;
exports.Image  = require('./image').Image;
exports.Server = require('./server').Server;

exports.createClient = function (options) {
  return new exports.Client(options);
};
