remote = require 'app/remote'

module.exports = (password, callback) ->

  remote.api.JUser.verifyPassword { password }, (err, confirmed) ->

    return callback err.message  if err
    return callback 'Current password cannot be confirmed'  unless confirmed

    callback()
