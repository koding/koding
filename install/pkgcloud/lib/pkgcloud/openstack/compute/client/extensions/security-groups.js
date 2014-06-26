/*
 * security-groups.js Implementation of OpenStack SecurityGroups API
 *
 * (C) 2014, Rackspace Inc.
 *
 */

var urlJoin = require('url-join');

var _extension = 'os-security-groups';

/**
 * client.listGroups
 *
 * @description List security groups for the current compute client
 *
 * @param {Function}    callback    f(err, groups) where groups is an array of security groups
 * @returns {*}
 */
exports.listGroups = function listGroups(options, callback) {

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  return this._request({
    path: _extension
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, body['security_groups'], res);
  });
};

/**
 * client.addGroup
 *
 * @description Create a new security group
 *
 * @param {object|String}   options         The object (or securityGroup to generate) for the new group
 * @param {String}          options.name    The name for the group
 * @param {String}          [options.description]    Optional description
 * @param callback
 * @returns {*}
 */
exports.addGroup = function addGroup(options, callback) {
  var requestOptions = {};

  requestOptions.name = typeof options === 'string' ? options : options.name;

  if (options.description) {
    requestOptions.description = options.description;
  }

  return this._request({
    method: 'POST',
    path: _extension,
    body: {
      security_group: options
    }
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(null, body['security_group']);
  });
};

/**
 * client.destroyGroup
 *
 * @description Delete a security group from the current account
 *
 * @param {String}    name    The name of the group to delete
 * @param {Function}  callback
 * @returns {*}
 */
exports.destroyGroup = function destroyGroup(name, callback) {
  return this._request({
    method: 'DELETE',
    path: urlJoin(_extension, name)
  }, function (err) {
    return callback(err);
  });
};
