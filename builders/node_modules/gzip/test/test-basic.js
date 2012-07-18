var vows = require('vows'),
    assert = require('assert'),
    gzip = require('../lib/gzip'),
    Buffer = require('buffer').Buffer;

vows.describe('node-gzip').addBatch({
  'String compressed by node-gzip' : {
    topic: function() {
      gzip('some-string', this.callback);
    },
    'should be not empty': function(compressed) {
      assert.ok(compressed);
    },
    'should be Buffer': function(compressed) {
      assert.ok(Buffer.isBuffer(compressed));
    },
    'should have non-zero length': function(compressed) {
      assert.ok(compressed.length > 0);
    }
  }
}).export(module);
