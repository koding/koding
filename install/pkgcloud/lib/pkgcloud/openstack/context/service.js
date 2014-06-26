/*
 * service.js: Service model
 *
 * (C) 2013 Rackspace, Ken Perkins
 * MIT LICENSE
 *
 */

var _ = require('underscore');

/**
 * Service class
 *
 * @description The service class is a thin wrapper on an entry in the openstack
 * service catalog
 *
 * @param {object}  details     the data for the new service
 * @param {object}  details.endpoints       the array of endpoints
 * @param {String}  details.name            the name of the service
 * @param {String}  details.type            the type of the new service
 * @constructor
 */
var Service = function (details) {
  var self = this;

  if (!details || typeof details !== 'object') {
    throw new Error('details are a required argument');
  }

  self.endpoints = details.endpoints;
  self.name = details.name;
  self.type = details.type;
};

/**
 * Service.getEndpointUrl
 *
 * @description gets the endpoint URL for a given service, optionally providing
 * the region.
 *
 * @param {object} options              the options for the endpoint call
 * @param {String} [options.region]     a region to use, if provided
 * @param {boolean} [options.useInternal]  prefer an internal endpoint, if available
 * @param {boolean} [options.useAdminUrl]  prefer an admin endpoint, if available
 *
 * @returns {String}            the endpoint uri
 */
Service.prototype.getEndpointUrl = function (options) {
  var self = this,
    url = null;

  options = options || {};
  options.serviceType = options.serviceType || this.type;

  // if the serviceType is wrong, return null
  if (options.serviceType.toLowerCase() !== this.type.toLowerCase()) {
    return '';
  }

  options = options || {};

  if (options.region) {
    _.each(self.endpoints, function (endpoint) {
      if (!endpoint.region || !matchRegion(endpoint.region, options.region)) {
        return;
      }

      url = getUrl(endpoint);
    });
  }
  else {
    _.each(self.endpoints, function(endpoint) {

      if (url) {
        return;
      }

      // return the first region-less endpoint
      if (!endpoint.region) {
        url = getUrl(endpoint);
      }
    });
  }

  /**
   * getUrl
   *
   * @description utility function for getEndpointUrl
   * @param {object} endpoint     the endpoint to use
   * @param {string} [endpoint.internalURL]     the internal URL of the endpoint
   * @param {string} [endpoint.publicURL]       the public URL of the endpoint
   *
   * @returns {String} the uri of the endpoint
   */
  function getUrl(endpoint) {
    var useInternal = typeof options.useInternal === 'boolean' ?
      options.useInternal : false;

    return useInternal && endpoint.internalURL
      ? endpoint.internalURL
      : ((typeof options.useAdmin === 'boolean' && options.useAdmin && endpoint.adminURL) ?
        endpoint.adminURL : endpoint.publicURL);
  }

  if (!url) {
    throw new Error('Unable to identify endpoint url');
  }

  return url;
};

exports.Service = Service;

function matchRegion(a, b) {
  if (!a && !b) {
    return true;
  }
  else if ((!a && b) || (a && !b)) {
    return false;
  }

  return a.toLowerCase() === b.toLowerCase();
}
