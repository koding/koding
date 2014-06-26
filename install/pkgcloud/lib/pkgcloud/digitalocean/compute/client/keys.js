/*
 * keys.js: Implementation of DigitalOcean SSH keys Client.
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
// Lists all DigitalOcean SSH Keys matching the specified `options`.
//
exports.listKeys = function (callback) {
  return this._request({
    path: '/ssh_keys'
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, body.ssh_keys);
  });
};

//
// ### function getKey (name, callback)
// #### @name {string} Name of the DigitalOcean SSH key to get
// #### @callback {function} Continuation to respond to when complete.
//
// Gets the details of the DigitalOcean SSH Key with the specified `name`.
//
exports.getKey = function (name, callback) {
  return this._request({
    path: '/ssh_keys/' + name
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, body.ssh_key);
  });
};

//
// ### function addKey (options, callback)
// #### @options {Object} SSH Public Key details
// ####     @name {string} String name of the key
// ####     @key  {string} SSH Public Key
// #### @callback {function} Continuation to respond to when complete.
//
// Adds a DigitalOcean SSH Key with the specified `options`.
//
exports.addKey = function (options, callback) {
  if (!options || !options.key || !options.name) {
    return errs.handle(
      errs.create({ message: '`key` and `name` are required options.' }),
      callback
    );
  }

  return this._request({
    path: '/ssh_keys/new',
    qs: {
      name: options.name,
      ssh_pub_key: options.key
    }
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, true);
  });
};

//
// ### function getKey (name, callback)
// #### @name {string} Name of the DigitalOcean SSH key to destroy
// #### @callback {function} Continuation to respond to when complete.
//
// Destroys DigitalOcean SSH Key with the specified `name`.
//
exports.destroyKey = function (name, callback) {
  return this._request({
    path: '/ssh_keys/' + name + '/destroy',
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, true);
  });
};