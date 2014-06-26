/*
 * containers.js: Instance methods for working with containers from Azure
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

var async = require('async'),
    request = require('request'),
    base = require('../../../core/storage'),
    pkgcloud = require('../../../../../lib/pkgcloud'),
    storage = pkgcloud.providers.azure.storage;

//
// ### function getContainers (callback)
// #### @callback {function} Continuation to respond to when complete.
// Gets all Rackspace Cloudfiles containers for this instance.
//
exports.getContainers = function (callback) {
  var self = this;

  this._xmlRequest({
    method: 'GET',
    qs: {
      comp: 'list'
    }
  }, function (err, body) {
    if (err) { return callback(err); }

    var containers = self._toArray(body.Containers.Container);

    containers = containers.map(function (container) {
      return new (storage.Container)(self, container);
    });

    callback(null, containers);
  });
};

//
// ### function getContainer (container, callback)
// #### @container {string|storage.Container} Name of the container to return
// #### @callback {function} Continuation to respond to when complete.
// Responds with the Rackspace Cloudfiles container for the specified
// `container`.
//
exports.getContainer = function (container, callback) {
  var containerName = container instanceof storage.Container ? container.name : container,
      self = this,
      options;

  this._xmlRequest({
    method: 'GET',
    path: containerName,
    qs: {
      restype: 'container'
    }
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, new (storage.Container)(self, body));
  });
};

//
// ### function createContainer (options, callback)
// #### @options {string|Container} Container to create in Rackspace Cloudfiles.
// #### @callback {function} Continuation to respond to when complete.
// Creates the specified `container` in the Rackspace Cloudfiles associated
// with this instance.
//
// From Azure docs:
// A container that was recently deleted cannot be recreated until all of
// its blobs are deleted. Depending on how much data was stored within the container,
// complete deletion can take seconds or minutes. If you try to create a container
// of the same name during this cleanup period, your call returns an error immediately.
//
exports.createContainer = function (options, callback) {
  var containerName = options instanceof base.Container ? options.name : options,
      self = this;

  this._xmlRequest({
    method: 'PUT',
    path: containerName,
    qs: {
      restype: 'container'
    }
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, new (storage.Container)(self, options));
  });
};

//
// ### function destroyContainer (container, callback)
// #### @container {string} Name of the container to destroy
// #### @callback {function} Continuation to respond to when complete.
// Destroys the specified `container` and all files in it.
// From Azure docs:
// A container that was recently deleted cannot be recreated until all of
// its blobs are deleted. Depending on how much data was stored within the container,
// complete deletion can take seconds or minutes. If you try to create a container
// of the same name during this cleanup period, your call returns an error immediately.
//
exports.destroyContainer = function (container, callback) {
  var containerName = container instanceof base.Container ? container.name : container,
      self = this;

  this._xmlRequest({
    method: 'DELETE',
    path: containerName,
    qs: {
      restype: 'container'
    }
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, res.statusCode == 202);
   });
};
