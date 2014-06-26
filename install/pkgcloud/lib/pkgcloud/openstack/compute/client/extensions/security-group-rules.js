/*
 * security-group-rules.js Implementation of OpenStack SecurityGroup Rules API
 *
 * (C) 2014, Rackspace Inc.
 *
 */

var urlJoin = require('url-join'),
    _ = require('underscore'),
    async = require('async');

var _extension = 'os-security-group-rules';

/**
 * client.addRule
 *
 * @description Add a rule to a security group
 *
 * @param {object}      options     options for the new group
 * @param {string}      options.groupId   the id of the security group to add the rule to
 * @param {number}      options.fromPort  source port for the rule
 * @param {number}      options.toPort    destination port
 * @param {string}      options.ipProtocol  tcp, udp, or icmp
 * @param {string}      options.cidr      source address range for the rule
 *
 * @param {Function}    callback    f(err, rule) where rule is the new security group rule
 * @returns {*}
 */
exports.addRule = function addRule(options, callback) {

  var requestOptions = {
    parent_group_id: options.groupId,
    cidr: options.cidr,
    from_port: options.fromPort,
    to_port: options.toPort,
    ip_protocol: options.ipProtocol
  };

  return this._request({
    method: 'POST',
    path: _extension,
    body: {
      security_group_rule: requestOptions
    }
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, body['security_group_rule'], res);
  });
};

/**
 * client.addRules
 *
 * @description Add an array of rules to a security group
 *
 * @param {Array}       rules       the rules to create
 * @param {Function}    callback    f(err, rules) where rules is an array of rules created
 * @returns {*}
 */
exports.addRules = function(rules, callback) {
  var created = [],
    self = this;
  async.forEachLimit(rules, 5, function(rule, next) {
    self.addRule(rule, function(err, rule) {
      if (err) {
        next(err);
        return;
      }

      created.push(rule);
      next();
    });
  }, function(err) {
    if (err) {
      callback(err);
      return;
    }

    callback(null, created);
  });
};
