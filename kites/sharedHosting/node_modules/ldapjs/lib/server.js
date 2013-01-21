// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var EventEmitter = require('events').EventEmitter;
var net = require('net');
var tls = require('tls');
var util = require('util');

var asn1 = require('asn1');
var sprintf = require('sprintf').sprintf;

var dn = require('./dn');
var dtrace = require('./dtrace');
var errors = require('./errors');
var Protocol = require('./protocol');
var logStub = require('./log_stub');

var Parser = require('./messages').Parser;
var AbandonResponse = require('./messages/abandon_response');
var AddResponse = require('./messages/add_response');
var BindResponse = require('./messages/bind_response');
var CompareResponse = require('./messages/compare_response');
var DeleteResponse = require('./messages/del_response');
var ExtendedResponse = require('./messages/ext_response');
var LDAPResult = require('./messages/result');
var ModifyResponse = require('./messages/modify_response');
var ModifyDNResponse = require('./messages/moddn_response');
var SearchRequest = require('./messages/search_request');
var SearchResponse = require('./messages/search_response');
var UnbindResponse = require('./messages/unbind_response');



///--- Globals

var Ber = asn1.Ber;
var BerReader = asn1.BerReader;
var DN = dn.DN;


///--- Helpers

function mergeFunctionArgs(argv, start, end) {
  assert.ok(argv);

  if (!start)
    start = 0;
  if (!end)
    end = argv.length;

  var handlers = [];

  for (var i = start; i < end; i++) {
    if (argv[i] instanceof Array) {
      var arr = argv[i];
      for (var j = 0; j < arr.length; j++) {
        if (!(arr[j] instanceof Function)) {
          throw new TypeError('Invalid argument type: ' + typeof(arr[j]));
        }
        handlers.push(arr[j]);
      }
    } else if (argv[i] instanceof Function) {
      handlers.push(argv[i]);
    } else {
      throw new TypeError('Invalid argument type: ' + typeof(argv[i]));
    }
  }

  return handlers;
}


function getResponse(req) {
  assert.ok(req);

  var Response;

  switch (req.protocolOp) {
  case Protocol.LDAP_REQ_BIND:
    Response = BindResponse;
    break;
  case Protocol.LDAP_REQ_ABANDON:
    Response = AbandonResponse;
    break;
  case Protocol.LDAP_REQ_ADD:
    Response = AddResponse;
    break;
  case Protocol.LDAP_REQ_COMPARE:
    Response = CompareResponse;
    break;
  case Protocol.LDAP_REQ_DELETE:
    Response = DeleteResponse;
    break;
  case Protocol.LDAP_REQ_EXTENSION:
    Response = ExtendedResponse;
    break;
  case Protocol.LDAP_REQ_MODIFY:
    Response = ModifyResponse;
    break;
  case Protocol.LDAP_REQ_MODRDN:
    Response = ModifyDNResponse;
    break;
  case Protocol.LDAP_REQ_SEARCH:
    Response = SearchResponse;
    break;
  case Protocol.LDAP_REQ_UNBIND:
    Response = UnbindResponse;
    break;
  default:
    return null;
  }
  assert.ok(Response);

  var res = new Response({
    messageID: req.messageID,
    log4js: req.log4js,
    attributes: ((req instanceof SearchRequest) ? req.attributes : undefined)
  });
  res.connection = req.connection;
  res.logId = req.logId;

  return res;
}


function defaultHandler(req, res, next) {
  assert.ok(req);
  assert.ok(res);
  assert.ok(next);

  res.matchedDN = req.dn.toString();
  res.errorMessage = 'Server method not implemented';
  res.end(errors.LDAP_OTHER);
  return next();
}


function defaultNoOpHandler(req, res, next) {
  assert.ok(req);
  assert.ok(res);
  assert.ok(next);

  res.end();
  return next();
}


function noSuffixHandler(req, res, next) {
  assert.ok(req);
  assert.ok(res);
  assert.ok(next);

  res.errorMessage = 'No tree found for: ' + req.dn.toString();
  res.end(errors.LDAP_NO_SUCH_OBJECT);
  return next();
}


function noExOpHandler(req, res, next) {
  assert.ok(req);
  assert.ok(res);
  assert.ok(next);

  res.errorMessage = req.requestName + ' not supported';
  res.end(errors.LDAP_PROTOCOL_ERROR);
  return next();
}


