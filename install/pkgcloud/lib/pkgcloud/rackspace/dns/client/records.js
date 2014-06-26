/*
 * records.js: Rackspace DNS client records functionality
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

var _urlPrefix = 'domains',
    _recordFragment = 'records';

module.exports = {

  /**
   * @name Client.getRecords
   * @description getRecords retrieves your list of records for this domain
   * @param {Object|Number}     zone        the zone for the getRecords query
   * @param {Function}          callback    handles the callback of your api call
   */
  getRecords: function (zone, callback) {
    var self = this,
        zoneId = zone instanceof dns.Zone ? zone.id : zone;

    var requestOptions = {
      path: urlJoin(_urlPrefix, zoneId, _recordFragment)
    };

    self._request(requestOptions, function (err, body, res) {
      if(err) {
        return callback(err);
      }

      else if (!body || !body.records) {
        return callback(new Error('Unexpected empty response'));
      }

      else{
        return callback(null, body.records.map(function (record) {
          return new dns.Record(self, record);
        }), res);
      }
    });
  },

  /**
   * @name Client.getRecord
   * @description get the details of dns record for the provided zone and record
   * @param {object|Number}     zone          the zone of the record to query for
   * @param {object|String}     record        the record to query for
   * @param {Function}          callback      handles the callback of your api call
   */
  getRecord: function (zone, record, callback) {
    var self = this,
        zoneId = zone instanceof dns.Zone ? zone.id : zone,
        recordId = record instanceof dns.Record ? record.id : record;

    var requestOptions = {
      path: urlJoin(_urlPrefix, zoneId, _recordFragment, recordId)
    };

    self._request(requestOptions, function (err, body, res) {
      return err
        ? callback(err)
        : callback(err, new dns.Record(self, body));
    });
  },

  /**
   * @name Client.updateRecord
   * @description update a dns record for a given domain
   * @param {Record}      record      the record to update
   * @param {Function}    callback    handles the callback of your api call
   */
  updateRecord: function (zone, record, callback) {
    this.updateRecords(zone, [ record ], callback);
  },

  /**
   * @name Client.updateRecords
   * @description update a set of dns records for a given domain
   * @param {Array}       records     the records to update
   * @param {Function}    callback    handles the callback of your api call
   */
  updateRecords: function (zone, records, callback) {
    var self = this,
        data = [],
        zoneId = zone instanceof dns.Zone ? zone.id : zone;

    _.each(records, function (record) {
      if (!record.type || !record.name || !record.data) {
        return;
      }

      var updateRecord = {
        id: record.id,
        type: record.type,
        data: record.data,
        name: record.name
      };

      if (record.type === 'MX' || record.type === 'SRV') {
        updateRecord.priority = record.priority;
      }

      if (record.ttl) {
        updateRecord.ttl = record.ttl > 300 ? record.ttl : 300;
      }

      if (record.comment) {
        updateRecord.comment = record.comment;
      }

      data.push(updateRecord);
    });

    var requestOptions = {
      path: urlJoin(_urlPrefix, zoneId, _recordFragment),
      method: 'PUT',
      body: {
        records: data
      }
    };

    self._asyncRequest(requestOptions, function(err, result) {
      return err
        ? callback(err)
        : callback(null, result.response
          ? result.response.records.map(function (record) {
              return new dns.Record(self, record);
            })
          : []);
    });
  },

  /**
   * @name Client.addRecord
   * @description create a dns record for a given zone
   * @param {object|Number}     zone          the zone to add the record to
   * @param {object}            record        the record to create
   * @param {Function}          callback      handles the callback of your api call
   */
  createRecord: function (zone, record, callback) {
    this.createRecords(zone, [ record ], function(err, records) {
      return err
        ? callback(err)
        : callback(err, records[0]);
    });
  },

  /**
   * @name Client.createRecords
   * @description create a set of dns records for a given zone
   * @param {object|Number}     zone          the zone to add the records to
   * @param {Array}             records       the array of records to create
   * @param {Function}          callback      handles the callback of your api call
   */
  createRecords: function (zone, records, callback) {
    var self = this,
        data = [],
        zoneId = zone instanceof dns.Zone ? zone.id : zone;

    _.each(records, function (record) {
      if (!record.type || !record.name || !record.data) {
        return;
      }

      var newRecord = {
        type: record.type,
        data: record.data,
        name: record.name
      };

      if (record.type === 'MX' || record.type === 'SRV') {
        newRecord.priority = record.priority;
      }

      if (record.ttl) {
        newRecord.ttl = record.ttl > 300 ? record.ttl : 300;
      }

      if (record.comment) {
        newRecord.comment = record.comment;
      }

      data.push(newRecord);
    });

    var requestOptions = {
      path: urlJoin(_urlPrefix, zoneId, _recordFragment),
      method: 'POST',
      body: {
        records: data
      }
    };

    self._asyncRequest(requestOptions, function (err, result) {
      return err
        ? callback(err)
        : callback(err, result.response.records.map(function (record) {
        return new dns.Record(self, record);
      }));
    });
  },

  /**
   * @name Client.deleteRecord
   * @description delete a dns record for a given domain
   * @param {object|Number}     zone          the zone of the record to query for
   * @param {object|String}     record        the record to query for
   * @param {Function}    callback    handles the callback of your api call
   */
  deleteRecord: function (zone, record, callback) {
    var self = this,
        zoneId = zone instanceof dns.Zone ? zone.id : zone,
        recordId = record instanceof dns.Record ? record.id : record;

    var requestOptions = {
      path: urlJoin(_urlPrefix, zoneId, _recordFragment, recordId),
      method: 'DELETE'
    };

    self._asyncRequest(requestOptions, function (err) {
      return callback(err);
    });
  },

  /**
   * @name Client.deleteRecords
   * @description deletes multiple dns records for a given domain
   * @param {object|Number}     zone          the zone of the record to query for
   * @param {Array}       records     the array of ids to delete
   * @param {Function}    callback    handles the callback of your api call
   */
  deleteRecords: function (zone, records, callback) {
    var self = this,
        zoneId = zone instanceof dns.Zone ? zone.id : zone;

    var ids = _.map(records, function(record) {
      return 'id=' +
        (record instanceof dns.Record
        ? record.id
        : record);
    });

    var requestOptions = {
      path: urlJoin(_urlPrefix, zoneId, _recordFragment + '?' + ids.join('&')),
      method: 'DELETE'
    };

    self._asyncRequest(requestOptions, function (err, result) {
      return callback(err);
    });
  }
};