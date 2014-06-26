/*
 * images.js: Implementation of OpenStack Images Client.
 *
 * (C) 2013, Nodejitsu Inc.
 *
 */
var pkgcloud = require('../../../../../lib/pkgcloud'),
    base     = require('../../../core/compute'),
    urlJoin  = require('url-join'),
    compute  = pkgcloud.providers.openstack.compute;

var _urlPrefix = 'images';

/**
 * client.getImages
 *
 * @description get an array of images for the current account
 *
 * @param callback
 * @returns {*}
 */
exports.getImages = function getImages(options, callback) {
  var self = this;

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  return this._request({
    path: urlJoin(_urlPrefix, 'detail')
  }, function (err, body) {
    if (err) {
      return callback(err);
    }
    if (!body || ! body.images) {
      return callback(new Error('Unexpected empty response'));
    }
    else {
      return callback(null, body.images.map(function (result) {
        return new compute.Image(self, result);
      }));
    }
  });
};

/**
 * client.getImage
 *
 * @description get an image for the current account
 *
 * @param {String|object}     image     the image or imageId to get
 * @param callback
 * @returns {*}
 */
exports.getImage = function getImage(image, callback) {
  var self    = this,
      imageId = image instanceof base.Image ? image.id : image;

  return this._request({
    path: urlJoin(_urlPrefix, imageId)
  }, function (err, body) {
    if (err) {
      return callback(err);
    }
    if (!body || !body.image) {
      return callback(new Error('Unexpected empty response'));
    }
    else {
      return callback(null, new compute.Image(self, body.image));
    }
  });
};

/**
 * client.createImage
 *
 * @description create an image for a provided server
 *
 * @param {object}          options
 * @param {String|object}   options.server    the server or serverId to create the image from
 * @param {String}          options.name      the name of the new image
 * @param {object}          [options.metadata]  optional metadata about the new image
 * @param callback
 * @returns {*}
 */
exports.createImage = function createImage(options, callback) {
  var self = this,
      serverId;

  serverId = options.server instanceof compute.Server
    ? options.server.id
    : options.server;

  var createOptions = {
    createImage: { name: options.name }
  };

  if (options.metadata) {
    createOptions.createImage.metadata = options.metadata;
  }

  return this._doServerAction.call(this, serverId, createOptions, function (err, body, res) {
    if (err) {
      return callback(err);
    }

    return self._request({
      uri: res.headers.location
    }, function(err, body) {
      if (err) {
        return callback(err);
      }
      if (!body || !body.image) {
        return callback(new Error('Unexpected empty response'));
      }
      else {
        return callback(null, new compute.Image(self, body.image));
      }
    });
  });
};

/**
 * client.destroyImage
 *
 * @description delete the provided image
 *
 * @param {String|object}     image     the image or imageId to get
 * @param callback
 * @returns {*}
 */
exports.destroyImage = function destroyImage(image, callback) {
  var imageId = image instanceof compute.Image ? image.id : image;

  return this._request({
      path: urlJoin(_urlPrefix, imageId),
      method: 'DELETE'
    },
    function (err) {
      return err
        ? callback(err)
        : callback(null, { ok: imageId });
  });
};