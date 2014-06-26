/*
 * snapshots.js: Instance methods for working with SnapShots from OpenStack Block Storage
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 *
 */
var errs = require('errs'),
    Snapshot = require('../snapshot').Snapshot,
    urlJoin = require('url-join');

var _urlPrefix = 'snapshots';

/**
 * client.getSnapshots
 *
 * @description Get the snapshots for an account
 *
 * @param {boolean|function}    options  Optional. If provided, gets the
 * full details for the snapshots
 * @param {function}        callback
 * @returns {*}
 */
exports.getSnapshots = function (options, callback) {
  var self = this,
      path = _urlPrefix;

  if (typeof options === 'function') {
    callback = options;
  }
  else if ((typeof options === 'boolean') && (options)) {
    path = urlJoin(_urlPrefix, 'details');
  }

  return self._request({
    path: path
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, body.snapshots.map(function (data) {
      return new Snapshot(self, data);
    }), res);
  });
};

/**
 * client.getSnapshot
 *
 * @description Get the details for the provided snapshot
 *
 * @param {object|String}   snapshot  The snapshot or snapshot id for the query
 * @param {function}        callback
 * @returns {*}
 */
exports.getSnapshot = function (snapshot, callback) {
  var self = this,
      snapshotId = snapshot instanceof Snapshot ? snapshot.id : snapshot;

  return self._request({
    path: urlJoin(_urlPrefix, snapshotId)
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(null, new Snapshot(self, body.snapshot));
  });
};

/**
 * client.createSnapshot
 *
 * @description Creates a snapshot from the provided options
 *
 * @param {object}      details   options for the provided create call
 * @param {string}      details.name    the name of the new snapshot
 * @param {string}      details.description   the description for the new snapshot
 * @param {string}      details.volumeId    the volumeId for the new snapshot
 * @param {boolean}     [details.force]   force creation of the snapshot
 * @param {function}    callback
 * @returns {*}
 */
exports.createSnapshot = function(details, callback) {
  var self = this;

  var createOptions = {
    method: 'POST',
    path: _urlPrefix,
    body: {
      snapshot: {
        name: details.name,
        description: details.description,
        force: typeof details.force === 'boolean' ? details.force : false,
        'volume_id': details.volumeId
      }
    }
  };

  self._request(createOptions, function(err, body, res) {
    console.dir(body);
    return err
      ? callback(err)
      : callback(null, new Snapshot(self, body.snapshot));
  });
};

/**
 * client.updateSnapshot
 *
 * @description Updates a snapshot from a current instance
 *
 * @param {object}      snapshot   the snapshot to update
 * @param {string}      snapshot.name    the name of the updated snapshot
 * @param {string}      snapshot.description   the description for the updated snapshot
 * @param {function}    callback
 * @returns {*}
 */
exports.updateSnapshot = function (snapshot, callback) {
  var self = this,
      snapshotId = snapshot instanceof Snapshot ? snapshot.id : snapshot;

  var updateOptions = {
    method: 'PUT',
    path: urlJoin(_urlPrefix, snapshotId),
    body: {
      name: snapshot.name,
      description: snapshot.description
    }
  };

  self._request(updateOptions, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, new Snapshot(self, body.snapshot));
  });
};

/**
 * client.deleteSnapshot
 *
 * @description Deletes a snapshot
 *
 * @param {object|String}     snapshot   the snapshot to delete
 * @param {function}          callback
 * @returns {*}
 */
exports.deleteSnapshot = function (snapshot, callback) {
  var snapshotId = snapshot instanceof Snapshot ? snapshot.id : snapshot;

  return this._request({
    path: urlJoin(_urlPrefix, snapshotId),
    method: 'DELETE'
  }, function (err) {
    return err
      ? callback(err)
      : callback(null, true);
  });
};