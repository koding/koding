this.sequence = require('./sequence');

this.race = require('./race');

this.daisy = function(args) {
  process.nextTick(args.next = function() {
    var fn;
    if (fn = args.shift()) {
      return !!fn(args) || true;
    } else {
      return false;
    }
  });
  return args.next;
};

this.dash = function(args, cb) {
  var arg, count, length, _i, _len, _ref;
  if ('function' === typeof args) {
    _ref = [args, cb], cb = _ref[0], args = _ref[1];
  }
  length = args.length;
  if (length === 0) {
    process.nextTick(cb);
  } else {
    count = 0;
    args.fin = function() {
      if (++count === length) {
        return !!cb() || true;
      } else {
        return false;
      }
    };
    for (_i = 0, _len = args.length; _i < _len; _i++) {
      arg = args[_i];
      process.nextTick(arg);
    }
  }
  return args.fin;
};
