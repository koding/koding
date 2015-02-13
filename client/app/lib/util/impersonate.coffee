remote = require('../remote').getInstance()
showErrorNotification = require './showErrorNotification'

module.exports = (username) ->
  remote.api.JAccount.impersonate username, (err) =>
    if err
      options = userMessage: "You are not allowed to impersonate"
      showErrorNotification err, options
    else global.location.reload()

