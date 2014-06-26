/*
 * image.js: Joyent Cloud DataSet
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
  this.id           = details.urn;
  this.name         = details.name;
  this.created      = details.created;

  //
  // Joyent specific
  //
  this.urn          = details.urn;
  this.joyentId     = details.id;
  this.os           = details.os;
  this.type         = details.type;
  this.description  = details.description;
  this["default"]   = details["default"];
  this.version      = details.version;
  this.requirements = details.requirements;
  this.original     = this.rackspace = details;
};