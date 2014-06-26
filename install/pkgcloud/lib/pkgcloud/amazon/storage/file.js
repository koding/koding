/*
 * container.js: AWS S3 File
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    base  = require('../../core/storage/file');

var File = exports.File = function File(client, details) {
  base.File.call(this, client, details);
};

utile.inherits(File, base.File);

File.prototype._setProperties = function (details) {
  var self = this;

  this.name = details.name || details.Key;
  this.size = +(details.Size || details['content-length']) || 0;
  this.container = details.container;

  // AWS Specific
  this.storageClass = this.StorageClass;
};
