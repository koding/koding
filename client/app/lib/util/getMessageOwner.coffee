fetchAccount = require './fetchAccount'

module.exports = (message, callback) ->
  fetchAccount message.account, (err, owner) ->
    return callback err  if err
    return callback { message: 'Account not found', name: 'NotFound' }  unless owner
    callback null, owner
