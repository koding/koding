var vows = require('vows'),
    assert = require('assert'),
    gzip = require('../lib/gzip'),
    Buffer = require('buffer').Buffer;

var promise;

vows.describe('node-gzip').addBatch({
  'When executed node-gzip' : {
    topic: function() {
      this.callback(null, gzip('some-string'));
    },
    'should return EventEmitter': function(result) {
      assert.instanceOf(result, process.EventEmitter);
      promise = result;
    }
  }
}).addBatch({
  'A "promise"': {
    'should receive "data" event': {
      topic: function() {
        var callback = this.callback;
        promise.on('data', function(data) {
          callback(null, data);
        });
      },
      'with Buffer argument': function(data) {
        assert.instanceOf(data, Buffer);
      }
    },
    'should receive "end" event': {
      topic: function() {
        var callback = this.callback;
        promise.on('end', function(data) {
          callback(null, data);
        });
      },
      'with no arguments!': function(data) {
        assert.ok(!data);
      }
    }
  }
}).export(module);

