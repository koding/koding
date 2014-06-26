/*
 * index.js: Top-level include for pkgcloud `base` module from which all pkgcloud objects inherit.
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

exports.Client = require('./client').Client;
exports.Model  = require('./model').Model;