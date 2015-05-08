kd = require 'kd'
remote = require('app/remote').getInstance()

module.exports = fetchPrivateMessageCount = (options, callback) ->

  remote.api.SocialMessage.fetchPrivateMessageCount options, (err, result) ->
    return callback err  if err

    # increase it by 1 for Koding Bot. ~Umut
    result.totalCount += 1
    callback null, result
