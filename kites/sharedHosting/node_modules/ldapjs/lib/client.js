// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var EventEmitter = require('events').EventEmitter;
var net = require('net');
var tls = require('tls');
var util = require('util');

var Attribute = require('./attribute');
var Change = require('./change');
var Control = require('./controls/index').Control;
var Protocol = require('./protocol');
var dn = require('./dn');
var errors = require('./errors');
var filters = require('./filters');
var logStub = require('./log_stub');
var messages = require('./messages');
var url = require('./url');



///--- Globals

var AbandonRequest = messages.AbandonRequest;
var AddRequest = messages.AddRequest;
var BindRequest = messages.BindRequest;
var CompareRequest = messages.CompareRequest;
var DeleteRequest = messages.DeleteRequest;
var ExtendedRequest = messages.ExtendedRequest;
var ModifyRequest = messages.ModifyRequest;
var ModifyDNRequest = messages.ModifyDNRequest;
var SearchRequest = messages.SearchRequest;
var UnbindRequest = messages.UnbindRequest;
var UnbindResponse = messages.UnbindResponse;

var LDAPResult = messages.LDAPResult;
var SearchEntry = messages.SearchEntry;
var SearchReference = messages.SearchReference;
var SearchResponse = messages.SearchResponse;
var Parser = messages.Parser;


var Filter = filters.Filter;
var PresenceFilter = filters.PresenceFilter;


var MAX_MSGID = Math.pow(2, 31) - 1;



///--- Internal Helpers

function xor() {
  var b = false;
  for (var i = 0; i < arguments.length; i++) {
    if (arguments[i] && !b) b = true;
    else if (arguments[i] && b) return false;
  }
  return b;
}


function validateControls(controls) {
  if (Array.isArray(controls)) {
    controls.forEach(function(c) {
      if (!(c instanceof Control))
        throw new TypeError('controls must be [Control]');
    });
  } else if (controls instanceof Control) {
    controls = [controls];
  } else {
    throw new TypeError('controls must be [Control]');
  }

  return controls;
}


function ConnectionError(message) {
  errors.LDAPError.call(this,
                        'ConnectionError',
                        0x80, // LDAP_OTHER,
                        message,
                        null,
                        ConnectionError);
}
util.inherits(ConnectionError, errors.LDAPError);



///--- API

/**
 * Constructs a new client.
 *
 * The options object is required, and must contain either a URL (string) or
 * a socketPath (string); the socketPath is only if you want to talk to an LDAP
 * server over a Unix Domain Socket.  Additionally, you can pass in a log4js
 * option that is the result of `require('log4js')`, presumably after you've
 * configured it.
 *
 * @param {Object} options must have either url or socketPath.
 * @throws {TypeError} on bad input.
 */
function Client(options) {
  if (!options || typeof(options) !== 'object')
    throw new TypeError('options (object) required');
  if (options.url && typeof(options.url) !== 'string')
    throw new TypeError('options.url (string) required');
  if (options.socketPath && typeof(options.socketPath) !== 'string')
    throw new TypeError('options.socketPath must be a string');
  if (options.log4js && typeof(options.log4js) !== 'object')
    throw new TypeError('options.log4s must be an object');

  if (!xor(options.url, options.socketPath))
    throw new TypeError('options.url ^ options.socketPath required');

  EventEmitter.call(this, options);

  var self = this;
  this.secure = false;
  if (options.url) {
    this.url = url.parse(options.url);
    this.secure = this.url.secure;
  }

  this.connection = null;
  this.connectTimeout = options.connectTimeout || false;
  this.connectOptions = {
    port: self.url ? self.url.port : options.socketPath,
    host: self.url ? self.url.hostname : undefined,
    socketPath: options.socketPath || undefined
  };
  this.log4js = options.log4js || logStub;
  this.reconnect = (typeof(options.reconnect) === 'number' ?
                    options.reconnect : 1000);
  this.shutdown = false;
  this.timeout = options.timeout || false;

  this.__defineGetter__('log', function() {
    if (!self._log)
      self._log = self.log4js.getLogger('Client');

    return self._log;
  });

  return this.connect(function() {});
}
util.inherits(Client, EventEmitter);
module.exports = Client;


/**
 * Connects this client, either at construct time, or after an unbind has
 * been called. Under normal circumstances you don't need to call this method.
 *
 * @param {Function} callback invoked when `connect()` is done.
 */
