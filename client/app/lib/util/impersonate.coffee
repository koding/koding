kd = require 'kd'
showErrorNotification = require './showErrorNotification'
KiteCache = require '../kite/kitecache'

module.exports = (username) ->
  kd.singletons.socialapi.account.impersonate username, (err) ->
    if err
      options = { userMessage: 'You are not allowed to impersonate' }
      showErrorNotification err, options
    else

      # We need to clear cache just before impersonate
      # otherwise cache can cause some issue while working
      # on the impersonated account ~ GG
      KiteCache.clearAll()

      global.location.reload()
