/*
 * containers.js: Instance methods for working with containers
 * for Openstack Object Storage
 *
 * (C) 2013 Rackspace, Ken Perkins
 * MIT LICENSE
 *
 */

var async = require('async'),
    request = require('request'),
  base = require('../../../core/storage'),
    pkgcloud = require('../../../../pkgcloud'),
    _ = require('underscore');

/**
 * client.getContainers
 *
 * @description get the list of containers for an account
 *
 * @param {object|Function}   options
 * @param {Number}            [options.limit]   the number of records to return
 * @param {String}            [options.marker]  Marker value. Operation returns object names that are greater than this value.
 * @param {String}            [options.end_marker]  Operation returns object names that are less than this value.
 * @param {Function}          callback
 */
exports.getContainers = function (options, callback) {
  var self = this;

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  var getContainerOpts = {
    path: '',
    qs: _.extend({
      format: 'json'
    }, _.pick(options, ['limit', 'marker', 'end_marker']))
  };
  ;
  this._request(getContainerOpts, function (err, body) {
    if (err) {
      return callback(err);
    }
    else if (!body || !(body instanceof Array)) {
      return new Error('Malformed API Response')
    }

    return callback(null, body.map(function (container) {
      return new self.models.Container(self, container);
    }));
  });
};

/**
 * client.getContainer
 *
 * @description get the details for a specific container
 *
 * @param {String|object}     container     the container or containerName
 * @param callback
 */
exports.getContainer = function (container, callback) {
  var containerName = container instanceof this.models.Container ? container.name : container,
    self = this;

  this._request({
    method: 'HEAD',
    container: containerName
  }, function (err, body, res) {
    if (err) {
      return callback(err);
    }

    var details = _.extend({}, body, {
      name: containerName,
      count: parseInt(res.headers['x-container-object-count'], 10),
      bytes: parseInt(res.headers['x-container-bytes-used'], 10)
    });

    details.metadata = self.deserializeMetadata(self.CONTAINER_META_PREFIX, res.headers);

    callback(null, new self.models.Container(self, details));
  });
};

/**
 * client.createContainer
 *
 * @description create a new container
 *
 * @param {object}    options
 * @param {String}    options.name      the name of the new container
 * @param {object}    [options.metadata]  optional metadata about the container
 * @param callback
 */
exports.createContainer = function (options, callback) {
  var containerName = typeof options === 'object' ? options.name : options,
      self = this;

  var createContainerOpts = {
    method: 'PUT',
    container: containerName
  };

  if (options.metadata) {
    createContainerOpts.headers = self.serializeMetadata(self.CONTAINER_META_PREFIX, options.metadata);
  }

  this._request(createContainerOpts, function (err) {
    return err
      ? callback(err)
      : callback(null, new self.models.Container(self, { name: containerName, metadata: options.metadata }));
  });
};

/**
 * client.updateContainerMetadata
 *
 * @description Updates the metadata in the specified `container` in
 * the storage container associated with this instance.
 *
 * @param {String|object}     container     the container or containerName
 * @param callback
 */
exports.updateContainerMetadata = function (container, callback) {
  this._updateContainerMetadata(container,
    this.serializeMetadata(this.CONTAINER_META_PREFIX, container.metadata),
    callback);
};

/**
 * client.updateContainerMetadata
 *
 * @description Removes the provided `metadata` in the specified
 * `container` in the storage container associated with this instance.
 *
 * @param {String|object}     container     the container or containerName
 * @param {object}            metadataToRemove     the metadata to remove from the container
 * @param callback
 */
exports.removeContainerMetadata = function (container, metadataToRemove, callback) {
  this._updateContainerMetadata(container,
    this.serializeMetadata(this.CONTAINER_REMOVE_META_PREFIX, metadataToRemove),
    callback);
};

/**
 * client._updateContainerMetadata
 *
 * @description Convenience function for updating container metadata
 */
exports._updateContainerMetadata = function(container, metadata, callback) {
  var self = this;

  if (!(container instanceof self.models.Container)) {
    throw new Error('Must update an existing container instance');
  }

  var updateContainerOpts = {
    method: 'POST',
    container: container.name,
    headers: metadata
  };

  this._request(updateContainerOpts, function (err) {

    // omit our newly deleted header fields, if any
    if (!err) {
      container.metadata = _.omit(container.metadata,
        _.keys(self.deserializeMetadata(self.CONTAINER_REMOVE_META_PREFIX, metadata)));
    }

    return err
      ? callback(err)
      : callback(null, container);
  });
};

/**
 * client.destroyContainer
 *
 * @description Delete the storage container and all files within it
 *
 * @param {String|object}     container     the container or containerName
 * @param callback
 */
exports.destroyContainer = function (container, callback) {
  var containerName = container instanceof this.models.Container ? container.name : container,
      self = this;

  this.getFiles(container, function (err, files) {
    if (err) {
      return callback(err);
    }

    function deleteContainer(err) {
      if (err) {
        return callback(err);
      }

      self._request({
        method: 'DELETE',
        container: containerName
      }, function(err) {
        return err
          ? callback(err)
          : callback(null, true);
      });
    }

    function destroyFile(file, next) {
      file.remove(next);
    }

    if (files.length === 0) {
      return deleteContainer();
    }

    async.forEach(files, destroyFile, deleteContainer);
  });
};
