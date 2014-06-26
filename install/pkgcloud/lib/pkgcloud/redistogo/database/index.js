/*
 * index.js: Top-level include for the RedisToGo database module
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

exports.Client    = require('./client').Client;

exports.createClient = function createClient(options) {
  return new exports.Client(options);
};
