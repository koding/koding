/*
 * index.js: Top-level include from which all pkgcloud compute models inherit.
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var ip = require('ip');

exports.Flavor       = require('./flavor').Flavor;
exports.Image        = require('./image').Image;
exports.Server       = require('./server').Server;

//
// ### function isPrivate (addr)
// Determines if an IP address is private.
//
exports.isPrivate = ip.isPrivate;

//
// ### function isPublic (addr)
// Determines if an IP address is public.
//
exports.isPublic = ip.isPublic;

//
// ### function serverPass (server)
// #### @server {Object} Server to extract the serverPass from.
//
// Returns the server password (if it exists).
//
exports.serverPass = function (server) {
  if (server.adminPass) {
    return server.adminPass;
  }
  else if (server.metadata) {
    return server.metadata['root'];
  }

  return '';
};

//
// ### function serverIp (server)
// #### @server {Object} Server to extract the IP from.
//
// Attempts to return the `server` IP.
//
exports.serverIp = function (server, options) {
  if (!server && !server.ips && !server.addresses) {
    return null;
  }

  options = options || {};

  var isPublic  = options.isPublic  || exports.isPublic,
      isPrivate = options.isPrivate || exports.isPrivate,
      interfaces,
      addresses,
      networks,
      pub;

  if (server.ips) {
    //
    // Joyent uses the format:
    // * { ips: ['23.23.23.23', '10.0.0.1'] }
    // OR
    // * { ips: ['10.0.0.1', '23.23.23.23'] }
    //
    pub = server.ips.filter(function (addr) {
      return isPublic(addr);
    });

    return !pub.length
      ? server.ips[0]
      : pub[0];
  }
  else if (server.addresses.public || server.addresses.private) {
    //
    // Rackspace and most sane providers use:
    //
    // addresses: {
    //   public: ['23.23.23.23'],
    //   private: ['10.0.0.1']
    // }
    //
    // OR
    //
    // addresses: {
    //   public: [],
    //   private: ['10.0.0.1']
    // }
    //
    return server.addresses.public.length
      ? server.addresses.public[0]
      : server.addresses.private[0];
  }
  else if (server.addresses) {
    //
    // OpenStack uses a non-standard set of names
    //
    // addresses: {
    //   vlan01: [
    //     { version: 4, addr: '10.0.0.1' }
    //     { version: 4, addr: '23.23.23.23' }
    //   ]
    // }
    //
    interfaces = Object.keys(server.addresses);
    if (!interfaces.length) {
      return null;
    }

    addresses = interfaces.reduce(function (all, iface) {
      server.addresses[iface]
        .map(function (info) { return info.addr })
        .filter(Boolean)
        .forEach(function (addr) {
          if (isPublic(addr)) {
            all['public'].push(addr);
          }
          else if (isPrivate(addr)) {
            all['private'].push(addr);
          }
        });

      return all;
    }, { public: [], private: [] });

    return addresses['public'][0]
      || addresses['private'][0]
      || null;
  }

  return null;
};
