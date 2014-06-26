/*
 * index.js: Top-level include for the Azure Tables database module
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

exports.Client    = require('./client').Client;

exports.createClient = function createClient(options) {
  return new exports.Client(options);
};
