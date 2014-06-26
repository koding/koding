/*
 * index.js: OpenStack compute extension index
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 * (updated by Alvaro M. Reol)
 */

var utile = require('utile');

var extensions = {
  getExtensions: function(callback) {
    return this._request({
      path: 'extensions'
    }, function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, body.extensions, res);
    });
  }
};

utile.mixin(extensions, require('./floating-ips'));
utile.mixin(extensions, require('./keys'));
utile.mixin(extensions, require('./networks'));
utile.mixin(extensions, require('./security-groups'));
utile.mixin(extensions, require('./security-group-rules'));
utile.mixin(extensions, require('./servers'));
utile.mixin(extensions, require('./volume-attachments'));

module.exports = extensions;