Client.prototype.connect = function(callback) {
  if (this.connection)
    return callback();

  var self = this;
  var timer = false;
  if (this.connectTimeout) {
    timer = setTimeout(function() {
      if (self.connection)
        self.connection.destroy();

      var err = new ConnectionError('timeout');
      self.emit('connectTimeout');
      return callback(err);
    }, this.connectTimeout);
  }

  this.connection = this._newConnection();

  function reconnect() {
    self.connection = null;

    if (self.reconnect)
      setTimeout(function() { self.connect(function() {}); }, self.reconnect);
  }

  self.connection.on('close', function(had_err) {
    self.emit('close', had_err);
    reconnect();
  });

  self.connection.on('connect', function() {
    if (timer)
      clearTimeout(timer);

    if (self._bindDN && self._credentials)
      return self.bind(self._bindDN, self._credentials, function(err) {
        if (err) {
          self.log.error('Unable to bind(on(\'connect\')): %s', err.stack);
          self.connection.end();
        }

        return callback();
      });

    return callback();
  });

  return false;
};


/**
 * Performs a simple authentication against the server.
 *
 * @param {String} name the DN to bind as.
 * @param {String} credentials the userPassword associated with name.
 * @param {Control} controls (optional) either a Control or [Control].
 * @param {Function} callback of the form f(err, res).
 * @param {Socket} conn don't use this. Internal only (reconnects).
 * @throws {TypeError} on invalid input.
 */
Client.prototype.bind = function(name, credentials, controls, callback, conn) {
  if (typeof(name) !== 'string' && !(name instanceof dn.DN))
    throw new TypeError('name (string) required');
  if (typeof(credentials) !== 'string')
    throw new TypeError('credentials (string) required');
  if (typeof(controls) === 'function') {
    callback = controls;
    controls = [];
  } else {
    controls = validateControls(controls);
  }
  if (typeof(callback) !== 'function')
    throw new TypeError('callback (function) required');


  var self = this;
  this.connect(function() {
    var req = new BindRequest({
      name: name || '',
      authentication: 'Simple',
      credentials: credentials || '',
      controls: controls
    });

    return self._send(req, [errors.LDAP_SUCCESS], function(err, res) {
      if (!err) { // In case we need to reconnect later
        self._bindDN = name;
        self._credentials = credentials;
      }

      return callback(err, res);
    }, conn);
  });
};


/**
 * Sends an abandon request to the LDAP server.
 *
 * The callback will be invoked as soon as the data is flushed out to the
 * network, as there is never a response from abandon.
 *
 * @param {Number} messageID the messageID to abandon.
 * @param {Control} controls (optional) either a Control or [Control].
 * @param {Function} callback of the form f(err).
 * @throws {TypeError} on invalid input.
 */
Client.prototype.abandon = function(messageID, controls, callback) {
  if (typeof(messageID) !== 'number')
    throw new TypeError('messageID (number) required');
  if (typeof(controls) === 'function') {
    callback = controls;
    controls = [];
  } else {
    controls = validateControls(controls);
  }
  if (typeof(callback) !== 'function')
    throw new TypeError('callback (function) required');

  var req = new AbandonRequest({
    abandonID: messageID,
    controls: controls
  });

  return this._send(req, 'abandon', callback);
};


/**
 * Adds an entry to the LDAP server.
 *
 * Entry can be either [Attribute] or a plain JS object where the
 * values are either a plain value or an array of values.  Any value (that's
 * not an array) will get converted to a string, so keep that in mind.
 *
 * @param {String} name the DN of the entry to add.
 * @param {Object} entry an array of Attributes to be added or a JS object.
 * @param {Control} controls (optional) either a Control or [Control].
 * @param {Function} callback of the form f(err, res).
 * @throws {TypeError} on invalid input.
 */
Client.prototype.add = function(name, entry, controls, callback) {
  if (typeof(name) !== 'string')
    throw new TypeError('name (string) required');
  if (typeof(entry) !== 'object')
    throw new TypeError('entry (object) required');
  if (typeof(controls) === 'function') {
    callback = controls;
    controls = [];
  } else {
    controls = validateControls(controls);
  }
  if (typeof(callback) !== 'function')
    throw new TypeError('callback (function) required');

  if (Array.isArray(entry)) {
    entry.forEach(function(a) {
      if (!Attribute.isAttribute(a))
        throw new TypeError('entry must be an Array of Attributes');
    });
  } else {
    var save = entry;

    entry = [];
    Object.keys(save).forEach(function(k) {
      var attr = new Attribute({type: k});
      if (Array.isArray(save[k])) {
        save[k].forEach(function(v) {
          attr.addValue(v.toString());
        });
      } else {
        attr.addValue(save[k].toString());
      }
      entry.push(attr);
    });
  }

  var req = new AddRequest({
    entry: dn.parse(name),
    attributes: entry,
    controls: controls
  });

  return this._send(req, [errors.LDAP_SUCCESS], callback);
};


