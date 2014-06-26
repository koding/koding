/*
 * index.js: Top-level include for the OpenStack identity module
 *
 * (C) 2013 Nodejitsu Inc.
 *
 */

exports.Client = require('./client').Client;

exports.createClient = function (options) {
  return new exports.Client(options);
};
