/*
 * record.js: Base record from which all pkgcloud dns record inherit from
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    model = require('../base/model');

var Record = exports.Record = function (zone, details) {
  model.Model.call(this, zone.client, details);
};

utile.inherits(Record, model.Model);

Record.prototype.create = function(callback) {
  return this.zone.createRecord(this, callback);
};

Record.prototype.get = function(callback) {
  return this.zone.getRecord(this, callback);
};

Record.prototype.update = function(callback) {
  return this.zone.updateRecord(this, callback);
};

Record.prototype.destroy = function(callback) {
  return this.zone.deleteRecord(this, callback);
};