function template(ck_options) {
var __slice = Array.prototype.slice;
var __hasProp = Object.prototype.hasOwnProperty;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
var __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype;
  return child;
};
var __indexOf = Array.prototype.indexOf || function(item) {
  for (var i = 0, l = this.length; i < l; i++) {
    if (this[i] === item) return i;
  }
  return -1;
};
    var ck_buffer, ck_doctypes, ck_esc, ck_indent, ck_render_attrs, ck_repeat, ck_self_closing, ck_tabs, ck_tag, coffeescript, comment, doctype, h, tag, text, _ref, _ref2, _ref3, _ref4;
    ck_options != null ? ck_options : ck_options = {};
    (_ref = ck_options.context) != null ? _ref : ck_options.context = {};
    (_ref2 = ck_options.locals) != null ? _ref2 : ck_options.locals = {};
    (_ref3 = ck_options.format) != null ? _ref3 : ck_options.format = false;
    (_ref4 = ck_options.autoescape) != null ? _ref4 : ck_options.autoescape = false;
    ck_buffer = [];
    ck_render_attrs = function(obj) {
      var k, str, v;
      str = '';
      for (k in obj) {
        v = obj[k];
        str += " " + k + "=\"" + (ck_esc(v)) + "\"";
      }
      return str;
    };
    ck_doctypes = {
      '5': '<!DOCTYPE html>',
      'xml': '<?xml version="1.0" encoding="utf-8" ?>',
      'default': '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">',
      'transitional': '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">',
      'strict': '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
      'frameset': '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">',
      '1.1': '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">',
      'basic': '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">',
      'mobile': '<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">'
    };
    ck_self_closing = ['area', 'base', 'basefont', 'br', 'hr', 'img', 'input', 'link', 'meta'];
    ck_esc = function(txt) {
      if (ck_options.autoescape) {
        return h(txt);
      } else {
        return String(txt);
      }
    };
    ck_tabs = 0;
    ck_repeat = function(string, count) {
      return Array(count + 1).join(string);
    };
    ck_indent = function() {
      if (ck_options.format) {
        return text(ck_repeat('  ', ck_tabs));
      }
    };
    h = function(txt) {
      return String(txt).replace(/&(?!\w+;)/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    };
    doctype = function(type) {
      type != null ? type : type = 5;
      text(ck_doctypes[type]);
      if (ck_options.format) {
        return text('\n');
      }
    };
    text = function(txt) {
      ck_buffer.push(String(txt));
      return null;
    };
    comment = function(cmt) {
      text("<!--" + cmt + "-->");
      if (ck_options.format) {
        return text('\n');
      }
    };
    tag = function() {
      var name;
      name = arguments[0];
      delete arguments[0];
      return ck_tag(name, arguments);
    };
    ck_tag = function(name, opts) {
      var o, result, _i, _j, _len, _len2;
      ck_indent();
      text("<" + name);
      for (_i = 0, _len = opts.length; _i < _len; _i++) {
        o = opts[_i];
        if (typeof o === 'object') {
          text(ck_render_attrs(o));
        }
      }
      if (__indexOf.call(ck_self_closing, name) >= 0) {
        text(' />');
        if (ck_options.format) {
          text('\n');
        }
      } else {
        text('>');
        for (_j = 0, _len2 = opts.length; _j < _len2; _j++) {
          o = opts[_j];
          switch (typeof o) {
            case 'string':
            case 'number':
              text(ck_esc(o));
              break;
            case 'function':
              if (ck_options.format) {
                text('\n');
              }
              ck_tabs++;
              result = o.call(ck_options.context);
              if (typeof result === 'string') {
                ck_indent();
                text(ck_esc(result));
                if (ck_options.format) {
                  text('\n');
                }
              }
              ck_tabs--;
              ck_indent();
          }
        }
        text("</" + name + ">");
        if (ck_options.format) {
          text('\n');
        }
      }
      return null;
    };
    coffeescript = function(code) {
      return script(";(" + code + ")();");
    };
    var a,div,i,li,p,s,th,u,ul;a = function(){return ck_tag('a', arguments)};div = function(){return ck_tag('div', arguments)};i = function(){return ck_tag('i', arguments)};li = function(){return ck_tag('li', arguments)};p = function(){return ck_tag('p', arguments)};s = function(){return ck_tag('s', arguments)};th = function(){return ck_tag('th', arguments)};u = function(){return ck_tag('u', arguments)};ul = function(){return ck_tag('ul', arguments)};(function(){ul(function() {
  var guy, _i, _len, _ref, _results;
  _ref = this.stooges;
  _results = [];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    guy = _ref[_i];
    _results.push(li(guy));
  }
  return _results;
});
div(function() {
  var guy, _i, _len, _ref, _results;
  _ref = this.foo;
  _results = [];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    guy = _ref[_i];
    _results.push(div(guy));
  }
  return _results;
});}).call(ck_options.context);return ck_buffer.join('');
}