function fireDTraceProbe(req, res) {
  assert.ok(req);

  req._dtraceId = res._dtraceId = dtrace._nextId();
  var probeArgs = [
    req._dtraceId,
    req.connection.remoteAddress || 'localhost',
    req.connection.ldap.bindDN.toString(),
    req.dn.toString()
  ];

  var op;
  switch (req.protocolOp) {
  case Protocol.LDAP_REQ_ABANDON:
    op = 'abandon';
    break;
  case Protocol.LDAP_REQ_ADD:
    op = 'add';
    probeArgs.push(req.attributes.length);
    break;
  case Protocol.LDAP_REQ_BIND:
    op = 'bind';
    break;
  case Protocol.LDAP_REQ_COMPARE:
    op = 'compare';
    probeArgs.push(req.attribute);
    probeArgs.push(req.value);
    break;
  case Protocol.LDAP_REQ_DELETE:
    op = 'delete';
    break;
  case Protocol.LDAP_REQ_EXTENSION:
    op = 'exop';
    probeArgs.push(req.name);
    probeArgs.push(req.value);
    break;
  case Protocol.LDAP_REQ_MODIFY:
    op = 'modify';
    probeArgs.push(req.changes.length);
    break;
  case Protocol.LDAP_REQ_MODRDN:
    op = 'modifydn';
    probeArgs.push(req.newRdn.toString());
    probeArgs.push((req.newSuperior ? req.newSuperior.toString() : ''));
    break;
  case Protocol.LDAP_REQ_SEARCH:
    op = 'search';
    probeArgs.push(req.scope);
    probeArgs.push(req.filter.toString());
    break;
  case Protocol.LDAP_REQ_UNBIND:
    op = 'unbind';
    break;
  }

  res._dtraceOp = op;
  dtrace.fire('server-' + op + '-start', function() {
    return probeArgs;
  });
}



///--- API

/**
 * Constructs a new server that you can call .listen() on, in the various
 * forms node supports.  You need to first assign some handlers to the various
 * LDAP operations however.
 *
 * The options object currently only takes a certificate/private key, and a
 * log4js handle.
 *
 * This object exposes the following events:
 *  - 'error'
 *  - 'close'
 *
 * @param {Object} options (optional) parameterization object.
 * @throws {TypeError} on bad input.
 */
