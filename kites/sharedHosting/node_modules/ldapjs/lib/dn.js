// Copyright 2011 Mark Cavage, Inc.  All rights reserved.



function invalidDN(name) {
  var e = new Error();
  e.name = 'InvalidDistinguishedNameError';
  e.message = name;
  return e;
}


function isAlphaNumeric(c) {
  var re = /[A-Za-z0-9]/;
  return re.test(c);
}


function isWhitespace(c) {
  var re = /\s/;
  return re.test(c);
}

function RDN(obj) {
  var self = this;

  if (obj) {
    Object.keys(obj).forEach(function(k) {
      self[k.toLowerCase()] = obj[k];
    });
  }
}


RDN.prototype.toString = function() {
  var self = this;

  var str = '';
  Object.keys(this).forEach(function(k) {
    if (str.length)
      str += '+';

    str += k + '=' + self[k];
  });

  return str;
};

// Thank you OpenJDK!
function parse(name) {
  if (typeof(name) !== 'string')
    throw new TypeError('name (string) required');

  var cur = 0;
  var len = name.length;

  function parseRdn() {
    var rdn = new RDN();
    while (cur < len) {
      trim();
      var attr = parseAttrType();
      trim();
      if (cur >= len || name[cur++] !== '=')
        throw invalidDN(name);

      trim();
      var value = parseAttrValue();
      trim();
      rdn[attr.toLowerCase()] = value;
      if (cur >= len || name[cur] !== '+')
        break;
      ++cur;
    }

    return rdn;
  }


  function trim() {
    while ((cur < len) && isWhitespace(name[cur]))
      ++cur;
  }

  function parseAttrType() {
    var beg = cur;
    while (cur < len) {
      var c = name[cur];
      if (isAlphaNumeric(c) ||
          c == '.' ||
          c == '-' ||
          c == ' ') {
        ++cur;
      } else {
        break;
      }
    }
    // Back out any trailing spaces.
    while ((cur > beg) && (name[cur - 1] == ' '))
      --cur;

    if (beg == cur)
      throw invalidDN(name);

    return name.slice(beg, cur);
  }

  function parseAttrValue() {
    if (cur < len && name[cur] == '#') {
      return parseBinaryAttrValue();
    } else if (cur < len && name[cur] == '"') {
      return parseQuotedAttrValue();
    } else {
      return parseStringAttrValue();
    }
  }

  function parseBinaryAttrValue() {
    var beg = cur++;
    while (cur < len && isAlphaNumeric(name[cur]))
      ++cur;

    return name.slice(beg, cur);
  }

  function parseQuotedAttrValue() {
    var beg = cur++;

    while ((cur < len) && name[cur] != '"') {
      if (name[cur] === '\\')
        ++cur; // consume backslash, then what follows

      ++cur;
    }
    if (cur++ >= len) // no closing quote
      throw invalidDN(name);

    return name.slice(beg, cur);
  }

  function parseStringAttrValue() {
    var beg = cur;
    var esc = -1;

    while ((cur < len) && !atTerminator()) {
      if (name[cur] === '\\') {
        ++cur; // consume backslash, then what follows
        esc = cur;
      }
      ++cur;
    }
    if (cur > len) // backslash followed by nothing
      throw invalidDN(name);

    // Trim off (unescaped) trailing whitespace.
    var end;
    for (end = cur; end > beg; end--) {
      if (!isWhitespace(name[end - 1]) || (esc === (end - 1)))
        break;
    }
    return name.slice(beg, end);
  }

  function atTerminator() {
    return (cur < len &&
            (name[cur] === ',' ||
             name[cur] === ';' ||
             name[cur] === '+'));
  }

  var rdns = [];

  rdns.push(parseRdn());
  while (cur < len) {
    if (name[cur] === ',' || name[cur] === ';') {
      ++cur;
      rdns.push(parseRdn());
    } else {
      throw invalidDN(name);
    }
  }

  return new DN(rdns);
}



///--- API


function DN(rdns) {
  if (!Array.isArray(rdns))
    throw new TypeError('rdns ([object]) required');
  rdns.forEach(function(rdn) {
    if (typeof(rdn) !== 'object')
      throw new TypeError('rdns ([object]) required');
  });

  this.rdns = rdns.slice();

  this.__defineGetter__('length', function() {
    return this.rdns.length;
  });
}


DN.prototype.toString = function() {
  var _dn = [];
  this.rdns.forEach(function(rdn) {
    _dn.push(rdn.toString());
  });
  return _dn.join(', ');
};


DN.prototype.childOf = function(dn) {
  if (typeof(dn) !== 'object')
    dn = parse(dn);

  if (this.rdns.length <= dn.rdns.length)
    return false;

  var diff = this.rdns.length - dn.rdns.length;
  for (var i = dn.rdns.length - 1; i >= 0; i--) {
    var rdn = dn.rdns[i];

    var keys = Object.keys(rdn);
    if (!keys.length)
      return false;

    for (var j = 0; j < keys.length; j++) {
      var k = keys[j];
        var ourRdn = this.rdns[i + diff];
        if (ourRdn[k] !== rdn[k])
          return false;
    }
  }

  return true;
};


DN.prototype.parentOf = function(dn) {
  if (typeof(dn) !== 'object')
    dn = parse(dn);

  if (!this.rdns.length || this.rdns.length >= dn.rdns.length)
    return false;

  var diff = dn.rdns.length - this.rdns.length;
  for (var i = this.rdns.length - 1; i >= 0; i--) {
    var rdn = this.rdns[i];
    var keys = Object.keys(rdn);

    if (!keys.length)
      return false;

    for (var j = 0; j < keys.length; j++) {
      var k = keys[j];
      var theirRdn = dn.rdns[i + diff];
      if (theirRdn[k] !== rdn[k])
        return false;
    }
  }

  return true;
};


DN.prototype.equals = function(dn) {
  if (typeof(dn) !== 'object')
    dn = parse(dn);

  if (this.rdns.length !== dn.rdns.length)
    return false;

  for (var i = 0; i < this.rdns.length; i++) {
    var ours = this.rdns[i];
    var theirs = dn.rdns[i];
    var ourKeys = Object.keys(ours);
    var theirKeys = Object.keys(theirs);
    if (ourKeys.length !== theirKeys.length)
      return false;

    ourKeys.sort();
    theirKeys.sort();

    for (var j = 0; j < ourKeys.length; j++) {
      if (ourKeys[j] !== theirKeys[j])
        return false;
      if (ours[ourKeys[j]] !== theirs[ourKeys[j]])
        return false;
    }
  }

  return true;
};


DN.prototype.parent = function() {
  if (this.rdns.length > 1) {
    var save = this.rdns.shift();
    var dn = new DN(this.rdns);
    this.rdns.unshift(save);
    return dn;
  }

  return null;
};


DN.prototype.clone = function() {
  return new DN(this.rdns);
};


DN.prototype.reverse = function() {
  this.rdns.reverse();
  return this;
};


DN.prototype.pop = function() {
  return this.rdns.pop();
};


DN.prototype.push = function(rdn) {
  if (typeof(rdn) !== 'object')
    throw new TypeError('rdn (RDN) required');

  return this.rdns.push(rdn);
};


DN.prototype.shift = function() {
  return this.rdns.shift();
};


DN.prototype.unshift = function(rdn) {
  if (typeof(rdn) !== 'object')
    throw new TypeError('rdn (RDN) required');

  return this.rdns.unshift(rdn);
};



///--- Exports

module.exports = {

  parse: parse,

  DN: DN,

  RDN: RDN

};
