/*
 * node.js: Base record from which all pkgcloud loadbalancer node models inherit from
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    model = require('../base/model');

var Node = exports.Node = function (client, details) {
  model.Model.call(this, client, details);
};

utile.inherits(Node, model.Model);