/**
 * Compares an attribute/value pair with an entry on the LDAP server.
 *
 * @param {String} name the DN of the entry to compare attributes with.
 * @param {String} attr name of an attribute to check.
 * @param {String} value value of an attribute to check.
 * @param {Control} controls (optional) either a Control or [Control].
 * @param {Function} callback of the form f(err, boolean, res).
 * @throws {TypeError} on invalid input.
 */
Client.prototype.compare = function(name, attr, value, controls, callback) {
  if (typeof(name) !== 'string')
    throw new TypeError('name (string) required');
  if (typeof(attr) !== 'string')
    throw new TypeError('attribute (string) required');
  if (typeof(value) !== 'string')
    throw new TypeError('value (string) required');
  if (typeof(controls) === 'function') {
    callback = controls;
    controls = [];
  } else {
    controls = validateControls(controls);
  }
  if (typeof(callback) !== 'function')
    throw new TypeError('callback (function) required');

  var req = new CompareRequest({
    entry: dn.parse(name),
    attribute: attr,
    value: value,
    controls: controls
  });

  function _callback(err, res) {
    if (err)
      return callback(err);

    return callback(null, (res.status === errors.LDAP_COMPARE_TRUE), res);
  }

  return this._send(req,
                    [errors.LDAP_COMPARE_TRUE, errors.LDAP_COMPARE_FALSE],
                    _callback);
};


/**
 * Deletes an entry from the LDAP server.
 *
 * @param {String} name the DN of the entry to delete.
 * @param {Control} controls (optional) either a Control or [Control].
 * @param {Function} callback of the form f(err, res).
 * @throws {TypeError} on invalid input.
 */
Client.prototype.del = function(name, controls, callback) {
  if (typeof(name) !== 'string')
    throw new TypeError('name (string) required');
  if (typeof(controls) === 'function') {
    callback = controls;
    controls = [];
  } else {
    controls = validateControls(controls);
  }
  if (typeof(callback) !== 'function')
    throw new TypeError('callback (function) required');

  var req = new DeleteRequest({
    entry: dn.parse(name),
    controls: controls
  });

  return this._send(req, [errors.LDAP_SUCCESS], callback);
};


/**
 * Performs an extended operation on the LDAP server.
 *
 * Pretty much none of the LDAP extended operations return an OID
 * (responseName), so I just don't bother giving it back in the callback.
 * It's on the third param in `res` if you need it.
 *
 * @param {String} name the OID of the extended operation to perform.
 * @param {String} value value to pass in for this operation.
 * @param {Control} controls (optional) either a Control or [Control].
 * @param {Function} callback of the form f(err, value, res).
 * @throws {TypeError} on invalid input.
 */
Client.prototype.exop = function(name, value, controls, callback) {
  if (typeof(name) !== 'string')
    throw new TypeError('name (string) required');
  if (typeof(value) === 'function') {
    callback = value;
    controls = [];
    value = '';
  }
  if (typeof(value) !== 'string')
    throw new TypeError('value (string) required');
  if (typeof(controls) === 'function') {
    callback = controls;
    controls = [];
  } else {
    controls = validateControls(controls);
  }
  if (typeof(callback) !== 'function')
    throw new TypeError('callback (function) required');

  var req = new ExtendedRequest({
    requestName: name,
    requestValue: value,
    controls: controls
  });

  function _callback(err, res) {
    if (err)
      return callback(err);

    return callback(null, res.responseValue || '', res);
  }

  return this._send(req, [errors.LDAP_SUCCESS], _callback);
};


/**
 * Performs an LDAP modify against the server.
 *
 * @param {String} name the DN of the entry to modify.
 * @param {Change} change update to perform (can be [Change]).
 * @param {Control} controls (optional) either a Control or [Control].
 * @param {Function} callback of the form f(err, res).
 * @throws {TypeError} on invalid input.
 */
