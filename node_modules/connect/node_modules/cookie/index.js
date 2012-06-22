
/// Serialize the a name value pair into a cookie string suitable for
/// http headers. An optional options object specified cookie parameters
///
/// serialize('foo', 'bar', { httpOnly: true })
///   => "foo=bar; httpOnly"
///
/// @param {String} name
/// @param {String} val
/// @param {Object} options
/// @return {String}
var serialize = function(name, val, opt){
    var pairs = [name + '=' + encode(val)];
    opt = opt || {};

    if (opt.maxAge) pairs.push('Max-Age=' + opt.maxAge);
    if (opt.domain) pairs.push('Domain=' + opt.domain);
    if (opt.path) pairs.push('Path=' + opt.path);
    if (opt.expires) pairs.push('Expires=' + opt.expires.toUTCString());
    if (opt.httpOnly) pairs.push('HttpOnly');
    if (opt.secure) pairs.push('Secure');

    return pairs.join('; ');
};

/// Parse the given cookie header string into an object
/// The object has the various cookies as keys(names) => values
/// @param {String} str
/// @return {Object}
var parse = function(str) {
    var obj = {}
    var pairs = str.split(/[;,] */);

    pairs.forEach(function(pair) {
        var eq_idx = pair.indexOf('=')
        var key = pair.substr(0, eq_idx).trim()
        var val = pair.substr(++eq_idx, pair.length).trim();

        // quoted values
        if ('"' == val[0]) {
            val = val.slice(1, -1);
        }

        // only assign once
        if (undefined == obj[key]) {
            obj[key] = decode(val);
        }
    });

    return obj;
};

var encode = function(str) {
    return str.replace(/[ ",;/]/g, function(val) {
        switch(val) {
        case ' ': return '%20';
        case '"': return '%22';
        case ',': return '%2c';
        case '/': return '%2f';
        case ';': return '%3b';
        }
    });
};

var decode = function(str) {
    return str.replace(/(%2[02cfCF])|(%3[bB])/g, function(val) {
        switch(val) {
        case '%20': return ' ';
        case '%22': return '"';
        case '%2C':
        case '%2c': return ',';
        case '%2F':
        case '%2f': return '/';
        case '%3B':
        case '%3b': return ';';
        }
    });
};

module.exports.serialize = serialize;
module.exports.parse = parse;
