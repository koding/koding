/*
 * user.js: Rackspace Cloud Database User
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    model = require('../../core/base/model');

var User = exports.User = function User(client, details) {
  model.Model.call(this, client, details);
};

utile.inherits(User, model.Model);

User.prototype.refresh = function (callback) {
  this.client.getUser(this, callback);
};

User.prototype._setProperties = function (details) {
  this.name = details.name;
  this.password = details.password;
};