require=(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({"T9Wsc/":[function(require,module,exports){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

function EventEmitter() {
  this._events = this._events || {};
  this._maxListeners = this._maxListeners || undefined;
}
module.exports = EventEmitter;

// Backwards-compat with node 0.10.x
EventEmitter.EventEmitter = EventEmitter;

EventEmitter.prototype._events = undefined;
EventEmitter.prototype._maxListeners = undefined;

// By default EventEmitters will print a warning if more than 10 listeners are
// added to it. This is a useful default which helps finding memory leaks.
EventEmitter.defaultMaxListeners = 10;

// Obviously not all Emitters should be limited to 10. This function allows
// that to be increased. Set to zero for unlimited.
EventEmitter.prototype.setMaxListeners = function(n) {
  if (!isNumber(n) || n < 0 || isNaN(n))
    throw TypeError('n must be a positive number');
  this._maxListeners = n;
  return this;
};

EventEmitter.prototype.emit = function(type) {
  var er, handler, len, args, i, listeners;

  if (!this._events)
    this._events = {};

  // If there is no 'error' event listener then throw.
  if (type === 'error') {
    if (!this._events.error ||
        (isObject(this._events.error) && !this._events.error.length)) {
      er = arguments[1];
      if (er instanceof Error) {
        throw er; // Unhandled 'error' event
      } else {
        throw TypeError('Uncaught, unspecified "error" event.');
      }
      return false;
    }
  }

  handler = this._events[type];

  if (isUndefined(handler))
    return false;

  if (isFunction(handler)) {
    switch (arguments.length) {
      // fast cases
      case 1:
        handler.call(this);
        break;
      case 2:
        handler.call(this, arguments[1]);
        break;
      case 3:
        handler.call(this, arguments[1], arguments[2]);
        break;
      // slower
      default:
        len = arguments.length;
        args = new Array(len - 1);
        for (i = 1; i < len; i++)
          args[i - 1] = arguments[i];
        handler.apply(this, args);
    }
  } else if (isObject(handler)) {
    len = arguments.length;
    args = new Array(len - 1);
    for (i = 1; i < len; i++)
      args[i - 1] = arguments[i];

    listeners = handler.slice();
    len = listeners.length;
    for (i = 0; i < len; i++)
      listeners[i].apply(this, args);
  }

  return true;
};

EventEmitter.prototype.addListener = function(type, listener) {
  var m;

  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events)
    this._events = {};

  // To avoid recursion in the case that type === "newListener"! Before
  // adding it to the listeners, first emit "newListener".
  if (this._events.newListener)
    this.emit('newListener', type,
              isFunction(listener.listener) ?
              listener.listener : listener);

  if (!this._events[type])
    // Optimize the case of one listener. Don't need the extra array object.
    this._events[type] = listener;
  else if (isObject(this._events[type]))
    // If we've already got an array, just append.
    this._events[type].push(listener);
  else
    // Adding the second element, need to change to array.
    this._events[type] = [this._events[type], listener];

  // Check for listener leak
  if (isObject(this._events[type]) && !this._events[type].warned) {
    var m;
    if (!isUndefined(this._maxListeners)) {
      m = this._maxListeners;
    } else {
      m = EventEmitter.defaultMaxListeners;
    }

    if (m && m > 0 && this._events[type].length > m) {
      this._events[type].warned = true;
      console.error('(node) warning: possible EventEmitter memory ' +
                    'leak detected. %d listeners added. ' +
                    'Use emitter.setMaxListeners() to increase limit.',
                    this._events[type].length);
      console.trace();
    }
  }

  return this;
};

EventEmitter.prototype.on = EventEmitter.prototype.addListener;

EventEmitter.prototype.once = function(type, listener) {
  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  var fired = false;

  function g() {
    this.removeListener(type, g);

    if (!fired) {
      fired = true;
      listener.apply(this, arguments);
    }
  }

  g.listener = listener;
  this.on(type, g);

  return this;
};

// emits a 'removeListener' event iff the listener was removed
EventEmitter.prototype.removeListener = function(type, listener) {
  var list, position, length, i;

  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events || !this._events[type])
    return this;

  list = this._events[type];
  length = list.length;
  position = -1;

  if (list === listener ||
      (isFunction(list.listener) && list.listener === listener)) {
    delete this._events[type];
    if (this._events.removeListener)
      this.emit('removeListener', type, listener);

  } else if (isObject(list)) {
    for (i = length; i-- > 0;) {
      if (list[i] === listener ||
          (list[i].listener && list[i].listener === listener)) {
        position = i;
        break;
      }
    }

    if (position < 0)
      return this;

    if (list.length === 1) {
      list.length = 0;
      delete this._events[type];
    } else {
      list.splice(position, 1);
    }

    if (this._events.removeListener)
      this.emit('removeListener', type, listener);
  }

  return this;
};

EventEmitter.prototype.removeAllListeners = function(type) {
  var key, listeners;

  if (!this._events)
    return this;

  // not listening for removeListener, no need to emit
  if (!this._events.removeListener) {
    if (arguments.length === 0)
      this._events = {};
    else if (this._events[type])
      delete this._events[type];
    return this;
  }

  // emit removeListener for all listeners on all events
  if (arguments.length === 0) {
    for (key in this._events) {
      if (key === 'removeListener') continue;
      this.removeAllListeners(key);
    }
    this.removeAllListeners('removeListener');
    this._events = {};
    return this;
  }

  listeners = this._events[type];

  if (isFunction(listeners)) {
    this.removeListener(type, listeners);
  } else {
    // LIFO order
    while (listeners.length)
      this.removeListener(type, listeners[listeners.length - 1]);
  }
  delete this._events[type];

  return this;
};

EventEmitter.prototype.listeners = function(type) {
  var ret;
  if (!this._events || !this._events[type])
    ret = [];
  else if (isFunction(this._events[type]))
    ret = [this._events[type]];
  else
    ret = this._events[type].slice();
  return ret;
};

EventEmitter.listenerCount = function(emitter, type) {
  var ret;
  if (!emitter._events || !emitter._events[type])
    ret = 0;
  else if (isFunction(emitter._events[type]))
    ret = 1;
  else
    ret = emitter._events[type].length;
  return ret;
};

function isFunction(arg) {
  return typeof arg === 'function';
}

function isNumber(arg) {
  return typeof arg === 'number';
}

function isObject(arg) {
  return typeof arg === 'object' && arg !== null;
}

function isUndefined(arg) {
  return arg === void 0;
}

},{}],"events":[function(require,module,exports){
module.exports=require('T9Wsc/');
},{}],3:[function(require,module,exports){
// shim for using process in browser

var process = module.exports = {};

process.nextTick = (function () {
    var canSetImmediate = typeof window !== 'undefined'
    && window.setImmediate;
    var canPost = typeof window !== 'undefined'
    && window.postMessage && window.addEventListener
    ;

    if (canSetImmediate) {
        return function (f) { return window.setImmediate(f) };
    }

    if (canPost) {
        var queue = [];
        window.addEventListener('message', function (ev) {
            var source = ev.source;
            if ((source === window || source === null) && ev.data === 'process-tick') {
                ev.stopPropagation();
                if (queue.length > 0) {
                    var fn = queue.shift();
                    fn();
                }
            }
        }, true);

        return function nextTick(fn) {
            queue.push(fn);
            window.postMessage('process-tick', '*');
        };
    }

    return function nextTick(fn) {
        setTimeout(fn, 0);
    };
})();

process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];

process.binding = function (name) {
    throw new Error('process.binding is not supported');
}

// TODO(shtylman)
process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};

},{}],4:[function(require,module,exports){
var EventEmitter = require('events').EventEmitter;
var scrubber = require('./lib/scrub');
var objectKeys = require('./lib/keys');
var forEach = require('./lib/foreach');
var isEnumerable = require('./lib/is_enum');

module.exports = function (cons, opts) {
    return new Proto(cons, opts);
};

(function () { // browsers bleh
    for (var key in EventEmitter.prototype) {
        Proto.prototype[key] = EventEmitter.prototype[key];
    }
})();

function Proto (cons, opts) {
    var self = this;
    EventEmitter.call(self);
    if (!opts) opts = {};
    
    self.remote = {};
    self.callbacks = { local : [], remote : [] };
    self.wrap = opts.wrap;
    self.unwrap = opts.unwrap;
    
    self.scrubber = scrubber(self.callbacks.local);
    
    if (typeof cons === 'function') {
        self.instance = new cons(self.remote, self);
    }
    else self.instance = cons || {};
}

Proto.prototype.start = function () {
    this.request('methods', [ this.instance ]);
};

Proto.prototype.cull = function (id) {
    delete this.callbacks.remote[id];
    this.emit('request', {
        method : 'cull',
        arguments : [ id ]
    });
};

Proto.prototype.request = function (method, args) {
    var scrub = this.scrubber.scrub(args);
    
    this.emit('request', {
        method : method,
        arguments : scrub.arguments,
        callbacks : scrub.callbacks,
        links : scrub.links
    });
};

Proto.prototype.handle = function (req) {
    var self = this;
    var args = self.scrubber.unscrub(req, function (id) {
        if (self.callbacks.remote[id] === undefined) {
            // create a new function only if one hasn't already been created
            // for a particular id
            var cb = function () {
                self.request(id, [].slice.apply(arguments));
            };
            self.callbacks.remote[id] = self.wrap ? self.wrap(cb, id) : cb;
            return cb;
        }
        return self.unwrap
            ? self.unwrap(self.callbacks.remote[id], id)
            : self.callbacks.remote[id]
        ;
    });
    
    if (req.method === 'methods') {
        self.handleMethods(args[0]);
    }
    else if (req.method === 'cull') {
        forEach(args, function (id) {
            delete self.callbacks.local[id];
        });
    }
    else if (typeof req.method === 'string') {
        if (isEnumerable(self.instance, req.method)) {
            self.apply(self.instance[req.method], args);
        }
        else {
            self.emit('fail', new Error(
                'request for non-enumerable method: ' + req.method
            ));
        }
    }
    else if (typeof req.method == 'number') {
        var fn = self.callbacks.local[req.method];
        if (!fn) {
            self.emit('fail', new Error('no such method'));
        }
        else self.apply(fn, args);
    }
};

Proto.prototype.handleMethods = function (methods) {
    var self = this;
    if (typeof methods != 'object') {
        methods = {};
    }
    
    // copy since assignment discards the previous refs
    forEach(objectKeys(self.remote), function (key) {
        delete self.remote[key];
    });
    
    forEach(objectKeys(methods), function (key) {
        self.remote[key] = methods[key];
    });
    
    self.emit('remote', self.remote);
    self.emit('ready');
};

Proto.prototype.apply = function (f, args) {
    try { f.apply(undefined, args) }
    catch (err) { this.emit('error', err) }
};

},{"./lib/foreach":5,"./lib/is_enum":6,"./lib/keys":7,"./lib/scrub":8,"events":"T9Wsc/"}],5:[function(require,module,exports){
module.exports = function forEach (xs, f) {
    if (xs.forEach) return xs.forEach(f)
    for (var i = 0; i < xs.length; i++) {
        f.call(xs, xs[i], i);
    }
}

},{}],6:[function(require,module,exports){
var objectKeys = require('./keys');

module.exports = function (obj, key) {
    if (Object.prototype.propertyIsEnumerable) {
        return Object.prototype.propertyIsEnumerable.call(obj, key);
    }
    var keys = objectKeys(obj);
    for (var i = 0; i < keys.length; i++) {
        if (key === keys[i]) return true;
    }
    return false;
};

},{"./keys":7}],7:[function(require,module,exports){
module.exports = Object.keys || function (obj) {
    var keys = [];
    for (var key in obj) keys.push(key);
    return keys;
};

},{}],8:[function(require,module,exports){
var traverse = require('traverse');
var objectKeys = require('./keys');
var forEach = require('./foreach');

function indexOf (xs, x) {
    if (xs.indexOf) return xs.indexOf(x);
    for (var i = 0; i < xs.length; i++) if (xs[i] === x) return i;
    return -1;
}

// scrub callbacks out of requests in order to call them again later
module.exports = function (callbacks) {
    return new Scrubber(callbacks);
};

function Scrubber (callbacks) {
    this.callbacks = callbacks;
}

// Take the functions out and note them for future use
Scrubber.prototype.scrub = function (obj) {
    var self = this;
    var paths = {};
    var links = [];
    
    var args = traverse(obj).map(function (node) {
        if (typeof node === 'function') {
            var i = indexOf(self.callbacks, node);
            if (i >= 0 && !(i in paths)) {
                // Keep previous function IDs only for the first function
                // found. This is somewhat suboptimal but the alternatives
                // are worse.
                paths[i] = this.path;
            }
            else {
                var id = self.callbacks.length;
                self.callbacks.push(node);
                paths[id] = this.path;
            }
            
            this.update('[Function]');
        }
        else if (this.circular) {
            links.push({ from : this.circular.path, to : this.path });
            this.update('[Circular]');
        }
    });
    
    return {
        arguments : args,
        callbacks : paths,
        links : links
    };
};
 
// Replace callbacks. The supplied function should take a callback id and
// return a callback of its own.
Scrubber.prototype.unscrub = function (msg, f) {
    var args = msg.arguments || [];
    forEach(objectKeys(msg.callbacks || {}), function (sid) {
        var id = parseInt(sid, 10);
        var path = msg.callbacks[id];
        traverse.set(args, path, f(id));
    });
    
    forEach(msg.links || [], function (link) {
        var value = traverse.get(args, link.from);
        traverse.set(args, link.to, value);
    });
    
    return args;
};

},{"./foreach":5,"./keys":7,"traverse":9}],9:[function(require,module,exports){
var traverse = module.exports = function (obj) {
    return new Traverse(obj);
};

function Traverse (obj) {
    this.value = obj;
}

Traverse.prototype.get = function (ps) {
    var node = this.value;
    for (var i = 0; i < ps.length; i ++) {
        var key = ps[i];
        if (!node || !hasOwnProperty.call(node, key)) {
            node = undefined;
            break;
        }
        node = node[key];
    }
    return node;
};

Traverse.prototype.has = function (ps) {
    var node = this.value;
    for (var i = 0; i < ps.length; i ++) {
        var key = ps[i];
        if (!node || !hasOwnProperty.call(node, key)) {
            return false;
        }
        node = node[key];
    }
    return true;
};

Traverse.prototype.set = function (ps, value) {
    var node = this.value;
    for (var i = 0; i < ps.length - 1; i ++) {
        var key = ps[i];
        if (!hasOwnProperty.call(node, key)) node[key] = {};
        node = node[key];
    }
    node[ps[i]] = value;
    return value;
};

Traverse.prototype.map = function (cb) {
    return walk(this.value, cb, true);
};

Traverse.prototype.forEach = function (cb) {
    this.value = walk(this.value, cb, false);
    return this.value;
};

Traverse.prototype.reduce = function (cb, init) {
    var skip = arguments.length === 1;
    var acc = skip ? this.value : init;
    this.forEach(function (x) {
        if (!this.isRoot || !skip) {
            acc = cb.call(this, acc, x);
        }
    });
    return acc;
};

Traverse.prototype.paths = function () {
    var acc = [];
    this.forEach(function (x) {
        acc.push(this.path); 
    });
    return acc;
};

Traverse.prototype.nodes = function () {
    var acc = [];
    this.forEach(function (x) {
        acc.push(this.node);
    });
    return acc;
};

Traverse.prototype.clone = function () {
    var parents = [], nodes = [];
    
    return (function clone (src) {
        for (var i = 0; i < parents.length; i++) {
            if (parents[i] === src) {
                return nodes[i];
            }
        }
        
        if (typeof src === 'object' && src !== null) {
            var dst = copy(src);
            
            parents.push(src);
            nodes.push(dst);
            
            forEach(objectKeys(src), function (key) {
                dst[key] = clone(src[key]);
            });
            
            parents.pop();
            nodes.pop();
            return dst;
        }
        else {
            return src;
        }
    })(this.value);
};

function walk (root, cb, immutable) {
    var path = [];
    var parents = [];
    var alive = true;
    
    return (function walker (node_) {
        var node = immutable ? copy(node_) : node_;
        var modifiers = {};
        
        var keepGoing = true;
        
        var state = {
            node : node,
            node_ : node_,
            path : [].concat(path),
            parent : parents[parents.length - 1],
            parents : parents,
            key : path.slice(-1)[0],
            isRoot : path.length === 0,
            level : path.length,
            circular : null,
            update : function (x, stopHere) {
                if (!state.isRoot) {
                    state.parent.node[state.key] = x;
                }
                state.node = x;
                if (stopHere) keepGoing = false;
            },
            'delete' : function (stopHere) {
                delete state.parent.node[state.key];
                if (stopHere) keepGoing = false;
            },
            remove : function (stopHere) {
                if (isArray(state.parent.node)) {
                    state.parent.node.splice(state.key, 1);
                }
                else {
                    delete state.parent.node[state.key];
                }
                if (stopHere) keepGoing = false;
            },
            keys : null,
            before : function (f) { modifiers.before = f },
            after : function (f) { modifiers.after = f },
            pre : function (f) { modifiers.pre = f },
            post : function (f) { modifiers.post = f },
            stop : function () { alive = false },
            block : function () { keepGoing = false }
        };
        
        if (!alive) return state;
        
        function updateState() {
            if (typeof state.node === 'object' && state.node !== null) {
                if (!state.keys || state.node_ !== state.node) {
                    state.keys = objectKeys(state.node)
                }
                
                state.isLeaf = state.keys.length == 0;
                
                for (var i = 0; i < parents.length; i++) {
                    if (parents[i].node_ === node_) {
                        state.circular = parents[i];
                        break;
                    }
                }
            }
            else {
                state.isLeaf = true;
                state.keys = null;
            }
            
            state.notLeaf = !state.isLeaf;
            state.notRoot = !state.isRoot;
        }
        
        updateState();
        
        // use return values to update if defined
        var ret = cb.call(state, state.node);
        if (ret !== undefined && state.update) state.update(ret);
        
        if (modifiers.before) modifiers.before.call(state, state.node);
        
        if (!keepGoing) return state;
        
        if (typeof state.node == 'object'
        && state.node !== null && !state.circular) {
            parents.push(state);
            
            updateState();
            
            forEach(state.keys, function (key, i) {
                path.push(key);
                
                if (modifiers.pre) modifiers.pre.call(state, state.node[key], key);
                
                var child = walker(state.node[key]);
                if (immutable && hasOwnProperty.call(state.node, key)) {
                    state.node[key] = child.node;
                }
                
                child.isLast = i == state.keys.length - 1;
                child.isFirst = i == 0;
                
                if (modifiers.post) modifiers.post.call(state, child);
                
                path.pop();
            });
            parents.pop();
        }
        
        if (modifiers.after) modifiers.after.call(state, state.node);
        
        return state;
    })(root).node;
}

function copy (src) {
    if (typeof src === 'object' && src !== null) {
        var dst;
        
        if (isArray(src)) {
            dst = [];
        }
        else if (isDate(src)) {
            dst = new Date(src.getTime ? src.getTime() : src);
        }
        else if (isRegExp(src)) {
            dst = new RegExp(src);
        }
        else if (isError(src)) {
            dst = { message: src.message };
        }
        else if (isBoolean(src)) {
            dst = new Boolean(src);
        }
        else if (isNumber(src)) {
            dst = new Number(src);
        }
        else if (isString(src)) {
            dst = new String(src);
        }
        else if (Object.create && Object.getPrototypeOf) {
            dst = Object.create(Object.getPrototypeOf(src));
        }
        else if (src.constructor === Object) {
            dst = {};
        }
        else {
            var proto =
                (src.constructor && src.constructor.prototype)
                || src.__proto__
                || {}
            ;
            var T = function () {};
            T.prototype = proto;
            dst = new T;
        }
        
        forEach(objectKeys(src), function (key) {
            dst[key] = src[key];
        });
        return dst;
    }
    else return src;
}

var objectKeys = Object.keys || function keys (obj) {
    var res = [];
    for (var key in obj) res.push(key)
    return res;
};

function toS (obj) { return Object.prototype.toString.call(obj) }
function isDate (obj) { return toS(obj) === '[object Date]' }
function isRegExp (obj) { return toS(obj) === '[object RegExp]' }
function isError (obj) { return toS(obj) === '[object Error]' }
function isBoolean (obj) { return toS(obj) === '[object Boolean]' }
function isNumber (obj) { return toS(obj) === '[object Number]' }
function isString (obj) { return toS(obj) === '[object String]' }

var isArray = Array.isArray || function isArray (xs) {
    return Object.prototype.toString.call(xs) === '[object Array]';
};

var forEach = function (xs, fn) {
    if (xs.forEach) return xs.forEach(fn)
    else for (var i = 0; i < xs.length; i++) {
        fn(xs[i], i, xs);
    }
};

forEach(objectKeys(Traverse.prototype), function (key) {
    traverse[key] = function (obj) {
        var args = [].slice.call(arguments, 1);
        var t = new Traverse(obj);
        return t[key].apply(t, args);
    };
});

var hasOwnProperty = Object.hasOwnProperty || function (obj, key) {
    return key in obj;
};

},{}],"kite":[function(require,module,exports){
module.exports=require('JL8Kc6');
},{}],"JL8Kc6":[function(require,module,exports){
"use strict";
var BasicKite, Kite,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BasicKite = require('../kite/kite.coffee');

module.exports = Kite = (function(_super) {
  var Promise;

  __extends(Kite, _super);

  Promise = (window.Promise);

  function Kite(options) {
    if (!(this instanceof Kite)) {
      return new Kite(options);
    }
    Kite.__super__.constructor.call(this, options);
  }

  Kite.prototype.tell = function(method, params, callback) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return Kite.__super__.tell.call(_this, method, params, function(err, result) {
          if (err) {
            return reject(err);
          }
          return resolve(result);
        });
      };
    })(this)).nodeify(callback);
  };

  Kite.prototype.ready = function() {
    return new Promise((function(_this) {
      return function(resolve) {
        return Kite.__super__.ready.call(_this, resolve);
      };
    })(this));
  };

  return Kite;

})(BasicKite);


},{"../kite/kite.coffee":"03yxz7"}],12:[function(require,module,exports){
"use strict";
module.exports = function(options) {
  var backoff, initalDelayMs, maxDelayMs, maxReconnectAttempts, multiplyFactor, totalReconnectAttempts, _ref, _ref1, _ref2, _ref3, _ref4;
  if (options == null) {
    options = {};
  }
  backoff = (_ref = options.backoff) != null ? _ref : {};
  totalReconnectAttempts = 0;
  initalDelayMs = (_ref1 = backoff.initialDelayMs) != null ? _ref1 : 700;
  multiplyFactor = (_ref2 = backoff.multiplyFactor) != null ? _ref2 : 1.4;
  maxDelayMs = (_ref3 = backoff.maxDelayMs) != null ? _ref3 : 1000 * 15;
  maxReconnectAttempts = (_ref4 = backoff.maxReconnectAttempts) != null ? _ref4 : 50;
  this.clearBackoffTimeout = function() {
    return totalReconnectAttempts = 0;
  };
  return this.setBackoffTimeout = (function(_this) {
    return function(fn) {
      var timeout;
      if (totalReconnectAttempts < maxReconnectAttempts) {
        timeout = Math.min(initalDelayMs * Math.pow(multiplyFactor, totalReconnectAttempts), maxDelayMs);
        setTimeout(fn, timeout);
        return totalReconnectAttempts++;
      } else {
        return _this.emit("backoffFailed");
      }
    };
  })(this);
};


},{}],13:[function(require,module,exports){
"use strict";
module.exports = function(method, ctx) {
  var boundMethod;
  if (ctx == null) {
    ctx = this;
  }
  if (ctx[method] == null) {
    throw new Error("Could not bind method: " + method);
  }
  boundMethod = "__bound__" + method;
  boundMethod in ctx || Object.defineProperty(ctx, boundMethod, {
    value: ctx[method].bind(ctx)
  });
  return ctx[boundMethod];
};


},{}],"03yxz7":[function(require,module,exports){
(function (process){
"use strict";
var EventEmitter, Kite,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

EventEmitter = require('events').EventEmitter;

module.exports = Kite = (function(_super) {
  var CLOSED, ERROR, NOTREADY, OKAY, READY, WebSocket, dnodeProtocol, makeProperError, uniqueId, wrapApi, _ref, _ref1;

  __extends(Kite, _super);

  dnodeProtocol = require('dnode-protocol');

  WebSocket = (window.WebSocket);

  wrapApi = require('./wrap-api.coffee');

  _ref = [0, 1, 3], NOTREADY = _ref[0], READY = _ref[1], CLOSED = _ref[2];

  _ref1 = [0, 1], OKAY = _ref1[0], ERROR = _ref1[1];

  uniqueId = (window.uuid).v4;

  function Kite(options) {
    var _base, _base1;
    if (!(this instanceof Kite)) {
      return new Kite(options);
    }
    this.id = uniqueId();
    this.options = 'string' === typeof options ? {
      url: options
    } : options;
    if ((_base = this.options).autoConnect == null) {
      _base.autoConnect = true;
    }
    if ((_base1 = this.options).autoReconnect == null) {
      _base1.autoReconnect = true;
    }
    this.readyState = NOTREADY;
    if (this.options.autoReconnect) {
      this.initBackoff();
    }
    this.proto = dnodeProtocol(wrapApi(this.options.api), {
      wrap: this.bound('wrapMessage'),
      unwrap: this.bound('unwrapMessage')
    });
    this.proto.on('request', (function(_this) {
      return function(req) {
        _this.ready(function() {
          return _this.ws.send(JSON.stringify(req));
        });
        _this.emit('info', "proto request", req);
      };
    })(this));
    if (this.options.autoConnect) {
      this.connect();
    }
  }

  Kite.prototype.connect = function() {
    var url;
    if (this.readyState === READY) {
      return;
    }
    url = this.options.url;
    this.ws = new WebSocket(url);
    this.ws.addEventListener('open', this.bound('onOpen'));
    this.ws.addEventListener('close', this.bound('onClose'));
    this.ws.addEventListener('message', this.bound('onMessage'));
    this.ws.addEventListener('error', this.bound('onError'));
    this.emit('info', "Trying to connect to " + url);
  };

  Kite.prototype.disconnect = function(reconnect) {
    if (reconnect == null) {
      reconnect = false;
    }
    this.autoReconnect = !!reconnect;
    this.ws.close();
    this.emit('info', "Disconnecting from " + this.options.url);
  };

  Kite.prototype.onOpen = function() {
    this.readyState = READY;
    this.emit('connected');
    this.emit('ready');
    this.emit('info', "Connected to Kite: " + this.options.url);
    this.clearBackoffTimeout();
  };

  Kite.prototype.onClose = function() {
    this.readyState = CLOSED;
    this.emit('disconnected');
    if (this.autoReconnect) {
      process.nextTick((function(_this) {
        return function() {
          return _this.setBackoffTimeout(_this.bound("connect"));
        };
      })(this));
    }
    if (this.errState === ERROR) {
      this.emit('error', "Websocket error!");
      this.errState = OKAY;
    }
    this.emit('info', "" + this.options.url + ": disconnected, trying to reconnect...");
  };

  Kite.prototype.onMessage = function(_arg) {
    var data, req;
    data = _arg.data;
    this.emit('info', "onMessage", data);
    req = (function() {
      try {
        return JSON.parse(data);
      } catch (_error) {}
    })();
    if (req != null) {
      this.proto.handle(req);
    }
  };

  Kite.prototype.onError = function(err) {
    this.errState = ERROR;
    this.emit('info', "" + this.options.url + " error: " + err.data);
  };

  Kite.prototype.unwrapMessage = function(message) {
    var err, result, _ref2;
    _ref2 = message.withArgs[0], err = _ref2.error, result = _ref2.result;
    if (err != null) {
      err = makeProperError(err);
    }
    return {
      err: err,
      result: result
    };
  };

  Kite.prototype.wrapMessage = function(method, params, callback) {
    var _ref2, _ref3, _ref4, _ref5, _ref6;
    return {
      authentication: this.options.auth,
      withArgs: params,
      responseCallback: (function(_this) {
        return function(response) {
          var err, result, _ref2;
          _ref2 = _this.unwrapMessage(response), err = _ref2.err, result = _ref2.result;
          return callback(err, result);
        };
      })(this),
      kite: {
        username: "" + ((_ref2 = this.options.username) != null ? _ref2 : 'anonymous'),
        environment: "" + ((_ref3 = this.options.environment) != null ? _ref3 : 'browser'),
        name: "browser",
        version: "" + ((_ref4 = this.options.version) != null ? _ref4 : '1.0.0'),
        region: "" + ((_ref5 = this.options.region) != null ? _ref5 : 'browser'),
        hostname: "" + ((_ref6 = this.options.hostname) != null ? _ref6 : 'browser'),
        id: this.id
      }
    };
  };

  Kite.prototype.tell = function(method, params, callback) {
    var scrubbed;
    if (callback.times == null) {
      callback.times = 1;
    }
    scrubbed = this.proto.scrubber.scrub([this.wrapMessage(method, params, callback)]);
    scrubbed.method = method;
    this.proto.emit('request', scrubbed);
  };

  makeProperError = function(_arg) {
    var err, message, type;
    type = _arg.type, message = _arg.message;
    err = new Error(message);
    err.type = type;
    return err;
  };

  Kite.prototype.bound = require('./bound.coffee');

  Kite.prototype.initBackoff = require('./backoff.coffee');

  Kite.prototype.ready = function(callback) {
    if (this.readyState === READY) {
      process.nextTick(callback);
    } else {
      this.once('ready', callback);
    }
  };

  Kite.disconnect = function() {
    var kite, kites, _i, _len;
    kites = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    for (_i = 0, _len = kites.length; _i < _len; _i++) {
      kite = kites[_i];
      kite.disconnect();
    }
  };

  Kite.random = function(kites) {
    return kites[Math.floor(Math.random() * kites.length)];
  };

  return Kite;

})(EventEmitter);


}).call(this,require("/Users/thorn/Desktop/kite.js/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"))
},{"./backoff.coffee":12,"./bound.coffee":13,"./wrap-api.coffee":16,"/Users/thorn/Desktop/kite.js/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":3,"dnode-protocol":4,"events":"T9Wsc/"}],"./src/kite/kite.coffee":[function(require,module,exports){
module.exports=require('03yxz7');
},{}],16:[function(require,module,exports){
"use strict";
var __hasProp = {}.hasOwnProperty;

module.exports = function(userlandApi) {
  var api, fn, method;
  if (userlandApi == null) {
    userlandApi = {};
  }
  api = ['error', 'info', 'log', 'warn'].reduce(function(api, method) {
    api[method] = console[method].bind(console);
    return api;
  }, {});
  for (method in userlandApi) {
    if (!__hasProp.call(userlandApi, method)) continue;
    fn = userlandApi[method];
    api[method] = fn;
  }
  return api;
};


},{}]},{},["JL8Kc6"])