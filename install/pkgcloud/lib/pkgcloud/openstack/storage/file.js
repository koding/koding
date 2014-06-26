/*
 * file.js: Openstack Object Storage File (i.e. StorageObject)
 *
 * (C) 2013 Rackspace, Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    base = require('../../core/storage/file');

var File = exports.File = function File(client, details) {
  base.File.call(this, client, details);
};

utile.inherits(File, base.File);

File.prototype.updateMetadata = function (callback) {
  this.client.updateFileMetadata(this.container, this, callback);
};

// Remark: This method is untested
File.prototype.copy = function (container, destination, callback) {
  var copyOptions = {
    method: 'PUT',
    uri: this.fullPath,
    headers: {
      'X-COPY-DESTINATION': [container, destination].join('/'),
      'CONTENT-LENGTH': this.bytes
    }
  };

  this.client._request(copyOptions, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, true);
  });
};

File.prototype._setProperties = function (details) {
  var self = this;

  this.metadata = {};
  this.container = details.container || null;
  this.name = details.name || null;
  this.etag = details.etag || details.hash || null;
  this.contentType = details['content-type'] || details['content_type'] || null;

  this.lastModified = details['last-modified']
    ? new Date(details['last-modified'])
    : details['last_modified']
    ? new Date(details['last_modified'])
    : null;

  this.size = this.bytes = details['content-length']
    ? parseInt(details['content-length'], 10)
    : details['bytes']
    ? parseInt(details['bytes'], 10)
    : null;

  Object.keys(details).forEach(function (header) {
    var match;
    if (match = header.match(/x-object-meta-(\w+)/i)) {
      self.metadata[match[1]] = details[header];
    }
  });
};

