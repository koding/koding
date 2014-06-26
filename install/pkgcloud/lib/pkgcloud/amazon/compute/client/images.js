/*
 * images.js: Implementation of AWS Images Client.
 *
 * (C) 2012, Nodejitsu Inc.
 *
 */
var pkgcloud = require('../../../../../lib/pkgcloud'),
    base     = require('../../../core/compute'),
    errs     = require('errs'),
    compute  = pkgcloud.providers.amazon.compute;

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

  var query = { 'Owner.0': 'self' },
      self = this;

  if (options && options.owners) {
    //
    // TODO: Support more than just owners
    //
    for (var i = 0; i < options.owners.length; i++) {
      query['Owner.' + (i + 1)] = options.owners[i];
    }
  }

  return this._query('DescribeImages', query, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, self._toArray(body.imagesSet.item).map(function (image) {
          return new compute.Image(self, image);
        }), res);
  });
};

// ### function getImage (image, callback)
// #### @image    {Image|String} Image id or an Image
// #### @callback {function} f(err, image). `image` is an object that
// represents the image that was retrieved.
//
// Gets a specified image of AWS using the provided details
// object.
//
exports.getImage = function getImage(image, callback) {
  var self    = this,
      imageId = image instanceof base.Image ? image.id : image,
      query   = { 'ImageId.1': imageId };

  return this._query('DescribeImages', query, function (err, body, res) {
    if (err) {
      return callback(err);
    }
    var image = self._toArray(body.imagesSet.item).map(function (image) {
      return image ? new compute.Image(self, image) : null;
    })[0];

    return !image
      ? callback(new Error('Image not found'))
      : callback(null, image, res);
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
// Creates an image in AWS based on a server
//
exports.createImage = function createImage(options, callback) {
  options || (options = {});

  if (!options.name) throw new TypeError('`name` is a required option');
  if (!options.server) throw new TypeError('`server` is a required option');

  var self    = this,
      serverId = options.server instanceof base.Server
        ? options.server.id : options.server,
      query = { InstanceId: serverId, Name: options.name };

  return this._query('CreateImage', query, function (err, body, res) {
    return err
      ? callback(err)
      : self.getImage(res.imageId, callback);
  });
};

//
// ### function destroyImage(image, callback)
// #### @image    {Image|String} Image id or an Image
// #### @callback {function} f(err, image). `image` is an object that
// represents the image that was deleted.
//
// Destroys an image in AWS
//
exports.destroyImage = function destroyImage(image, callback) {
  var self = this;

  this.getImage(image, function (err, image) {
    if (err) {
      return callback(err);
    }

    if (!image.blockDeviceMapping.item ||
        !image.blockDeviceMapping.item.ebs.snapshotId) {
      return callback(new TypeError('Image is not EBS backed'));
    }

    var query = {
      snapshotId: image.blockDeviceMapping.item.ebs.snapshotId
    };

    self._query('DeleteSnapshot', query, function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, { ok: query.snapshotId }, res);
    });
  });
};