Client.prototype.modify = function(name, change, controls, callback) {
  if (typeof(name) !== 'string')
    throw new TypeError('name (string) required');
  if (typeof(change) !== 'object')
    throw new TypeError('change (Change) required');

  var changes = [];

  function changeFromObject(change) {
    if (!change.operation && !change.type)
      throw new Error('change.operation required');
    if (typeof(change.modification) !== 'object')
      throw new Error('change.modification (object) required');

    Object.keys(change.modification).forEach(function(k) {
      var mod = {};
      mod[k] = change.modification[k];
      changes.push(new Change({
        operation: change.operation || change.type,
        modification: mod
      }));
    });
  }

  if (change instanceof Change) {
    changes.push(change);
  } else if (Array.isArray(change)) {
    change.forEach(function(c) {
      if (c instanceof Change) {
        changes.push(c);
      } else {
        changeFromObject(c);
      }
    });
  } else {
    changeFromObject(change);
  }

  if (typeof(controls) === 'function') {
    callback = controls;
    controls = [];
  } else {
    controls = validateControls(controls);
  }
  if (typeof(callback) !== 'function')
    throw new TypeError('callback (function) required');

  var req = new ModifyRequest({
    object: dn.parse(name),
    changes: changes,
    controls: controls
  });

  return this._send(req, [errors.LDAP_SUCCESS], callback);
};


/**
 * Performs an LDAP modifyDN against the server.
 *
 * This does not allow you to keep the old DN, as while the LDAP protocol
 * has a facility for that, it's stupid. Just Search/Add.
 *
 * This will automatically deal with "new superior" logic.
 *
 * @param {String} name the DN of the entry to modify.
 * @param {String} newName the new DN to move this entry to.
 * @param {Control} controls (optional) either a Control or [Control].
 * @param {Function} callback of the form f(err, res).
 * @throws {TypeError} on invalid input.
 */
Client.prototype.modifyDN = function(name, newName, controls, callback) {
  if (typeof(name) !== 'string')
    throw new TypeError('name (string) required');
  if (typeof(newName) !== 'string')
    throw new TypeError('newName (string) required');
  if (typeof(controls) === 'function') {
    callback = controls;
    controls = [];
  } else {
    controls = validateControls(controls);
  }
  if (typeof(callback) !== 'function')
    throw new TypeError('callback (function) required');

  var DN = dn.parse(name);
  var newDN = dn.parse(newName);

  var req = new ModifyDNRequest({
    entry: DN,
    deleteOldRdn: true,
    controls: controls
  });

  if (newDN.length !== 1) {
    req.newRdn = dn.parse(newDN.rdns.shift().toString());
    req.newSuperior = newDN;
  } else {
    req.newRdn = newDN;
  }

  return this._send(req, [errors.LDAP_SUCCESS], callback);
};


/**
 * Performs an LDAP search against the server.
 *
 * Note that the defaults for options are a 'base' search, if that's what
 * you want you can just pass in a string for options and it will be treated
 * as the search filter.  Also, you can either pass in programatic Filter
 * objects or a filter string as the filter option.
 *
 * Note that this method is 'special' in that the callback 'res' param will
 * have two important events on it, namely 'entry' and 'end' that you can hook
 * to.  The former will emit a SearchEntry object for each record that comes
 * back, and the latter will emit a normal LDAPResult object.
 *
 * @param {String} base the DN in the tree to start searching at.
 * @param {Object} options parameters:
 *                           - {String} scope default of 'base'.
 *                           - {String} filter default of '(objectclass=*)'.
 *                           - {Array} attributes [string] to return.
 *                           - {Boolean} attrsOnly whether to return values.
 * @param {Control} controls (optional) either a Control or [Control].
 * @param {Function} callback of the form f(err, res).
 * @throws {TypeError} on invalid input.
 */
