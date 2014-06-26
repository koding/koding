/*
 * index.js: Top-level include from which all pkgcloud dns models inherit.
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

exports.Record = require('./record').Record;
exports.Zone = require('./zone').Zone;