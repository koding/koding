/*
 * networkingClient.js: A base NetworkClient for Openstack networking clients
 *
 * (C) 2014 Hewlett-Packard Development Company, L.P.
 *
 */

var urlJoin = require('url-join'),
    _ = require('underscore');

var Client = exports.NetworkClient = function () {
  this.serviceType = 'network';
};

/**
 * client._getUrl
 *
 * @description get the url for the current network service
 *
 * @param options
 * @returns {exports|*}
 * @private
 */
Client.prototype._getUrl = function (options) {
  options = options || {};
  var fragment = '';

  if (options.network) {
    if (options.method === 'GET') {
      fragment = encodeURIComponent(options.network);
    }
  }

  if (options.path) {
    fragment = urlJoin(fragment, options.path.split('/').map(encodeURIComponent).join('/'));
  }

  var serviceUrl = options.serviceType ? this._identity.getServiceEndpointUrl({
    serviceType: options.serviceType,
    region: this.region
  }) : this._serviceUrl;

  if (fragment === '' || fragment === '/') {
    return serviceUrl;
  }

  return urlJoin(serviceUrl, fragment);

};
