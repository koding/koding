/*
 * container.js: Azure File (Blob)
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

var utile = require('utile'),
    base  = require('../../core/storage/file');

var File = exports.File = function File(client, details) {
  base.File.call(this, client, details);
};

utile.inherits(File, base.File);

File.prototype._setProperties = function (details) {
  this.container = details.container;

  if (details.Properties) {
    var properties = details.Properties;
    this.name = details.Name;
    this.size = (properties && properties['Content-Length']) ? parseInt(properties['Content-Length'], 10) : 0;
  } else {
    this.name = details.name;
    this.size = (details['content-length']) ? parseInt(details['content-length'], 10) : 0;
  }
};
