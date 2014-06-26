/*
 * index.js: Top-level include for the Azure module
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

exports.Client = require('./client').Client;
exports.Container = require('./container').Container;
exports.File  = require('./file').File;
exports.ChunkedStream  = require('./utils').ChunkedStream;

exports.createClient = function (options) {
  return new exports.Client(options);
};
