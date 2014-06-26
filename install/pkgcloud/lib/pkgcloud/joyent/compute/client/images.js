/*
 * images.js: Implementation of Joyent Images Client.
 *
 * (C) 2012, Nodejitsu Inc.
 *
 */
var pkgcloud = require('../../../../../lib/pkgcloud'),
    base     = require('../../../core/compute'),
    errs     = require('errs'),
    compute  = pkgcloud.providers.joyent.compute;

//
// ### function getImages (callback)
// #### @callback {function} f(err, images). `images` is an array that
// represents the images that are available to your account
//
// Lists all images available to your account.
//
exports.getImages = function getImages(callback) {
  var self = this;
  return this._request({
    path: this.account + '/datasets'
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, body.map(function (result) {
          return new compute.Image(self, result);
        }), res);
  });
};

// ### function getImage (image, callback)
// #### @image    {Image|String} Image id or an Image
// #### @callback {function} f(err, image). `image` is an object that
// represents the image that was retrieved.
//
// Gets a specified image of Joyent DataSets using the provided details
// object.
//
exports.getImage = function getImage(image, callback) {
  var self    = this,
      imageId = image instanceof base.Image ? image.id : image;

  // joyent decided to add spaces to their identifiers
  imageId = encodeURIComponent(imageId);

  return this._request({
    path: this.account + '/datasets/' + imageId
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, new compute.Image(self, body), res);
  });
};

//
// ### function createImage(options, callback)
// #### @id {Object} an object literal with options
// ####     @name    {String}  String name of the image
// ####     @server  {Boolean} the server to use
// #### @callback {function} f(err, image). `image` is an object that
// represents the image that was created.
//
// Creates an image in Joyent based on a server
//
exports.createImage = function createImage(options, callback) {
  return errs.handle(
    errs.create({ message: 'Not supported by joyent' }),
    callback
  );
};

//
// ### function destroyImage(image, callback)
// #### @image    {Image|String} Image id or an Image
// #### @callback {function} f(err, image). `image` is an object that
// represents the image that was deleted.
//
// Destroys an image in Joyent
//
exports.destroyImage = function destroyImage(image, callback) {
  return errs.handle(
    errs.create({ message: 'Not supported by joyent' }),
    callback
  );
};