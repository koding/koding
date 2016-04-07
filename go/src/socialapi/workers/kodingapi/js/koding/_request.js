var http, url;
http = require('http');
url = require('url');
exports.doRequest = function(endpoint, options, callback) {
    var opts, ref, req;
    if (!callback) {
        ref = [null, options], options = ref[0], callback = ref[1];
    }
    endpoint = url.parse(endpoint);
    opts = {
        host: endpoint.hostname,
        port: endpoint.port || 80,
        path: endpoint.pathname,
        headers: options.headers || {},
        method: options.method || 'POST'
    };
    if (options.params) {
        options.params = JSON.stringify(options.params);
        opts.headers['Content-Type'] = 'application/json';
        opts.headers['Content-Length'] = options.params.length;
    }
    req = http.request(opts);
    if (options.params) {
        req.write(options.params);
    }
    req.on('response', function(res) {
        res.body = '';
        res.setEncoding('utf-8');
        res.on('data', function(chunk) {
            return res.body += chunk;
        });
        return res.on('end', function() {
            return callback(res.body, res);
        });
    });
    return req.end();
};
exports.processRequest = function(endpoint, options, callback) {
    return doRequest(endpoint, options, function(body, res) {
        var parsedBody;
        parsedBody = (function() {
            try {
                return JSON.parse(body);
            } catch (_error) {}
        })();
        if (res.statusCode < 200 || res.statusCode > 300) {
            return callback(parsedBody);
        } else {
            return callback(null, parsedBody, res);
        }
    });
};