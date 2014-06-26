/*
 * databases.js: Rackspace Cloud Database within a Instance
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    model = require('../../core/base/model');

var Database = exports.Database = function Database(client, details) {
  model.Model.call(this, client, details);
};

utile.inherits(Database, model.Model);

Database.prototype.refresh = function (callback) {
  this.client.getDatabase(this, callback);
};

Database.prototype._setProperties = function (details) {
  // @todo Check for characters that CANNOT be used in the Database Name
  // @todo There is a length restrictions for database name. 64
  this.name = details.name;
  if (details.characterSet) this.characterSet = details.characterSet;
  if (details.collation) this.collation = details.collation;
};