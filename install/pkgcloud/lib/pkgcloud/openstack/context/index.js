/*
 * index.js: Top-level include for the OpenStack identity module
 *
 * (C) 2013 Nodejitsu Inc.
 *
 */

module.exports = require('./identity');
module.exports.serviceCatalog = require('./serviceCatalog');
module.exports.service = require('./service');
module.exports.ServiceCatalog = module.exports.serviceCatalog.ServiceCatalog;
module.exports.Service = module.exports.service.Service;
