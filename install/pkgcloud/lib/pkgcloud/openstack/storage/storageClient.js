/*
 * storageClient.js: A base StorageClient for Openstack &
 * Rackspace storage clients
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var urlJoin = require('url-join'),
    _ = require('underscore');

const CONTAINER_META_PREFIX = 'x-container-meta-';
const CONTAINER_REMOVE_META_PREFIX = 'x-remove-container-meta-';
const OBJECT_META_PREFIX = 'x-object-meta-';
const OBJECT_REMOVE_META_PREFIX = 'x-object-remove-meta-';

var Client = exports.StorageClient = function () {
  this.serviceType = 'object-store';
}

/**
 * client._getUrl
 *
 * @description get the url for the current storage service
 *
 * @param options
 * @returns {exports|*}
 * @private
 */
Client.prototype._getUrl = function (options) {
  options = options || {};

  var fragment = '';

  if (options.container) {
    fragment = encodeURIComponent(options.container);
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

Client.prototype.serializeMetadata = function (prefix, metadata) {

  if (!metadata) {
    return {};
  }

  var serializedMetadata = {};

  _.keys(metadata).forEach(function (key) {
    serializedMetadata[prefix + key] = metadata[key];
  });

  return serializedMetadata;
};

Client.prototype.deserializeMetadata = function (prefix, metadata) {

  if (!metadata) {
    return {};
  }

  var deserializedMetadata = {};

  _.keys(metadata).forEach(function (key) {
    if (key.indexOf(prefix) !== -1) {
      deserializedMetadata[key.split(prefix)[1]] = metadata[key];
    }
  });

  return deserializedMetadata;
};

Client.prototype.CONTAINER_META_PREFIX = CONTAINER_META_PREFIX;
Client.prototype.CONTAINER_REMOVE_META_PREFIX = CONTAINER_REMOVE_META_PREFIX;
Client.prototype.OBJECT_META_PREFIX = OBJECT_META_PREFIX;
Client.prototype.OBJECT_REMOVE_META_PREFIX = OBJECT_REMOVE_META_PREFIX;


