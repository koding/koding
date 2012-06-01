sys = require('sys')
crypto = require('crypto')

class Digest
  @hexdigest: (privateKey, string) ->
    new Digest().hmacSha1(privateKey, string)

  hmacSha1: (key, data) ->
    hmac = crypto.createHmac('sha1', @sha1(key))
    hmac.update(data)
    hmac.digest('hex')

  sha1: (data) ->
    hash = crypto.createHash('sha1')
    hash.update(data)
    hash.digest()

exports.Digest = Digest
