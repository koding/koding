/*
 * zones.js: Rackspace DNS client zone functionality
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var base = require('../../../core/dns'),
    urlJoin = require('url-join'),
    pkgcloud = require('../../../../../lib/pkgcloud'),
    errs = require('errs'),
    _ = require('underscore'),
    dns = pkgcloud.providers.rackspace.dns;

var _urlPrefix = 'domains';

module.exports = {

  /**
   * @name Client.getZones
   *
   * @description getZones retrieves your list of zones
   *
   * @param {Object|Function}     details     provides filters on your zones request
   * @param {Function}            callback    handles the callback of your api call
   */
  getZones: function (details, callback) {
    var self = this;

    if (typeof(details) === 'function') {
      callback = details;
      details = {};
    }

    var requestOptions = {
      path: _urlPrefix
    };

    requestOptions.qs = _.pick(details,
      'name');

    return self._request(requestOptions, function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, body.domains.map(function (result) {
        return new dns.Zone(self, result);
      }), res);
    });
  },

  /**
   * @name Client.getZone
   *
   * @description Gets the details for a specified zone id
   *
   * @param {String|object}       zone          the zone id of the requested zone
   * @param {Function}            callback      handles the callback of your api call
   */
  getZone: function (zone, callback) {
    var self = this,
        zoneId = zone instanceof dns.Zone ? zone.id : zone;

    self._request({
      path: urlJoin(_urlPrefix, zoneId)
    }, function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, new dns.Zone(self, body), res);
    });
  },

  /**
   * @name Client.createZone
   *
   * @description register a new zone in the rackspace cloud dns
   *
   * @param {Object}     details     the information for your new zone
   * @param {Function}   callback    handles the callback of your api call
   */
  createZone: function (details, callback) {
    this.createZones([ details ], function (err, zones) {
      if (err) {
        return callback(err);
      }

      if (zones && zones.length === 1) {
        return callback(err, zones[0]);
      }
      else {
        return callback(new Error('Unexpected error when creating single zone'), zones);
      }
    });
  },

  /**
   * @name Client.createZones
   *
   * @description register a new zone in the rackspace cloud dns
   *
   * @param {Array}      zones      the array of zones to create
   * @param {Function}   callback    handles the callback of your api call
   */
  createZones: function (zones, callback) {
    var self = this;

    var listOfZones = [];
    _.each(zones, function (zone) {
      ['name', 'email'].forEach(function (required) {
        if (!zone[required]) throw new Error('details.' +
          required + ' is a required argument.');
      });

      var newZone = {
        name: zone.name,
        emailAddress: zone.email
      };

      if (zone.ttl && typeof(zone.ttl) === 'number' && zone.ttl >= 300) {
        newZone.ttl = zone.ttl;
      }

      if (zone.comment) {
        newZone.comment = zone.comment;
      }

      listOfZones.push(newZone);
    });

    var requestOptions = {
      path: _urlPrefix,
      method: 'POST',
      body: {
        domains: listOfZones
      }
    };

    self._asyncRequest(requestOptions, function (err, result) {
      return err
        ? callback(err)
        : callback(err, result.response.domains.map(function (domain) {
          return new dns.Zone(self, domain);
      }));
    });
  },


  /**
   * @name Client.importZone
   *
   * @description This call provisions a new DNS zone under the account
   * specified by the BIND 9 formatted file configuration contents defined
   * in the request object.
   *
   * @param {Object}     details     the information for your new zone
   * @param {Function}   callback    handles the callback of your api call
   */
  importZone: function (details, callback) {
    var self = this;

    ['contentType', 'contents'].forEach(function (required) {
      if (!details[required]) throw new Error('details.' +
        required + ' is a required argument.');
    });

    if (details.contentType !== 'BIND_9') {
      callback(new Error({ invalidRequest: true }));
      return;
    }

    var importedZone = {
      contentType: details.contentType,
      contents: details.contents
    };

    var requestOptions = {
      path: urlJoin(_urlPrefix, 'import'),
      method: 'POST',
      body: {
        domains: [
          importedZone ]
      }
    };

    self._asyncRequest(requestOptions, function (err, result) {
      return err
        ? callback(err)
        : callback(err, result.response.domains.map(function (domain) {
        return new dns.Zone(self, domain);
      })[0]);
    });
  },

  /**
   * @name Client.exportZone
   *
   * @description This call exports a provided domain as a BIND zone file
   *
   * @param {Object|String}     zone        the information for your new zone
   * @param {Function}          callback    handles the callback of your api call
   */
  exportZone: function (zone, callback) {
    var self = this,
      zoneId = zone instanceof dns.Zone ? zone.id : zone;

    var requestOptions = {
      path: urlJoin(_urlPrefix, zoneId, 'export'),
      method: 'GET'
    };

    self._asyncRequest(requestOptions, function (err, result) {
      return err
        ? callback(err)
        : callback(err, result.response);
    });
  },


  /**
   * @name Client.updateZone
   * @description update a zone
   * @param {Zone}      zone      the zone to update
   * @param {Function}    callback    handles the callback of your api call
   */
  updateZone: function (zone, callback) {
    this.updateZones([ zone ], callback);
  },

  /**
   * @name Client.updateZones
   * @description update an array of zones
   * @param {Array}       zones     the array of zones to update
   * @param {Function}    callback    handles the callback of your api call
   */
  updateZones: function (zones, callback) {
    var self = this;

    var data = [];

    _.each(zones, function (zone) {
      if (!(zone instanceof dns.Zone)) {
        return;
      }

      var update = {
        id: zone.id,
        ttl: zone.ttl,
        emailAddress: zone.emailAddress,
        comment: zone.comment
      };

      data.push(update);
    });

    var requestOptions = {
      path: _urlPrefix,
      method: 'PUT',
      body: {
        domains: data
      }
    };

    self._asyncRequest(requestOptions, function(err) {
      callback(err);
    });
  },

  /**
   * @name Client.deleteZone
   * @description delete a zone
   * @param {Zone}              zone              the zone to delete
   * @param {object|Function}   options           options for the deleteZone call
   * @param {Function}          callback          handles the callback of your api call
   */
  deleteZone: function (zone, options, callback) {
    this.deleteZones([ zone ], options, callback);
  },

  /**
   * @name Client.deleteZones
   * @description delete an array of zones
   * @param {Array}               zones             the array of zones or zoneIds to delete
   * @param {object|Function}     options           options for the deleteZones call
   * @param {Function}            callback          handles the callback of your api call
   */
  deleteZones: function (zones, options, callback) {
    var self = this;

    if (typeof(options) === 'function') {
      callback = options;
      options = {};
    }

    var zoneIds = [];

    _.each(zones, function (zone) {
      if (zone instanceof dns.Zone) {
        zoneIds.push(zone.id);
      }
      else {
        zoneIds.push(zone);
      }
    });

    var deleteSubzones = typeof options.deleteSubzones === 'boolean'
      ? options.deleteSubzones : true;

    // HACK: Can't use qs here as it puts array keys with index location
    // which breaks API parsing of supplied ids
    // https://github.com/visionmedia/node-querystring/issues/71

    var requestOptions = {
      path: _urlPrefix + '?' +
        zoneIds.map(function(z) { return 'id=' + z }).join('&') +
        '&deleteSubzones=' + deleteSubzones.toString(),
      method: 'DELETE'
    };

    self._asyncRequest(requestOptions, function(err) {
      return callback(err);
    });
  },

  /**
   * @name Client.getZoneChanges
   * @description get a list of changes for a provided zone, optionally setting a date to filter by
   * @param {Zone}                zone              the zone or zoneId for the changes
   * @param {object|Function}     options           options for call
   * @param {Date}                [options.since]   changes after given date
   * @param {Function}            callback          handles the callback of your api call
   */
  getZoneChanges: function (zone, options, callback) {
    var self = this,
        zoneId = zone instanceof dns.Zone ? zone.id : zone;

    if (typeof(options) === 'function') {
      callback = options;
      options = {};
    }
    var requestOptions = {
      path: urlJoin(_urlPrefix, zoneId, 'changes'),
      method: 'GET'
    };

    if (options.since) {
      requestOptions.qs = {
        since: options.since.toString()
      }
    }

    self._request(requestOptions, function (err, body, res) {
      return err
        ? callback(err)
        : callback(err, body);
    });
  },

  /**
   * @name Client.cloneZone
   * @description clone a zone from a provided domain name
   *
   * @param {Zone}                zone              the zone or zoneId for the changes
   *
   * @param {object|Function}     options           options for call
   *
   * @param {String}              [options.cloneName]   The name of the new (cloned) domain.
   *
   * @param {Boolean}             [options.cloneSubdomains]       Recursively clone
   * subdomains. If set to false, then only the top level domain and its records are
   * cloned. Cloned subdomain configurations are modified the same way that cloned
   * top level domain configurations are modified. (Default=true)
   *
   * @param {Boolean}             [options.modifyComment]         Replace occurrences
   * of the reference domain name with the new domain name in comments on the cloned
   * (new) domain. (Default=true)
   *
   * @param {Boolean}             [options.modifyEmailAddress]    Replace occurrences
   * of the reference domain name with the new domain name in email addresses on the
   * cloned (new) domain. (Default=true)
   *
   * @param {Boolean}             [options.modifyRecordData]    Replace occurrences
   * of the reference domain name with the new domain name in data fields (of records)
   * on the cloned (new) domain. Does not affect NS records. (Default=true)
   *
   * @param {Function}            callback          handles the callback of your api call
   */
  cloneZone: function (zone, options, callback) {
    var self = this,
        zoneId = zone instanceof dns.Zone ? zone.id : zone;

    if (typeof(options) === 'function') {
      callback = options;
      options = {};
    }

    var requestOptions = {
      path: urlJoin(_urlPrefix, zoneId, 'clone'),
      method: 'POST',
      qs: {
        cloneName: options.cloneName
      }
    };

    _.extend(requestOptions.qs, _.pick(options, ['cloneSubdomains', 'modifyComment',
    'modifyEmailAddress', 'modifyRecordData']));

    self._asyncRequest(requestOptions, function (err, result) {
      return err
        ? callback(err)
        : callback(err, result.response.domains.map(function (domain) {
        return new dns.Zone(self, domain);
      })[0]);
    });
  },

  /**
   * @name Client.getSubZones
   * @description gets a list of the subzones for a provided zone
   *
   * @param {object|Number}     zone          the zone of the record to query for
   * @param {Function}          callback      handles the callback of your api call
   */
  getSubZones: function(zone, callback) {
    var self = this,
        zoneId = zone instanceof dns.Zone ? zone.id : zone;

    var requestOptions = {
      path: urlJoin(_urlPrefix, zoneId, 'subdomains'),
      method: 'GET'
    };

    self._request(requestOptions, function(err, body, res) {
      return err
        ? callback(err)
        : callback(null, body.domains.map(function (result) {
        return new dns.Zone(self, result);
      }), res);
    });
  }
};