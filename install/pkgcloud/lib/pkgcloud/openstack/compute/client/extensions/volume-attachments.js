/*
 * volume-attachments.js: OpenStack BlockStorage snapshot
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var Server = require('../../server').Server,
    urlJoin = require('url-join');

var _urlPrefix = '/servers',
    _extension = 'os-volume_attachments';

/**
 * client.getVolumeAttachments
 *
 * @description Get the attached volumes for a server
 *
 * @param {object|String}   server    The server or serverId to get volumes for
 * @param {function}        callback
 * @returns {*}
 */
exports.getVolumeAttachments = function(server, callback) {
  var serverId = server instanceof Server ? server.id : server;

  return this._request({
    path: urlJoin(_urlPrefix, serverId, _extension)
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, body.volumeAttachments, res);
  });
};

/**
 * client.getVolumeAttachmentDetails
 *
 * @description Get the details of an attached volume from a server
 *
 * @param {object|String}   server    The server or serverId for the volume
 * @param {object|String}   volume    The volume or volumeId to get details for
 * @param {function}        callback
 * @returns {*}
 */
exports.getVolumeAttachmentDetails = function (server, attachment, callback) {
  var serverId = server instanceof Server ? server.id : server,
      attachmentId = (typeof attachment === 'object') ? attachment.id : attachment;

  return this._request({
    path: urlJoin(_urlPrefix, serverId, _extension, attachmentId)
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, body.volumeAttachment, res);
  });
};

/**
 * client.detachVolume
 *
 * @description Detaches the provided volume id from the provided server id
 *
 * @param {object|String}   server    The server or serverId to detach the volume to
 * @param {object|String}   volume    The volume or volumeId to detach from the server
 * @param {function}        callback
 * @returns {*}
 */
exports.detachVolume = function(server, attachment, callback) {
  var serverId = server instanceof Server ? server.id : server,
      attachmentId = (typeof attachment === 'object') ? attachment.id : attachment;

  return this._request({
    path: urlJoin(_urlPrefix, serverId, _extension, attachmentId),
    method: 'DELETE'
  }, function (err) {
    return callback(err);
  });
};

/**
 * client.attachVolume
 *
 * @description Attaches the provided volume id to the provided server id
 *
 * @param {object|String}   server    The server or serverId to attach the volume to
 * @param {object|String}   volume    The volume or volumeId to attach to the server
 * @param {function}        callback
 * @returns {*}
 */
exports.attachVolume = function (server, volume, callback) {
  var serverId = server instanceof Server ? server.id : server,
      volumeId = (typeof volume === 'object') ? volume.id : volume;

  return this._request({
    path: urlJoin(_urlPrefix, serverId, _extension),
    body: {
      volumeAttachment: {
        device: null,
        volumeId: volumeId
      }
    },
    method: 'POST'
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(null, body.volumeAttachment);
  });
};