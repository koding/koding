/*
 * accounts.js: Accounts methods for working with databases from MongoLab
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var pkgcloud = require('../../../../../lib/pkgcloud'),
    errs     = require('errs');

// Create Account
// ### @options {Object} Set of options can be
// #### options['name'] {string} Name of account (required)
// #### options['email'] {string} Email of the owner of the account (required)
// #### options['password'] {string} Password for the account (Optional), If not specify so mongolab will generate one.
// ### @callback {Function} Continuation to respond to when complete.
exports.createAccount = function createAccount(options, callback) {
  // Check for options
  if (typeof options === 'function') {
    return errs.handle(errs.create({
      message: 'Options required for create an account.'
    }), options);
  }

  if (!options['name']) {
    return errs.handle(errs.create({
      message: 'options. Name is a required argument'
    }), callback);
  }

  if (!options['email']) {
    return errs.handle(errs.create({
      message: 'options. Email is a required argument'
    }), callback);
  }

  // Add support for the displayName input for mongolab
  // https://objectlabs.jira.com/wiki/display/partners/MongoLab+Partner+Integration+API#MongoLabPartnerIntegrationAPI-Createaccount.1

  var adminUser = { email: options['email'] };

  if (options['password']) {
    if (/[+\d]/g.test(options['password'])) {
      adminUser['password'] = options['password'];
    } else {
      return errs.handle(errs.create({
        message: 'options. Password must contain at least one numeric character.'
      }), callback);
    }
  }

  var createOptions = {
    method: 'POST',
    path: 'accounts',
    body: {
      name: [this.config.username, options['name']].join('_'),
      adminUser: adminUser
    }
  };

  this._request(createOptions, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null, { account: body.adminUser });
  });
};

// Delete Account
// ### @name {String} Name of the account to be deleted
// ### @callback {Function} Continuation to respond to when complete.
exports.deleteAccount = function deleteAccount(name, callback) {
  // Check for options
  if (typeof name === 'function') {
    return errs.handle(errs.create({
      message: 'Name required for delete an account.'
    }), name);
  }

  var deleteOptions = {
    method: 'DELETE',
    path: 'accounts/' + name
  };

  this._request(deleteOptions, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null);
  });
};

// List all accounts
// ### @callback {Function} Continuation to respond to when complete.
exports.getAccounts = function getAccounts(callback) {
  this._request({ path: 'accounts' }, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null, body.map(function (account) {
          return account.adminUser;
        }));
  });
};

// View an account
exports.getAccount = function getAccount(name, callback) {
  // Check for options
  if (typeof name === 'function') {
    return errs.handle(errs.create({
      message: 'Name required for view an account.'
    }), name);
  }

  this._request({ path: 'accounts/' + name }, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null, body.adminUser);
  });
};