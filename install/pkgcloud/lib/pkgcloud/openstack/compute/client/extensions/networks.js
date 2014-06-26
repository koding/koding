/*
 * networks.js Implementation of OpenStack os-networks extension
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 *
 */

var urlJoin = require('url-join'),
    networks = require('./networks-base');

module.exports = networks.createNetworkExtension('os-networks');
