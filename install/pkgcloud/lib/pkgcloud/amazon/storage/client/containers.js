/*
 * containers.js: Instance methods for working with containers from AWS S3
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var async = require('async'),
  request = require('request'),
  base = require('../../../core/storage'),
  pkgcloud = require('../../../../../lib/pkgcloud'),
  storage = pkgcloud.providers.amazon.storage;

//
// ### function getContainers (callback)
// #### @callback {function} Continuation to respond to when complete.
// Gets all AWS S3 containers for this instance.
//
exports.getContainers = function (callback) {
  var self = this;

  this._xmlRequest({
    path: '/'
  }, function (err, body) {
    if (err) {
      return callback(err);
    }

    var containers = self._toArray(body.Buckets.Bucket);

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
// Responds with the AWS S3 container for the specified
// `container`.
//
exports.getContainer = function (container, callback) {
  var containerName = container instanceof storage.Container ? container.name : container,
    self = this;

  this._xmlRequest({
    container: containerName
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(null, new (storage.Container)(self, body));
  });
};

//
// ### function createContainer (options, callback)
// #### @options {string|Container} Container to create in AWS S3.
// #### @callback {function} Continuation to respond to when complete.
// Creates the specified `container` in AWS S3 account associated
// with this instance.
//
exports.createContainer = function (options, callback) {
  var containerName = options instanceof base.Container ? options.name : options,
    self = this;

  this._xmlRequest({
    method: 'PUT',
    container: containerName
  }, function (err) {
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
//
exports.destroyContainer = function (container, callback) {
  var containerName = container instanceof base.Container ? container.name : container,
    self = this;

  this.getFiles(containerName, false, function (err, files) {
    if (err) {
      return callback(err);
    }

    function deleteContainer(err) {
      if (err) {
        return callback(err);
      }

      self._xmlRequest({
          method: 'DELETE',
          container: containerName
        }, function (err, body, res) {
          return err
            ? callback(err)
            : callback(null, res.statusCode == 204);
        }
      );
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
