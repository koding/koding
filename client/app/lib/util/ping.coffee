kd           = require 'kd'
doXhrRequest = require './doXhrRequest'

pingOptions =
  endPoint  : '/api/social/presence/ping'
  timeout   : 2000
  type      : 'GET'

pingFailures = 0

ping = ->
  doXhrRequest pingOptions, (err) ->
    if err
      pingFailures++  if err.code is 400
      console.error '[presence]', err
    else
      pingFailures = 0

    if pingFailures >= 2
      kd.singletons.mainController.doLogout()

module.exports = ->

  do ping
  kd.utils.repeat 20000, ping