function Server(options) {
  if (options) {
    if (typeof(options) !== 'object')
      throw new TypeError('options (object) required');
    if (options.log4js && typeof(options.log4js) !== 'object')
      throw new TypeError('options.log4s must be an object');

    if (options.certificate || options.key) {
      if (!(options.certificate && options.key) ||
          typeof(options.certificate) !== 'string' ||
          typeof(options.key) !== 'string') {
        throw new TypeError('options.certificate and options.key (string) ' +
                            'are both required for TLS');
      }
    }
  } else {
    options = {};
  }
  var self = this;
  if (!options.log4js)
    options.log4js = logStub;

  EventEmitter.call(this, options);

  this._chain = [];
  this.log4js = options.log4js;
  this.log = this.log4js.getLogger('Server');

  var log = this.log;

  function setupConnection(c) {
    assert.ok(c);

    if (c.type === 'unix') {
      c.remoteAddress = self.server.path;
      c.remotePort = c.fd;
    } else if (c.socket) { // TLS
      c.remoteAddress = c.socket.remoteAddress;
      c.remotePort = c.socket.remotePort;
    }


    var rdn = new dn.RDN({cn: 'anonymous'});

    c.ldap = {
      id: c.remoteAddress + ':' + c.remotePort,
      config: options,
      _bindDN: new DN([rdn])
    };
    c.addListener('timeout', function() {
      log.trace('%s timed out', c.ldap.id);
      c.destroy();
    });
    c.addListener('end', function() {
      log.trace('%s shutdown', c.ldap.id);
    });
    c.addListener('error', function(err) {
      log.warn('%s unexpected connection error', c.ldap.id, err);
      c.destroy();
    });
    c.addListener('close', function(had_err) {
      log.trace('%s close; had_err=%j', c.ldap.id, had_err);
      c.end();
    });

    c.ldap.__defineGetter__('bindDN', function() {
      return c.ldap._bindDN;
    });
    c.ldap.__defineSetter__('bindDN', function(val) {
      if (!(val instanceof DN))
        throw new TypeError('DN required');

      c.ldap._bindDN = val;
      return val;
    });
    return c;
  }

  function newConnection(c) {
    setupConnection(c);
    if (log.isTraceEnabled())
      log.trace('new connection from %s', c.ldap.id);

    dtrace.fire('server-connection', function() {
      return [c.remoteAddress];
    });

    c.parser = new Parser({
      log4js: options.log4js
    });
    c.parser.on('message', function(req) {
      req.connection = c;
      req.logId = c.ldap.id + '::' + req.messageID;
      req.startTime = new Date().getTime();

      if (log.isDebugEnabled())
        log.debug('%s: message received: req=%j', c.ldap.id, req.json);

      var res = getResponse(req);
      if (!res) {
        log.warn('Unimplemented server method: %s', req.type);
        c.destroy();
        return false;
      }

      res.connection = c;
      res.logId = req.logId;
      res.requestDN = req.dn;

      var chain = self._getHandlerChain(req, res);

      var i = 0;
      return function(err) {
        function sendError(err) {
          res.status = err.code || errors.LDAP_OPERATIONS_ERROR;
          res.matchedDN = req.suffix ? req.suffix.toString() : '';
          res.errorMessage = err.message || '';
          return res.end();
        }

        function after() {
          if (!self._postChain || !self._postChain.length)
            return;

          function next() {} // stub out next for the post chain

          self._postChain.forEach(function(c) {
            c.call(self, req, res, next);
          });
        }

        if (err) {
          log.trace('%s sending error: %s', req.logId, err.stack || err);
          sendError(err);
          return after();
        }

        try {
          var next = arguments.callee;
          if (chain.handlers[i])
            return chain.handlers[i++].call(chain.backend, req, res, next);

          if (req.protocolOp === Protocol.LDAP_REQ_BIND && res.status === 0)
            c.ldap.bindDN = req.dn;

          return after();
        } catch (e) {
          if (!e.stack)
            e.stack = e.toString();
          log.error('%s uncaught exception: %s', req.logId, e.stack);
          return sendError(new errors.OperationsError(e.message));
        }

      }();
    });

    c.parser.on('error', function(err, message) {
      log.error('Exception happened parsing for %s: %s',
                c.ldap.id, err.stack);


      if (!message)
        return c.destroy();

      var res = getResponse(message);
      if (!res)
        return c.destroy();

      res.status = 0x02; // protocol error
      res.errorMessage = err.toString();
      return c.end(res.toBer());
    });

    c.on('data', function(data) {
      if (log.isTraceEnabled())
        log.trace('data on %s: %s', c.ldap.id, util.inspect(data));

      try {
        c.parser.write(data);
      } catch (e) {
        log.warn('Unable to parse message [c.on(\'data\')]: %s', e.stack);
        c.end(new LDAPResult({
          status: 0x02,
          errorMessage: e.toString(),
          connection: c
        }).toBer());
      }
    });

  }; // end newConnection

  this.routes = {};
  if ((options.cert || options.certificate) && options.key) {
    options.cert = options.cert || options.certificate;
    this.server = tls.createServer(options, newConnection);
  } else {
    this.server = net.createServer(newConnection);
  }
  this.server.log4js = options.log4js;
  this.server.ldap = {
    config: options
  };
  this.server.on('close', function() {
    self.emit('close');
  });
  this.server.on('error', function(err) {
    self.emit('error', err);
  });

  this.__defineGetter__('maxConnections', function() {
    return self.server.maxConnections;
  });
  this.__defineSetter__('maxConnections', function(val) {
    self.server.maxConnections = val;
  });
  this.__defineGetter__('connections', function() {
    return self.server.connections;
  });
  this.__defineGetter__('name', function() {
    return 'LDAPServer';
  });
  this.__defineGetter__('url', function() {
    var str;
    if (this.server instanceof tls.Server) {
      str = 'ldaps://';
    } else {
      str = 'ldap://';
    }
    str += self.host || 'localhost';
    str += ':';
    str += self.port || 389;
    return str;
  });
}
util.inherits(Server, EventEmitter);
module.exports = Server;


/**
 * Adds a handler (chain) for the LDAP add method.
 *
 * Note that this is of the form f(name, [function]) where the second...N
 * arguments can all either be functions or arrays of functions.
 *
 * @param {String} name the DN to mount this handler chain at.
 * @return {Server} this so you can chain calls.
 * @throws {TypeError} on bad input
 */
Server.prototype.add = function(name) {
  var args = Array.prototype.slice.call(arguments, 1);
  return this._mount(Protocol.LDAP_REQ_ADD, name, args);
};


