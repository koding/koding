(function() {
  var ERROR_ID, EventEmitter, call_stack_location, create_callsite, current_trace_error, filename, format_location, format_method, in_prepare, limit_frames, prepareStackTrace, wrap_callback, __nextDomainTick, _addListener, _listeners, _nextTick, _on, _once, _removeListener, _setImmediate, _setInterval, _setTimeout;

  EventEmitter = require('events').EventEmitter;

  filename = __filename;

  current_trace_error = null;

  in_prepare = 0;

  exports.empty_frame = '---------------------------------------------';

  exports.async_trace_limit = 10;

  format_location = function(frame) {
    var column, file, line;
    if (frame.isNative()) {
      return 'native';
    }
    if (frame.isEval()) {
      return 'eval at ' + frame.getEvalOrigin();
    }
    file = frame.getFileName();
    line = frame.getLineNumber();
    column = frame.getColumnNumber();
    if (file == null) {
      return 'unknown source';
    }
    column = column != null ? ':' + column : '';
    line = line != null ? ':' + line : '';
    return file + line + column;
  };

  format_method = function(frame) {
    var function_name, method, type;
    function_name = frame.getFunctionName();
    if (!(frame.isToplevel() || frame.isConstructor())) {
      method = frame.getMethodName();
      type = frame.getTypeName();
      if (function_name == null) {
        return "" + type + "." + (method != null ? method : '<anonymous>');
      }
      if (method === function_name) {
        return "" + type + "." + function_name;
      }
      "" + type + "." + function_name + " [as " + method + "]";
    }
    if (frame.isConstructor()) {
      return "new " + (function_name != null ? function_name : '<anonymous>');
    }
    if (function_name != null) {
      return function_name;
    }
    return null;
  };

  exports.format_stack_frame = function(frame) {
    var location, method;
    if (frame.getFileName() === exports.empty_frame) {
      return exports.empty_frame;
    }
    method = format_method(frame);
    location = format_location(frame);
    if (method == null) {
      return "    at " + location;
    }
    return "    at " + method + " (" + location + ")";
  };

  exports.format_stack = function(err, frames) {
    var lines;
    lines = [];
    try {
      lines.push(err.toString());
    } catch (e) {
      console.log('Caught error in longjohn. Please report this to matt.insler@gmail.com.');
    }
    lines.push.apply(lines, frames.map(exports.format_stack_frame));
    return lines.join('\n');
  };

  create_callsite = function(location) {
    return Object.create({
      getFileName: function() {
        return location;
      },
      getLineNumber: function() {
        return null;
      },
      getFunctionName: function() {
        return null;
      },
      getTypeName: function() {
        return null;
      },
      getMethodName: function() {
        return null;
      },
      getColumnNumber: function() {
        return null;
      },
      isNative: function() {
        return null;
      }
    });
  };

  prepareStackTrace = function(error, structured_stack_trace) {
    var previous_stack, _ref;
    ++in_prepare;
    if (error.__cached_trace__ == null) {
      error.__cached_trace__ = structured_stack_trace.filter(function(f) {
        return f.getFileName() !== filename;
      });
      if (!(error.__previous__ != null) && in_prepare === 1) {
        error.__previous__ = current_trace_error;
      }
      if (error.__previous__ != null) {
        previous_stack = error.__previous__.stack;
        if ((previous_stack != null ? previous_stack.length : void 0) > 0) {
          error.__cached_trace__.push(create_callsite(exports.empty_frame));
          (_ref = error.__cached_trace__).push.apply(_ref, previous_stack);
        }
      }
    }
    --in_prepare;
    if (in_prepare > 0) {
      return error.__cached_trace__;
    }
    return exports.format_stack(error, error.__cached_trace__);
  };

  limit_frames = function(stack) {
    var count, previous;
    if (exports.async_trace_limit <= 0) {
      return;
    }
    count = exports.async_trace_limit - 1;
    previous = stack;
    while ((previous != null) && count > 1) {
      previous = previous.__previous__;
      --count;
    }
    if (previous != null) {
      return delete previous.__previous__;
    }
  };

  ERROR_ID = 1;

  call_stack_location = function() {
    var err, orig, stack;
    orig = Error.prepareStackTrace;
    Error.prepareStackTrace = function(x, stack) {
      return stack;
    };
    err = new Error();
    Error.captureStackTrace(err, arguments.callee);
    stack = err.stack;
    Error.prepareStackTrace = orig;
    return "" + (stack[2].getFunctionName()) + " (" + (stack[2].getFileName()) + ":" + (stack[2].getLineNumber()) + ")";
  };

  wrap_callback = function(callback, location) {
    var new_callback, trace_error;
    trace_error = new Error();
    trace_error.id = ERROR_ID++;
    trace_error.location = call_stack_location();
    trace_error.__location__ = location;
    trace_error.__previous__ = current_trace_error;
    trace_error.__trace_count__ = current_trace_error != null ? current_trace_error.__trace_count__ + 1 : 1;
    limit_frames(trace_error);
    new_callback = function() {
      current_trace_error = trace_error;
      trace_error = null;
      try {
        return callback.apply(this, arguments);
      } catch (e) {
        e.stack;
        throw e;
      } finally {
        current_trace_error = null;
      }
    };
    new_callback.__original_callback__ = callback;
    return new_callback;
  };

  _on = EventEmitter.prototype.on;

  _addListener = EventEmitter.prototype.addListener;

  _once = EventEmitter.prototype.once;

  _removeListener = EventEmitter.prototype.removeListener;

  _listeners = EventEmitter.prototype.listeners;

  EventEmitter.prototype.addListener = function(event, callback) {
    var args;
    args = Array.prototype.slice.call(arguments);
    args[1] = wrap_callback(callback, 'EventEmitter.addListener');
    return _addListener.apply(this, args);
  };

  EventEmitter.prototype.on = function(event, callback) {
    var args;
    args = Array.prototype.slice.call(arguments);
    args[1] = wrap_callback(callback, 'EventEmitter.on');
    return _on.apply(this, args);
  };

  EventEmitter.prototype.once = function(event, callback) {
    var args;
    args = Array.prototype.slice.call(arguments);
    args[1] = wrap_callback(callback, 'EventEmitter.once');
    return _once.apply(this, args);
  };

  EventEmitter.prototype.removeListener = function(event, callback) {
    var find_listener, listener,
      _this = this;
    find_listener = function(callback) {
      var is_callback, l, listeners, _i, _len, _ref, _ref1;
      is_callback = function(val) {
        var _ref, _ref1, _ref2;
        return val.__original_callback__ === callback || ((_ref = val.__original_callback__) != null ? (_ref1 = _ref.listener) != null ? _ref1.__original_callback__ : void 0 : void 0) === callback || ((_ref2 = val.listener) != null ? _ref2.__original_callback__ : void 0) === callback;
      };
      if (((_ref = _this._events) != null ? _ref[event] : void 0) == null) {
        return null;
      }
      if (is_callback(_this._events[event])) {
        return _this._events[event];
      }
      if (Array.isArray(_this._events[event])) {
        listeners = (_ref1 = _this._events[event]) != null ? _ref1 : [];
        for (_i = 0, _len = listeners.length; _i < _len; _i++) {
          l = listeners[_i];
          if (is_callback(l)) {
            return l;
          }
        }
      }
      return null;
    };
    listener = find_listener(callback);
    if (!((listener != null) && typeof listener === 'function')) {
      return this;
    }
    return _removeListener.call(this, event, listener);
  };

  EventEmitter.prototype.listeners = function(event) {
    var l, listeners, unwrapped, _i, _len;
    listeners = _listeners.call(this, event);
    unwrapped = [];
    for (_i = 0, _len = listeners.length; _i < _len; _i++) {
      l = listeners[_i];
      if (l.__original_callback__) {
        unwrapped.push(l.__original_callback__);
      } else {
        unwrapped.push(l);
      }
    }
    return unwrapped;
  };

  _nextTick = process.nextTick;

  process.nextTick = function(callback) {
    var args;
    args = Array.prototype.slice.call(arguments);
    args[0] = wrap_callback(callback, 'process.nextTick');
    return _nextTick.apply(this, args);
  };

  __nextDomainTick = process._nextDomainTick;

  process._nextDomainTick = function(callback) {
    var args;
    args = Array.prototype.slice.call(arguments);
    args[0] = wrap_callback(callback, 'process.nextDomainTick');
    return __nextDomainTick.apply(this, args);
  };

  _setTimeout = global.setTimeout;

  _setInterval = global.setInterval;

  global.setTimeout = function(callback) {
    var args;
    args = Array.prototype.slice.call(arguments);
    args[0] = wrap_callback(callback, 'global.setTimeout');
    return _setTimeout.apply(this, args);
  };

  global.setInterval = function(callback) {
    var args;
    args = Array.prototype.slice.call(arguments);
    args[0] = wrap_callback(callback, 'global.setInterval');
    return _setInterval.apply(this, args);
  };

  if (global.setImmediate != null) {
    _setImmediate = global.setImmediate;
    global.setImmediate = function(callback) {
      var args;
      args = Array.prototype.slice.call(arguments);
      args[0] = wrap_callback(callback, 'global.setImmediate');
      return _setImmediate.apply(this, args);
    };
  }

  Error.prepareStackTrace = prepareStackTrace;

}).call(this);
