whoami = require 'app/util/whoami'
remote = require 'app/remote'

module.exports = (password, callback) ->

  whoami().fetchEmail (err, email) ->
    options = { password, email }
    remote.api.JUser.verifyPassword options, (err, confirmed) ->

      return callback err.message  if err
      return callback 'Current password cannot be confirmed'  unless confirmed

      callback()