Client.prototype.search = function(base, options, controls, callback) {
  if (typeof(base) !== 'string' && !(base instanceof dn.DN))
    throw new TypeError('base (string) required');
  if (Array.isArray(options) || (options instanceof Control)) {
    controls = options;
    options = {};
  } else if (typeof(options) === 'function') {
    callback = options;
    controls = [];
    options = {
      filter: new PresenceFilter({attribute: 'objectclass'})
    };
  } else if (typeof(options) === 'string') {
    options = {filter: filters.parseString(options)};
  } else if (typeof(options) !== 'object') {
    throw new TypeError('options (object) required');
  }
  if (typeof(options.filter) === 'string') {
    options.filter = filters.parseString(options.filter);
  } else if (!options.filter) {
    options.filter = new PresenceFilter({attribute: 'objectclass'});
  } else if (!(options.filter instanceof Filter)) {
    throw new TypeError('options.filter (Filter) required');
  }

  if (typeof(controls) === 'function') {
    callback = controls;
    controls = [];
  } else {
    controls = validateControls(controls);
  }
  if (typeof(callback) !== 'function')
    throw new TypeError('callback (function) required');

  if (options.attributes) {
    if (Array.isArray(options.attributes)) {
      // noop
    } else if (typeof(options.attributes) === 'string') {
      options.attributes = [options.attributes];
    } else {
      throw new TypeError('options.attributes must be an Array of Strings');
    }
  }
  var req = new SearchRequest({
    baseObject: typeof(base) === 'string' ? dn.parse(base) : base,
    scope: options.scope || 'base',
    filter: options.filter,
    derefAliases: Protocol.NEVER_DEREF_ALIASES,
    sizeLimit: options.sizeLimit || 0,
    timeLimit: options.timeLimit || 10,
    typesOnly: options.typesOnly || false,
    attributes: options.attributes || [],
    controls: controls
  });



  if (!this.connection)
    return callback(new ConnectionError('no connection'));

  var res = new EventEmitter();

  // This is some whacky logic to account for the connection not being
  // reconnected, and having thrown an error like "NotWriteable". Because
  // the event emitter logic will never block, we'll end up returning from
  // the event.on('error'), rather than "normally".
  var done = false;
  function errorIfNoConn(err) {
    if (done)
      return false;

    done = true;
    return callback(err);
  }
  res.once('error', errorIfNoConn);
  this._send(req, [errors.LDAP_SUCCESS], res);

  done = true;
  res.removeListener('error', errorIfNoConn);
  return callback(null, res);
};


/**
 * Unbinds this client from the LDAP server.
 *
 * Note that unbind does not have a response, so this callback is actually
 * optional; either way, the client is disconnected.
 *
 * @param {Function} callback of the form f(err).
 * @throws {TypeError} if you pass in callback as not a function.
 */
Client.prototype.unbind = function(callback) {
  if (callback && typeof(callback) !== 'function')
    throw new TypeError('callback must be a function');
  if (!callback)
    callback = function() { self.log.trace('disconnected'); };

  var self = this;
  this.reconnect = false;
  this._bindDN = null;
  this._credentials = null;

  if (!this.connection)
    return callback();

  var req = new UnbindRequest();
  return self._send(req, 'unbind', callback);
};



Client.prototype._send = function(message, expect, callback, connection) {
  assert.ok(message);
  assert.ok(expect);
  assert.ok(callback);

  var conn = connection || this.connection;

  var self = this;
  var timer;

  function closeConn(err) {
    if (timer)
      clearTimeout(timer);

    err = err || new ConnectionError('no connection');

    if (typeof(callback) === 'function') {
      callback(err);
    } else {
      callback.emit('error', err);
    }

    if (conn)
      conn.destroy();
  }

  if (!conn)
    return closeConn();

  // Now set up the callback in the messages table
  message.messageID = conn.ldap.nextMessageID;
  if (expect !== 'abandon') {
    conn.ldap.messages[message.messageID] = function(res) {
      if (timer)
        clearTimeout(timer);

      if (self.log.isDebugEnabled())
        self.log.debug('%s: response received: %j', conn.ldap.id, res.json);

      var err = null;

      if (res instanceof LDAPResult) {
        delete conn.ldap.messages[message.messageID];

        if (expect.indexOf(res.status) === -1) {
          err = errors.getError(res);
          if (typeof(callback) === 'function')
            return callback(err);

          return callback.emit('error', err);
        }

        if (typeof(callback) === 'function')
          return callback(null, res);

        callback.emit('end', res);
      } else if (res instanceof SearchEntry) {
        assert.ok(callback instanceof EventEmitter);
        callback.emit('searchEntry', res);

      } else if (res instanceof SearchReference) {
        assert.ok(callback instanceof EventEmitter);
        callback.emit('searchReference', res);

      } else if (res instanceof Error) {
        if (typeof(callback) === 'function')
          return callback(res);

        assert.ok(callback instanceof EventEmitter);
        callback.emit('error', res);
      } else {
        delete conn.ldap.messages[message.messageID];

        err = new errors.ProtocolError(res.type);
        if (typeof(callback) === 'function')
          return callback(err);

        callback.emit('error', err);
      }

      return false;
    };
  }

  // If there's a user specified timeout, pick that up
  if (this.timeout) {
    timer = setTimeout(function() {
      self.emit('timeout', message);
      if (conn.ldap.messages[message.messageID])
        conn.ldap.messages[message.messageID](new LDAPResult({
          status: 80, // LDAP_OTHER
          errorMessage: 'request timeout (client interrupt)'
        }));
    }, this.timeout);
  }

  try {
    // Note if this was an unbind, we just go ahead and end, since there
    // will never be a response
    var _writeCb = null;
    if (expect === 'abandon') {
      _writeCb = function() {
        return callback();
      };
    } else if (expect === 'unbind') {
      _writeCb = function() {
        conn.unbindMessageID = message.id;
        conn.end();
      };
    }

    // Finally send some data
    if (this.log.isDebugEnabled())
      this.log.debug('%s: sending request: %j', conn.ldap.id, message.json);
    return conn.write(message.toBer(), _writeCb);
  } catch (e) {
    return closeConn(e);
  }
};


