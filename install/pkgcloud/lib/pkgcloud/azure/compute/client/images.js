/*
 * images.js: Implementation of Azure Images Client.
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */
var pkgcloud = require('../../../../../lib/pkgcloud'),
  base     = require('../../../core/compute'),
  errs     = require('errs'),
  compute  = pkgcloud.providers.azure.compute,
  azureApi = require('../../utils/azureApi');

//
// ### function getImages (callback)
// #### @callback {function} f(err, images). `images` is an array that
// represents the images that are available to your account
//
// Lists all images available to your account.
//
exports.getImages = function getImages(options, callback) {
  if (!callback && typeof options === 'function') {
    callback = options;
    options = null;
  }

  var path = this.config.subscriptionId + '/services/images',
    self = this;

  return this.get(path, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, self._toArray(body.OSImage).map(function (image) {
          return new compute.Image(self, image);
        }), res);
  });
};

// ### function getImage (image, callback)
// #### @image    {Image|String} Image id or an Image
// #### @callback {function} f(err, image). `image` is an object that
// represents the image that was retrieved.
//
// Gets a specified image of Azure using the provided details
// object.
//
exports.getImage = function getImage(image, callback) {
  var self = this,
    imageId = image instanceof base.Image ? image.id : image,
    path = this.config.subscriptionId + '/services/images/' + imageId;

  this.get(path, function (err, body, res) {

    if (err) {
      return callback(err);
    }

    var result = null;
    if (body) {
      result = new compute.Image(self, body);
    }

    return result
      ? callback(null, result, res)
      : callback(new Error('Image not found'));
  });
};

//
// ### function createImage(options, callback)
// #### @id {Object} an object literal with options
// ####     @name    {String}  String name of the image
// ####     @server  {Server} the server to use
// #### @callback {function} f(err, image). `image` is an object that
// represents the image that was created.
//
// Creates an image in Azure based on a server
//
exports.createImage = function createImage(options, callback) {
  options || (options = {});

  if (!options.name) throw new TypeError('`name` is a required option');
  if (!options.server) throw new TypeError('`server` is a required option');

  var self    = this,
    serverId  = options.server instanceof base.Server
      ? options.server.id
      : options.server;

  azureApi.createImage(this, serverId, options.name, function (err, result) {
    return !err
      ? self.getImage(result, callback)
      : callback(err);
  });
};

//
// ### function destroyImage(image, callback)
// #### @image    {Image|String} Image id or an Image
// #### @callback {function} f(err, image). `image` is an object that
// represents the image that was deleted.
//
// Destroys an image in Azure
//
exports.destroyImage = function destroyImage(image, callback) {
  var self = this,
      imageId = image instanceof base.Image ? image.id : image,
      path = self.config.subscriptionId + '/services/images/' + imageId;

  self._xmlRequest({
    method: 'DELETE',
    path: path
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, { ok: imageId }, res);
  });
};
