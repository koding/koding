/*
 * keys.js: Implementation of AWS SSH keys Client.
 *
 * (C) 2012, Nodejitsu Inc.
 *
 */

var errs  = require('errs'),
    utile = require('utile');

//
// ### function listKeys (options, callback)
// #### @options {Object} **Optional** Filter parameters when listing keys
// #### @callback {function} Continuation to respond to when complete.
//
// Lists all EC2 Key Pairs matching the specified `options`.
//
exports.listKeys = function (options, callback) {
  if (!callback && typeof options === 'function') {
    callback = options;
    options = {};
  }

  var self = this;
  options = options || {};

  return this._query('DescribeKeyPairs', options, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, self._toArray(body.keySet.item));
  });
};

//
// ### function getKey (name, callback)
// #### @name {string} Name of the EC2 key pair to get
// #### @callback {function} Continuation to respond to when complete.
//
// Gets the details of the EC2 Key Pair with the specified `name`.
//
exports.getKey = function (name, callback) {
  return this.listKeys({
    'KeyName.1': name
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(null, body[0]);
  });
};

//
// ### function addKey (options, callback)
// #### @options {Object} SSH Public Key details
// ####     @name {string} String name of the key
// ####     @key  {string} SSH Public Key
// #### @callback {function} Continuation to respond to when complete.
//
// Adds an EC2 Key Pair with the specified `options`.
//
exports.addKey = function (options, callback) {
  if (!options || !options.key || !options.name) {
    return errs.handle(
      errs.create({ message: '`key` and `name` are required options.' }),
      callback
    );
  }

  return this._query(
    'ImportKeyPair',
    {
      KeyName: options.name,
      PublicKeyMaterial: utile.base64.encode(options.key)
    },
    function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, true);
    }
  );
};

//
// ### function destroyKey (name, callback)
// #### @name {string} Name of the EC2 key pair to destroy
// #### @callback {function} Continuation to respond to when complete.
//
// Destroys EC2 Key Pair with the specified `name`.
//
exports.destroyKey = function (name, callback) {
  return this._query(
    'DeleteKeyPair',
    { KeyName: name },
    function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, true);
    }
  );
};