/*
 * image.js: AWS Cloud
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    base  = require('../../core/compute/image');

var Image = exports.Image = function Image(client, details) {
  base.Image.call(this, client, details);
};

utile.inherits(Image, base.Image);

Image.prototype._setProperties = function (details) {
  this.id      = details.imageId;
  this.name    = details.name || details.imageLocation.split('/')[1];
  this.created = new Date(0);
  this.details = this.amazon = details;
};
