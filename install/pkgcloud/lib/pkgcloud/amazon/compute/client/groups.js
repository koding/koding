/*
 * groups.js: Implementation of AWS SecurityGroups Client.
 *
 */

var errs  = require('errs'),
    utile = require('utile');

//
// ### function listGroups (options, callback)
// #### @options {Object} **Optional** Filter parameters when listing keys
// #### @callback {function} Continuation to respond to when complete.
//
// Lists all EC2 SecurityGroups matching the specified `options`.
//
exports.listGroups = function (options, callback) {
  if (!callback && typeof options === 'function') {
    callback = options;
    options = {};
  }

  var self = this;
  options = options || {};

  return this._query('DescribeSecurityGroups', options, function (err, body, res) {
    return err
      ? callback(err)
      : callback(err, self._toArray(body.securityGroupInfo.item));
  });
};

//
// ### function getGroup (name, callback)
// #### @name {string} Name of the EC2 Security Group to get
// #### @callback {function} Continuation to respond to when complete.
//
// Gets the details of the EC2 SecurityGroup with the specified `name`.
//
exports.getGroup = function (name, callback) {
  return this.listGroups({
    'GroupName.1': name
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(null, body[0]);
  });
};

//
// ### function addGroup (options, callback)
// #### @options {Object} Security Group details
// ####     @name {string} String name of the group
// ####     @description  {string} Description of the group
// #### @callback {function} Continuation to respond to when complete.
//
// Adds an EC2 SecurityGroup with the specified `options`.
//
exports.addGroup = function (options, callback) {
  if (!options || !options.name || !options.description) {
    return errs.handle(
      errs.create({ message: '`name` and `description` are required options.' }),
      callback
    );
  }

  return this._query(
    'CreateSecurityGroup',
    {
      GroupName: options.name,
      GroupDescription: options.description
    },
    function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, true);
    }
  );
};

//
// ### function delGroup (name, callback)
// #### @name {string} Name of the EC2 Security Group to destroy
// #### @callback {function} Continuation to respond to when complete.
//
// Destroys EC2 SecurityGroup with the specified `name`.
//
exports.destroyGroup = function (name, callback) {
  return this._query(
    'DeleteSecurityGroup',
    { GroupName: name },
    function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, true);
    }
  );
};

//
// ### function addRules (options, callback)
// #### @options {Object} Ingress rules Group details
// ####     @name {string} String name of the group
// ####     @rules  {object} Ingress rules to apply
// #### @callback {function} Continuation to respond to when complete.
//
// Note: rules must match the format of the AWS API
//  - http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-AuthorizeSecurityGroupIngress.html
//
// Add Ingress Rules to a SecurityGroup with the specified `name`.
//
exports.addRules = function (options, callback) {
  if (!options || !options.name || !options.rules) {
    return errs.handle(
      errs.create({ message: '`name` and `rules` are required options.' }),
      callback
    );
  }

  // Simply append the group name to the rules - override if existing
  var rules = options.rules;
  rules.GroupName = options.name;

  return this._query(
    'AuthorizeSecurityGroupIngress',
    rules ,
    function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, true);
    }
  );
};

//
// ### function delRules (options, callback)
// #### @options {Object} Ingress rules Group details
// ####     @name {string} String name of the group
// ####     @rules  {object} Ingress rules to revoke
// #### @callback {function} Continuation to respond to when complete.
//
// Note: rules must match the format of the AWS API
//  - http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-AuthorizeSecurityGroupIngress.html
//
// Revoke Ingress Rules to a SecurityGroup with the specified `name`.
//
exports.delRules = function (options, callback) {
  if (!options || !options.name || !options.rules) {
    return errs.handle(
      errs.create({ message: '`name` and `rules` are required options.' }),
      callback
    );
  }

  // Simply append the group name to the rules - override if existing
  var rules = options.rules;
  rules.GroupName = options.name;

  return this._query(
    'RevokeSecurityGroupIngress',
    rules ,
    function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, true);
    }
  );
};
