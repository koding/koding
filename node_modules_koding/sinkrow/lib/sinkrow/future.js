var initializeFuture,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = function(context) {
  var Future;

  if ('function' === typeof context) {
    if (context.name) {
      return Future = (function(_super) {
        __extends(Future, _super);

        Future.queue || (Future.queue = []);

        function Future() {
          this.queue = [];
          Future.__super__.constructor.apply(this, arguments);
        }

        initializeFuture.call(Future);

        return Future;

      })(context);
    } else {
      context.isFuture = true;
      return context;
    }
  }
};

initializeFuture = (function() {
  var Pipeline, andThen, filter, isFuture, method, methods, next, originalMethods, replaceMethods, slice, _ref;

  _ref = require('underscore'), filter = _ref.filter, methods = _ref.methods;
  slice = [].slice;
  Pipeline = require('./pipeline');
  originalMethods = {};
  method = function(context, methodName) {
    originalMethods[methodName] = context[methodName];
    return function() {
      this.queue.push({
        context: context,
        methodName: methodName,
        args: slice.call(arguments)
      });
      return this;
    };
  };
  next = function(pipeline, err) {
    var args, context, e, methodName, queued;

    if (err != null) {
      return pipeline.callback.call(this, err);
    } else {
      queued = pipeline.queue.shift();
      if (queued != null) {
        methodName = queued.methodName, context = queued.context, args = queued.args;
        args.unshift(pipeline);
        args.push(next.bind(this, pipeline));
        try {
          return originalMethods[methodName].apply(originalMethods, args);
        } catch (_error) {
          e = _error;
          return pipeline.callback.call(this, e, pipeline);
        }
      } else {
        return pipeline.callback.call(this, null, pipeline);
      }
    }
  };
  andThen = function(callback) {
    var pipeline;

    pipeline = new Pipeline([], this.queue, callback);
    if (pipeline.queue.length) {
      next.call(this, pipeline);
    }
    this.queue = [];
    return this;
  };
  isFuture = function(methodName) {
    return this[methodName].isFuture;
  };
  replaceMethods = function() {
    var methodName, _i, _len, _ref1;

    _ref1 = filter(methods(this), isFuture.bind(this));
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      methodName = _ref1[_i];
      this[methodName] = method(this, methodName);
    }
    return this.then = andThen;
  };
  return function() {
    replaceMethods.call(this);
    return replaceMethods.call(this.prototype);
  };
})();
