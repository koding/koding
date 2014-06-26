/*
 * volumes.js: Instance methods for working with Volumes from CloudBlockStorage
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 *
 */
var errs = require('errs'),
    Volume = require('../volume').Volume,
    VolumeType = require('../volumetype').VolumeType,
    urlJoin = require('url-join');

var _urlPrefix = 'volumes';

/**
 * client.getVolumes
 *
 * @description Get the volumes for an account
 *
 * @param {boolean|function}    options  Optional. If provided, gets the
 * full details for the volumes
 * @param {function}        callback
 * @returns {*}
 */
exports.getVolumes = function (options, callback) {
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
      : callback(null, body.volumes.map(function (data) {
      return new Volume(self, data);
    }), res);
  });
};

/**
 * client.getVolume
 *
 * @description Get the details for the provided volume
 *
 * @param {object|String}   volume  The volume or volume id for the query
 * @param {function}        callback
 * @returns {*}
 */
exports.getVolume = function (volume, callback) {
  var self = this,
    volumeId = volume instanceof Volume ? volume.id : volume;

  return self._request({
    path: urlJoin(_urlPrefix, volumeId)
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(null, new Volume(self, body.volume));
  });
};

/**
 * client.createVolume
 *
 * @description Creates a volume from the provided options
 *
 * @param {object}      options   options for the provided create call
 * @param {string}      options.name    the name of the new volume
 * @param {string}      options.description   the description for the new volume
 * @param {number}      options.size   the size of the new volume in GB
 * @param {String}      [options.snapshotId]   the snapshotId to use in creating the new volume
 * @param {object|String}      [options.volumeType]    the volumeType for the new volume
 * @param {function}    callback
 * @returns {*}
 */
exports.createVolume = function (options, callback) {
  var self = this;

  var createOptions = {
    method: 'POST',
    path: _urlPrefix,
    body: {
      volume: {
        'display_name': options.name,
        'display_description': options.description,
        size: options.size
      }
    }
  };

  if (options.volumeType) {
    createOptions.body.volume['volume_type'] =
      options.volumeType instanceof VolumeType
        ? options.volumeType.name
        : options.volumeType;
  }

  if (options.snapshotId) {
    createOptions.body.volume['snapshot_id'] = options.snapshotId;
  }

  self._request(createOptions, function (err, body) {
    return err
      ? callback(err)
      : callback(null, new Volume(self, body.volume));
  });
};

/**
 * client.updateVolume
 *
 * @description Updates a volume from a current instance
 *
 * @param {object}      volume   the volume to update
 * @param {string}      volume.name    the name of the updated volume
 * @param {string}      volume.description   the description for the updated volume
 * @param {function}    callback
 * @returns {*}
 */
exports.updateVolume = function (volume, callback) {
  var self = this,
      volumeId = volume instanceof Volume ? volume.id : volume;

  var updateOptions = {
    method: 'PUT',
    path: urlJoin(_urlPrefix, volumeId),
    body: {
      name: volume.name,
      description: volume.description
    }
  };

  self._request(updateOptions, function (err, body) {
    return err
      ? callback(err)
      : callback(null, new Volume(self, body.volume));
  });
};

/**
 * client.deleteVolume
 *
 * @description Deletes a volume
 *
 * @param {object|String}     volume   the volume to delete
 * @param {function}          callback
 * @returns {*}
 */
exports.deleteVolume = function (volume, callback) {
  var volumeId = volume instanceof Volume ? volume.id : volume;

  return this._request({
    path: urlJoin(_urlPrefix, volumeId),
    method: 'DELETE'
  }, function (err) {
    return err
      ? callback(err)
      : callback();
  });
};