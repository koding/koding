kd           = require 'kd'
doXhrRequest = require './doXhrRequest'

kd.utils.repeat 20000, ->
  doXhrRequest { endPoint : '/api/presence/ping' }, (err) ->
    console.log err  if err
