/*
 * files.js: Instance methods for working with files from Rackspace Cloudfiles
 *
 * (C) 2013 Rackspace, Ken Perkins
 * MIT LICENSE
 *
 */

var fs = require('fs'),
    request = require('request'),
    utile = require('utile'),
    base = require('../../../core/storage'),
    pkgcloud = require('../../../../pkgcloud'),
    _ = require('underscore');

//
// ### function purgeFileFromCdn (container, file, emails, callback)
// #### @container {string} Name of the container to destroy the file in
// #### @file {string} Name of the file to destroy.
// #### @emails {Array} Optional array of emails to notify on purging
// #### @callback {function} Continuation to respond to when complete.
// Destroys the `file` in the specified `container`.
//
exports.purgeFileFromCdn = function (container, file, emails, callback) {
  var containerName = container instanceof this.models.Container ? container.name : container,
    fileName = file instanceof this.models.File ? file.name : file;

  if (typeof emails === 'function') {
    callback = emails;
    emails = [];
  }
  else if (typeof emails === 'string') {
    emails = emails.split(',');
  }

  var purgeOptions = {
    method: 'DELETE',
    container: containerName,
    path: fileName,
    serviceType: this.cdnServiceType
  };

  if (emails.length) {
    purgeOptions.headers = {};
    purgeOptions.headers['x-purge-email'] = emails.join(',');
  }

  this._request(purgeOptions, function (err) {
      return err
        ? callback(err)
        : callback(null, true);
    }
  );
};