/**
 * Adds a handler (chain) for the LDAP bind method.
 *
 * Note that this is of the form f(name, [function]) where the second...N
 * arguments can all either be functions or arrays of functions.
 *
 * @param {String} name the DN to mount this handler chain at.
 * @return {Server} this so you can chain calls.
 * @throws {TypeError} on bad input
 */
Server.prototype.bind = function(name) {
  var args = Array.prototype.slice.call(arguments, 1);
  return this._mount(Protocol.LDAP_REQ_BIND, name, args);
};


/**
 * Adds a handler (chain) for the LDAP compare method.
 *
 * Note that this is of the form f(name, [function]) where the second...N
 * arguments can all either be functions or arrays of functions.
 *
 * @param {String} name the DN to mount this handler chain at.
 * @return {Server} this so you can chain calls.
 * @throws {TypeError} on bad input
 */
Server.prototype.compare = function(name) {
  var args = Array.prototype.slice.call(arguments, 1);
  return this._mount(Protocol.LDAP_REQ_COMPARE, name, args);
};


/**
 * Adds a handler (chain) for the LDAP delete method.
 *
 * Note that this is of the form f(name, [function]) where the second...N
 * arguments can all either be functions or arrays of functions.
 *
 * @param {String} name the DN to mount this handler chain at.
 * @return {Server} this so you can chain calls.
 * @throws {TypeError} on bad input
 */
Server.prototype.del = function(name) {
  var args = Array.prototype.slice.call(arguments, 1);
  return this._mount(Protocol.LDAP_REQ_DELETE, name, args);
};


/**
 * Adds a handler (chain) for the LDAP exop method.
 *
 * Note that this is of the form f(name, [function]) where the second...N
 * arguments can all either be functions or arrays of functions.
 *
 * @param {String} name OID to assign this handler chain to.
 * @return {Server} this so you can chain calls.
 * @throws {TypeError} on bad input.
 */
Server.prototype.exop = function(name) {
  var args = Array.prototype.slice.call(arguments, 1);
  return this._mount(Protocol.LDAP_REQ_EXTENSION, name, args, true);
};


/**
 * Adds a handler (chain) for the LDAP modify method.
 *
 * Note that this is of the form f(name, [function]) where the second...N
 * arguments can all either be functions or arrays of functions.
 *
 * @param {String} name the DN to mount this handler chain at.
 * @return {Server} this so you can chain calls.
 * @throws {TypeError} on bad input
 */
Server.prototype.modify = function(name) {
  var args = Array.prototype.slice.call(arguments, 1);
  return this._mount(Protocol.LDAP_REQ_MODIFY, name, args);
};


/**
 * Adds a handler (chain) for the LDAP modifyDN method.
 *
 * Note that this is of the form f(name, [function]) where the second...N
 * arguments can all either be functions or arrays of functions.
 *
 * @param {String} name the DN to mount this handler chain at.
 * @return {Server} this so you can chain calls.
 * @throws {TypeError} on bad input
 */
Server.prototype.modifyDN = function(name) {
  var args = Array.prototype.slice.call(arguments, 1);
  return this._mount(Protocol.LDAP_REQ_MODRDN, name, args);
};


/**
 * Adds a handler (chain) for the LDAP search method.
 *
 * Note that this is of the form f(name, [function]) where the second...N
 * arguments can all either be functions or arrays of functions.
 *
 * @param {String} name the DN to mount this handler chain at.
 * @return {Server} this so you can chain calls.
 * @throws {TypeError} on bad input
 */
Server.prototype.search = function(name) {
  var args = Array.prototype.slice.call(arguments, 1);
  return this._mount(Protocol.LDAP_REQ_SEARCH, name, args);
};


/**
 * Adds a handler (chain) for the LDAP unbind method.
 *
 * This method is different than the others and takes no mount point, as unbind
 * is a connection-wide operation, not constrianed to part of the DIT.
 *
 * @return {Server} this so you can chain calls.
 * @throws {TypeError} on bad input
 */
Server.prototype.unbind = function() {
  var args = Array.prototype.slice.call(arguments, 0);
  return this._mount(Protocol.LDAP_REQ_UNBIND, 'unbind', args, true);
};


Server.prototype.use = function use() {
  var args = Array.prototype.slice.call(arguments);
  var chain = mergeFunctionArgs(args, 0, args.length);
  var self = this;
  chain.forEach(function(c) {
    self._chain.push(c);
  });
};


