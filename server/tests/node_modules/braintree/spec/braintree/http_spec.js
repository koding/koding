require('../spec_helper');

var braintree = specHelper.braintree,
    Config = require('../../lib/braintree/config').Config,
    Http = require('../../lib/braintree/http').Http;

vows.describe('Http').addBatch({
  'request': {
    'when the http response status is 500': {
      topic: function () {
        var http = new Http(new Config(specHelper.defaultConfig));
        http.post('/test/error', '', this.callback);
      },
      'returns a ServerError': function (err, response) {
        assert.equal(err.type, braintree.errorTypes.serverError);
      }
    },

    'when the http response status is 503': {
      topic: function () {
        var http = new Http(new Config(specHelper.defaultConfig));
        http.post('/test/maintenance', '', this.callback);
      },
      'returns a down for maintenance error': function (err, response) {
        assert.equal(err.type, braintree.errorTypes.downForMaintenanceError);
      }
    },

    'can hit the sandbox': {
      topic: function () {
        var http = new Http(new Config({
          environment: braintree.Environment.Sandbox,
          merchantId: 'node',
          publicKey: 'node',
          privateKey: 'node'
        }));
        http.get('/not_found', this.callback);
      },
      'gets a not found errors': function (err, response) {
        assert.equal(err.type, braintree.errorTypes.notFoundError);
      }
    }
  },

  'can hit production': {
    topic: function () {
      var http = new Http(new Config({
        environment: braintree.Environment.Production,
        merchantId: 'node',
        publicKey: 'node',
        privateKey: 'node'
      }));
      http.get('/not_found', this.callback);
    },
    'gets a not found errors': function (err, response) {
      assert.equal(err.type, braintree.errorTypes.notFoundError);
    }
  }

}).export(module);
