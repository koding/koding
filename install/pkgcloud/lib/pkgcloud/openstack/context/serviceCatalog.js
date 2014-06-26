/*
 * serviceCatalog.js: ServiceCatalog model
 *
 * (C) 2013 Rackspace, Ken Perkins
 * MIT LICENSE
 *
 */

var service = require('./service'),
    Service = require('./service').Service,
    async = require('async'),
    _ = require('underscore');

/**
 * ServiceCatalog class
 *
 * @description wrapper for the service catalog response from keystone
 *
 * @param {object}  catalog     the raw data to parse into the catalog
 * @constructor
 */
var ServiceCatalog = function (catalog) {
  var self = this;

  self.services = {};

  _.each(catalog, function (service) {
    // Special hack for rackspace with two compute types
    if (service.type === 'compute' && service.name === 'cloudServers') {
      return;
    }

    self.services[service.name] = new Service(service);
  });
};

ServiceCatalog.prototype.getServiceEndpointUrl = function(options) {
  var self = this;

  var _endpoint = null;

  _.each(self.services, function(service) {
    if (_endpoint) {
      return;
    }

    _endpoint = service.getEndpointUrl(options);
  });

  if (_endpoint) {
    return _endpoint;
  }
  else {
    throw new Error('Unable to find matching endpoint for requested service');
  }
};


exports.ServiceCatalog = ServiceCatalog;
