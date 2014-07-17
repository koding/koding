var argv = require('minimist')(process.argv);

var KONFIG = require('koding-config-manager').load("main."+argv.c);

var loadfire = require('loadfire');

loadfire.createServer({
  // Port to listeb on
  port: KONFIG.boxproxy.port,

  // Retries (when a server is down or not responding)
  retries: 5,
  retryTimeout: 100,

  // Ressources
  resources: [
    // Social
    {
      resource: 'social',
      backends: [
        {
          host: 'localhost',
          port: KONFIG.social.port
        }
      ],
      selector: loadfire.selectors.url('/xhr/*'),
      balancer: function(backends, req, cb) {
        return cb(null, backends[0]);
      }
    },

    // Broker
    {
      resource: 'broker',
      backends: [
        {
          host: 'localhost',
          port: KONFIG.broker.port
        }
      ],
      selector: loadfire.selectors.url('/subscribe/*'),
      balancer: function(backends, req, cb) {
        return cb(null, backends[0]);
      }
    },

    // Source maps
    {
      resource: 'sourcemaps',
      backends: [
        {
          host: 'localhost',
          port: KONFIG.sourcemaps.port
        }
      ],
      selector: loadfire.selectors.url('/sourcemaps/*'),
      balancer: function(backends, req, cb) {
        // Rewrite url
        req.url = req.url.substring(11);

        cb(null, backends[0]);
      }
    },

    // Web
    {
      resource: 'webserver',
      backends: [
        {
          host: 'localhost',
          port: KONFIG.webserver.port
        }
      ],
      selector: loadfire.selectors.url('/*'),
      balancer: function(backends, req, cb) {
        return cb(null, backends[0]);
      }
    },
  ]
}).listen();