Client.prototype._newConnection = function() {
  var c;
  var connectOpts = this.connectOptions;
  var log = this.log;
  var self = this;

  if (this.secure) {
    c = tls.connect(connectOpts.port, connectOpts.host, function() {
      if (log.isTraceEnabled())
        log.trace('%s connect event', c.ldap.id);

      c.ldap.connected = true;
      c.ldap.id += c.fd ? (':' + c.fd) : '';
      c.emit('connect', c.ldap.id);
    });
    c.setKeepAlive = function(enable, delay) {
      return c.socket.setKeepAlive(enable, delay);
    };
  } else {
    c = net.createConnection(connectOpts.port, connectOpts.host);
  }
  assert.ok(c);

  c.parser = new Parser({
    log4js: self.log4js
  });

  // Wrap the events
  c.ldap = {
    id: self.url ? self.url.hostname : connectOpts.socketPath,
    messageID: 0,
    messages: {}
  };

  c.ldap.__defineGetter__('nextMessageID', function() {
    if (++c.ldap.messageID >= MAX_MSGID)
      c.ldap.messageID = 1;
    return c.ldap.messageID;
  });

  c.on('connect', function() {
    if (log.isTraceEnabled())
      log.trace('%s connect event', c.ldap.id);

    c.ldap.connected = true;
    c.ldap.id += c.fd ? (':' + c.fd) : '';
    self.emit('connect', c.ldap.id);
  });

  c.on('end', function() {
    if (log.isTraceEnabled())
      log.trace('%s end event', c.ldap.id);

    c.end();
  });

  c.on('close', function(had_err) {
    if (log.isTraceEnabled())
      log.trace('%s close event had_err=%s', c.ldap.id, had_err ? 'yes' : 'no');

    Object.keys(c.ldap.messages).forEach(function(msgid) {
      var err;
      if (c.unbindMessageID !== parseInt(msgid, 10)) {
        err = new ConnectionError(c.ldap.id + ' closed');
      } else {
        err = new UnbindResponse({
          messageID: msgid
        });
        err.status = 'unbind';
      }

      if (typeof(c.ldap.messages[msgid]) === 'function') {
        var callback = c.ldap.messages[msgid];
        delete c.ldap.messages[msgid];
        return callback(err);
      } else if (c.ldap.messages[msgid]) {
        if (err instanceof Error)
          c.ldap.messages[msgid].emit('error', err);
        delete c.ldap.messages[msgid];
      }

      delete c.ldap;
      delete c.parser;
      return false;
    });
  });

  c.on('error', function(err) {
    if (log.isTraceEnabled())
      log.trace('%s error event=%s', c.ldap.id, err ? err.stack : '?');

    if (self.listeners('error').length)
      self.emit('error', err);

    c.end();
  });

  c.on('timeout', function() {
    if (log.isTraceEnabled())
      log.trace('%s timeout event=%s', c.ldap.id);

    self.emit('timeout');
    c.end();
  });

  c.on('data', function(data) {
    if (log.isTraceEnabled())
      log.trace('%s data event: %s', c.ldap.id, util.inspect(data));

    c.parser.write(data);
  });

  // The "router"
  c.parser.on('message', function(message) {
    message.connection = c;
    var callback = c.ldap.messages[message.messageID];

    if (!callback) {
      log.error('%s: unsolicited message: %j', c.ldap.id, message.json);
      return false;
    }

    return callback(message);
  });

  c.parser.on('error', function(err) {
    if (log.isTraceEnabled())
      log.trace('%s error event=%s', c.ldap.id, err ? err.stack : '?');

    if (self.listeners('error').length)
      self.emit('error', err);

    c.end();
  });

  return c;
};
