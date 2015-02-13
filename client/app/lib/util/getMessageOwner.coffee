remote = require('../remote').getInstance()

module.exports = (message, callback) ->
  {constructorName, _id} = message.account
  remote.cacheable constructorName, _id, (err, owner) ->
    return callback err  if err
    return callback { message: "Account not found", name: "NotFound" } unless owner
    callback null, owner