Server.prototype.after = function() {
  if (!this._postChain)
    this._postChain = [];

  var self = this;
  mergeFunctionArgs(arguments).forEach(function(h) {
    self._postChain.push(h);
  });
};


// All these just reexpose the requisite net.Server APIs
Server.prototype.listen = function(port, host, callback) {
  if (!port)
    throw new TypeError('port (number) required');

  if (typeof(host) === 'function') {
    callback = host;
    host = '0.0.0.0';
  }
  var self = this;

  function _callback() {
    if (typeof(port) === 'number') {
      self.host = host;
      self.port = port;
    } else {
      self.host = port;
      self.port = self.server.fd;
    }

    if (typeof(callback) === 'function')
      callback();
  }

  if (typeof(port) === 'number') {
    return this.server.listen(port, host, _callback);
  } else {
    return this.server.listen(port, _callback);
  }
};
Server.prototype.listenFD = function(fd) {
  this.host = 'unix-domain-socket';
  this.port = fd;
  return this.server.listenFD(fd);
};
Server.prototype.close = function() {
  return this.server.close();
};
Server.prototype.address = function() {
  return this.server.address();
};


Server.prototype._getRoute = function(_dn, backend) {
  assert.ok(dn);

  if (!backend)
    backend = this;

  var name;
  if (_dn instanceof dn.DN) {
    name = _dn.toString();
  } else {
    name = _dn;
  }

  if (!this.routes[name]) {
    this.routes[name] = {};
    this.routes[name].backend = backend;
    this.routes[name].dn = _dn;
  }

  return this.routes[name];
};


Server.prototype._getHandlerChain = function(req, res) {
  assert.ok(req);

  fireDTraceProbe(req, res);

  // check anonymous bind
  if (req.protocolOp === Protocol.LDAP_REQ_BIND &&
      req.dn.toString() === '' &&
      req.credentials === '') {
    return {
      backend: self,
      handlers: [defaultNoOpHandler]
    };
  }

  var op = '0x' + req.protocolOp.toString(16);

  var self = this;
  var routes = this.routes;
  var keys = Object.keys(routes);
  for (var i = 0; i < keys.length; i++) {
    var r = keys[i];
    var route = routes[r];

    // Special cases are abandons, exops and unbinds, handle those first.
    if (req.protocolOp === Protocol.LDAP_REQ_EXTENSION) {
      if (r !== req.requestName)
        continue;

      return {
        backend: routes.backend,
        handlers: route[op] || [noExOpHandler]
      };
    } else if (req.protocolOp === Protocol.LDAP_REQ_UNBIND) {
      function getUnbindChain() {
        if (routes['unbind'] && routes['unbind'][op])
          return routes['unbind'][op];

        self.log.debug('%s unbind request %j', req.logId, req.json);
        return [defaultNoOpHandler];
      }

      return {
        backend: routes['unbind'] ? routes['unbind'].backend : self,
        handlers: getUnbindChain()
      };
    } else if (req.protocolOp === Protocol.LDAP_REQ_ABANDON) {
      return {
        backend: self,
        handlers: [defaultNoOpHandler]
      };
    }

    if (!route[op])
      continue;

    // Otherwise, match via DN rules
    assert.ok(req.dn);
    assert.ok(route.dn);

    if (!route.dn.equals(req.dn) && !route.dn.parentOf(req.dn))
      continue;

    // We should be good to go.
    req.suffix = route.dn;
    return {
      backend: route.backend,
      handlers: route[op] || [defaultHandler]
    };
  }

  // We're here, so nothing matched.
  return {
    backend: self,
    handlers: [(req.protocolOp !== Protocol.LDAP_REQ_EXTENSION ?
                noSuffixHandler : noExOpHandler)]
  };
};


Server.prototype._mount = function(op, name, argv, notDN) {
  assert.ok(op);
  assert.ok(name !== undefined);
  assert.ok(argv);

  if (typeof(name) !== 'string')
    throw new TypeError('name (string) required');
  if (!argv.length)
    throw new Error('at least one handler required');

  var backend = this;
  var index = 0;

  if (typeof(argv[0]) === 'object' && !Array.isArray(argv[0])) {
    backend = argv[0];
    index = 1;
  }
  var route = this._getRoute(notDN ? name : dn.parse(name), backend);

  var chain = this._chain.slice();
  argv.slice(index).forEach(function(a) {
    chain.push(a);
  });
  route['0x' + op.toString(16)] = mergeFunctionArgs(chain);

  return this;
};
