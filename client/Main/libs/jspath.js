(function() {
  var JsPath,
    __slice = Array.prototype.slice;

  this.JsPath = (function() {
    var primTypes,
      _this = this;

    primTypes = /^(string|number|boolean)$/;

    /*
      @constructor.
      @signature: new JsPath(path, val)
      @param: path - a dot-notation style "path" to identify a
        nested JS object.
      @description: Initialize a new js object with the provided
        path.  I've never actually used this constructor for any-
        thing, and it is here for the sake of "comprehensiveness"
        at this time, although I am incredulous as to it's overall
        usefulness.
    */

    function JsPath(path, val) {
      return JsPath.setAt({}, path, val || {});
    }

    ['forEach', 'indexOf', 'join', 'pop', 'reverse', 'shift', 'sort', 'splice', 'unshift', 'push'].forEach(function(method) {
      return JsPath[method + 'At'] = function() {
        var obj, path, rest, target;
        obj = arguments[0], path = arguments[1], rest = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
        target = JsPath.getAt(obj, path);
        if ('function' === typeof (target != null ? target[method] : void 0)) {
          return target[method].apply(target, rest);
        } else {
          throw new Error("Does not implement method " + method + " at " + path);
        }
      };
    });

    /*
      @method. property of the constructor.
      @signature: JsPath.getAt(ref, path)
      @param: ref - the object to traverse.
      @param: path - a dot-notation style "path" to identify a
        nested JS object.
      @return: the object that can be found inside ref at the path
        described by the second parameter or undefined if the path
        is not valid.
    */

    JsPath.getAt = function(ref, path) {
      var prop;
      if ('function' === typeof path.split) {
        path = path.split('.');
      } else {
        path = path.slice();
      }
      while ((ref != null) && (prop = path.shift())) {
        ref = ref[prop];
      }
      return ref;
    };

    /*
      @method. property of the constructor.
      @signature: JsPath.getAt(ref, path)
      @param: obj - the object to extend.
      @param: path - a dot-notation style "path" to identify a
        nested JS object.
      @param: val - the value to assign to the path of the obj.
      @return: the object that was extended.
      @description: set a property to the path provided by the
        second parameter with the value provided by the third
        parameter.
    */

    JsPath.setAt = function(obj, path, val) {
      var component, last, prev, ref;
      if ('function' === typeof path.split) {
        path = path.split('.');
      } else {
        path = path.slice();
      }
      last = path.pop();
      prev = [];
      ref = obj;
      while (component = path.shift()) {
        if (primTypes.test(typeof ref[component])) {
          throw new Error("" + (prev.concat(component).join('.')) + " is\nprimitive, and cannot be extended.");
        }
        ref = ref[component] || (ref[component] = {});
        prev.push(component);
      }
      ref[last] = val;
      return obj;
    };

    JsPath.assureAt = function(ref, path, initializer) {
      var obj;
      if (obj = this.getAt(ref, path)) {
        return obj;
      } else {
        this.setAt(ref, path, initializer);
        return initializer;
      }
    };

    /*
      @method. property of the constructor.
      @signature: JsPath.deleteAt(ref, path)
      @param: obj - the object to extend.
      @param: path - a dot-notation style "path" to identify a
        nested JS object to dereference.
      @return: boolean success.
      @description: deletes the reference specified by the last
        unit of the path from the object specified by other
        components of the path, belonging to the provided object.
    */

    JsPath.deleteAt = function(ref, path) {
      var component, last, prev;
      if ('function' === typeof path.split) {
        path = path.split('.');
      } else {
        path = path.slice();
      }
      prev = [];
      last = path.pop();
      while (component = path.shift()) {
        if (primTypes.test(typeof ref[component])) {
          throw new Error("" + (prev.concat(component).join('.')) + " is\nprimitive; cannot drill any deeper.");
        }
        if (!(ref = ref[component])) return false;
        prev.push(component);
      }
      return delete ref[last];
    };

    return JsPath;

  }).call(this);

  /*
  Footnotes:
    1 - if there's no .split() method, assume it's already an array
  */

}).call(this);
