/*
 * image.js: Azure OS Images
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

var utile = require('utile'),
    base  = require('../../core/compute/image');

var Image = exports.Image = function Image(client, details) {
  base.Image.call(this, client, details);
};

utile.inherits(Image, base.Image);

Image.prototype._setProperties = function (details) {
  this.id      = details.Name;
  this.name    = details.Name;
  this.created = new Date(0);
  this.details = this.azure = details;
};
