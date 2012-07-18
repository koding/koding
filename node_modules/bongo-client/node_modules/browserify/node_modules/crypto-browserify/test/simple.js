var crypto = require('crypto')
var cryptoB = require('../')
var assert = require('assert')


function assertSame (fn) {
  fn(crypto, function (err, expected) {
    fn(cryptoB, function (err, actual) {
      assert.equal(actual, expected)
    })
  })
}

assertSame(function (crypto, cb) {
  cb(null, crypto.createHash('sha1').update('hello', 'utf-8').digest('hex'))
})

