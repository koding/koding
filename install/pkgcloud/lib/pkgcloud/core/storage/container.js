/*
 * container.js: Base container from which all pkgcloud containers inherit from
 *
 * (C) 2010 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    model = require('../base/model');

var Container = exports.Container = function (client, details) {
  this.files = [];

  model.Model.call(this, client, details);
};

utile.inherits(Container, model.Model);

Container.prototype.create = function (callback) {
  this.client.createContainer(this.name, callback);
};

Container.prototype.refresh = function (callback) {
  this.client.getContainer(this, callback);
};

Container.prototype.destroy = function (callback) {
  this.client.destroyContainer(this.name, callback);
};

Container.prototype.upload = function (file, local, options, callback) {
  this.client.upload(this.name, file, local, options, callback);
};

Container.prototype.getFiles = function (download, callback) {
  var self = this;

  // download can be omitted: (...).getFiles(callback);
  // In this case first argument will be a function
  if (typeof download === 'function' && !(download instanceof RegExp)) {
    callback = download;
    download = false;
  }

  this.client.getFiles(this.name, download, function (err, files) {
    if (err) {
      return callback(err);
    }

    self.files = files;
    callback(null, files);
  });
};

Container.prototype.removeFile = function (file, callback) {
  this.client.removeFile(this.name, file, callback);
};
