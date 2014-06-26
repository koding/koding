/*
 * keys.js Implementation of OpenStack KeyPair API
 *
 * (C) 2013, Nodejitsu Inc.
 *
 */

var urlJoin = require('url-join');

var _extension = 'os-keypairs';

/**
 * client.listKeys
 *
 * @description List keypards for the current compute client
 *
 * @param {Function}    callback    f(err, keypairs) where keypairs is an array of keypairs
 * @returns {*}
 */
exports.listKeys = function listKeys(callback) {
  return this._request({
    path: _extension
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, body.keypairs, res);
  });
};

/**
 * client.addKey
 *
 * @description Generate or import a keypair (if the key is supplied)
 *
 * @param {object|String}   options         The object (or keyname to generate) for the keypair
 * @param {String}          options.name    The name for the keypair
 * @param {String}          [options.public_key]    The SSH Key
 * @param callback
 * @returns {*}
 */
exports.addKey = function addKey(options, callback) {
  if (typeof options === 'string') {
    options = { name: options };
  }
  else if (options.key) {
    options.public_key = options.key;
    delete options.key;
  }

  return this._request({
    method: 'POST',
    path: _extension,
    body: {
      keypair: options
    }
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(null, body.keypair);
  });
};

/**
 * client.destroyKey
 *
 * @description Delete a keypair from the current account
 *
 * @param {String}    name    The name of the key to delete
 * @param {Function}  callback
 * @returns {*}
 */
exports.destroyKey = function destroyKey(name, callback) {
  return this._request({
    method: 'DELETE',
    path: urlJoin(_extension, name)
  }, function (err) {
    return callback(err);
  });
};

/**
 * client.getKey
 *
 * @description Get a keypair by name from the current account
 *
 * @param {String}    name    The name of the key to get
 * @param {Function}  callback
 * @returns {*}
 */
exports.getKey = function getKey(name, callback) {
  return this._request({
    path: urlJoin(_extension, name)
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(null, body.keypair);
  });
};
