/*
 * keys.js: Implementation of Joyent SSH keys Client.
 *
 * (C) 2012, Nodejitsu Inc.
 *
 */

var errs  = require('errs'),
    utile = require('utile');

//
// ### function listKeys (callback)
// #### @callback {function} Continuation to respond to when complete.
//
// Lists all Joyent SSH Keys matching the specified `options`.
//
exports.listKeys = function (callback) {
  return this._request({
    path: this.account + '/keys'
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, body);
  });
};

//
// ### function getKey (name, callback)
// #### @name {string} Name of the Joyent SSH key to get
// #### @callback {function} Continuation to respond to when complete.
//
// Gets the details of the Joyent SSH Key with the specified `name`.
//
exports.getKey = function (name, callback) {
  return this._request({
    path: this.account + '/keys/' + name
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, body);
  });
};

//
// ### function addKey (options, callback)
// #### @options {Object} SSH Public Key details
// ####     @name {string} String name of the key
// ####     @key  {string} SSH Public Key
// #### @callback {function} Continuation to respond to when complete.
//
// Adds a Joyent SSH Key with the specified `options`.
//
exports.addKey = function (options, callback) {
  if (!options || !options.key || !options.name) {
    return errs.handle(
      errs.create({ message: '`key` and `name` are required options.' }),
      callback
    );
  }

  return this._request({
    method: 'POST',
    path: this.account + '/keys',
    body: options
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, true);
  });
};

//
// ### function getKey (name, callback)
// #### @name {string} Name of the Joyent SSH key to destroy
// #### @callback {function} Continuation to respond to when complete.
//
// Destroys Joyent SSH Key with the specified `name`.
//
exports.destroyKey = function (name, callback) {
  return this._request({
    method: 'DELETE',
    path: this.account + '/keys/' + name
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, true);
  });
};