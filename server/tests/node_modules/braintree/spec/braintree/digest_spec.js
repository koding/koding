require('../spec_helper');
var Digest = require('../../lib/braintree/digest').Digest;

vows.describe('Util').addBatch({
  'hexdigest': {
    'test case 6 from RFC 2202': {
      topic: Digest.hexdigest(specHelper.multiplyString("\xaa", 80), "Test Using Larger Than Block-Size Key - Hash Key First"),
      'returns the expected digest': function (result) {
        assert.equal(result, 'aa4ae5e15272d00e95705637ce8a3b55ed402112');
      }
    },

    'test case 7 from RFC 2202': {
      topic: Digest.hexdigest(specHelper.multiplyString("\xaa", 80), "Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data"),
      'returns the expected digest': function (result) {
        assert.equal(result, 'e8e99d0f45237d786d6bbaa7965c7808bbff1a91');
      }
    }
  }
}).export(module);
